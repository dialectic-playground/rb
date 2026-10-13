# Low-Level Design (LLD) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Implementation language | Ruby 4.0 (rb) |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |
| Status | Approved |
| Inputs | `hld.md`, `specs/SRS.md`, `shared/CLI-CONVENTIONS.md` |

## 1. Source layout

```text
00-hello-world/
├── Gemfile, Gemfile.lock      # development gems: minitest, RuboCop (locked, with checksums)
├── .rubocop.yml               # RuboCop defaults + new cops, Ruby 4.0
└── src/
    ├── bin/dp-hello           # launcher: #!/usr/bin/env ruby; exit DpHello::CLI.main(ARGV)
    ├── lib/dp_hello.rb        # DpHello::PROGRAM and the requires
    ├── lib/dp_hello/
    │   ├── usage_error.rb     # DpHello::UsageError
    │   ├── arguments.rb       # DpHello::Arguments.normalize (UTF-8 arguments)
    │   ├── options.rb         # DpHello::Options.parse, Scanner, OptionValue, Parsed
    │   ├── validation.rb      # DpHello::Validation.validate, Config
    │   ├── greeting.rb        # DpHello::Greeting.text (pure)
    │   ├── output.rb          # DpHello::Output.write (binary mode, EPIPE)
    │   └── cli.rb             # DpHello::CLI.run (pure), CLI.main (I/O), help/version text
    └── test/                  # minitest: one *_test.rb per unit, test_helper.rb
```

## 2. Data types

### 2.1 `Options::OptionValue` (Data)
| Field | Type | Constraint / invariant | SRS |
| :-- | :-- | :-- | :-- |
| value | String | The value exactly as given (may be empty or start with `-`) | FR-02, CONV-15 |
| spelled | String | `-n`, `--name`, `-c`, or `--count`, as the user wrote the option | FR-03, FR-05, CONV-13 |

### 2.2 `Options::Parsed` (Data)
| Field | Type | Default | Constraint / invariant | SRS |
| :-- | :-- | :-- | :-- | :-- |
| action | Symbol | — | `:help`, `:version`, or `:greet` | FR-07, FR-08 |
| name | OptionValue or nil | nil | Last `-n`/`--name` occurrence (`:greet` only) | FR-06 |
| count | OptionValue or nil | nil | Last `-c`/`--count` occurrence (`:greet` only) | FR-06 |
| operands | Array of String | `[]` | All operands, in order, including those after `--` | FR-09 |

### 2.3 `Validation::Config` (Data)
| Field | Type | Default | Constraint / invariant | SRS |
| :-- | :-- | :-- | :-- | :-- |
| name | String | `World` | Non-empty | FR-01 … FR-03 |
| count | Integer | 1 | 1 ≤ count ≤ 1000 | FR-04, FR-05 |

### 2.4 Error type
`DpHello::UsageError < StandardError`; the message is the text after `dp-hello: `.
`CLI.run` writes `dp-hello: <message>\nTry 'dp-hello --help' for more information.\n` to
stderr and returns status 2.

| Raised by | Message | Exit status |
| :-- | :-- | :-- |
| `Scanner#scan_short` | `invalid option -- 'x'` | 2 |
| `Scanner#scan_long` | `unrecognized option '<token>'` | 2 |
| `Scanner#next_value` | `option requires an argument -- 'n'` / `'c'` | 2 |
| `Scanner#next_value` | `option '--name' requires an argument` / `'--count'` | 2 |
| `Scanner#scan_long` | `option '--help' doesn't allow an argument` / `'--version'` | 2 |
| `Validation.validate` | `extra operand '<first operand>'` | 2 |
| `Validation.validate_name` | `invalid argument '' for '<-n or --name>'` | 2 |
| `Validation.validate_count` | `invalid argument '<COUNT>' for '<-c or --count>'` | 2 |

## 3. Module and function specifications

### 3.1 `Arguments.normalize`
- **Signature:** `normalize(args) → Array<String>` (per element: `to_utf8(arg)`)
- **Responsibility:** return UTF-8-tagged copies of the arguments.
- **Postconditions:** each result is tagged UTF-8; the input strings are not mutated.
- **Algorithm:** if the tag is UTF-8, US-ASCII, or BINARY, re-tag the bytes as UTF-8 (POSIX:
  the bytes are UTF-8 regardless of the locale). Otherwise (a Windows code page) keep the
  bytes if they are valid UTF-8 or invalid in the tagged encoding; else transcode to UTF-8.
- **Errors:** none (a transcoding error falls back to re-tagging).
- **Satisfies:** CONV-05, CONV-06. **Unit tests:** `arguments_test.rb` (6 tests), `cli_test.rb::test_main_normalizes_locale_tagged_arguments`.

### 3.2 `Options.parse` / `Options::Scanner`
- **Signature:** `Options.parse(args) → Parsed`; raises `UsageError`.
- **Responsibility:** one left-to-right scan that reports syntax errors only.
- **Algorithm:** shift tokens until none remain. `--`: every remaining token is an operand.
  `--NAME[=V]` (`scan_long`): `help`/`version` return their action at once (or raise if `=`
  is present); `name`/`count` record the attached value or the next token (raise if there is
  none); anything else raises `unrecognized option` with the whole token. `-X…`
  (`scan_short`): `X` must be `n` or `c` (else `invalid option`); the value is the rest of
  the token or, if that is empty, the next token. Any other token (including `-`) is an
  operand. Later values overwrite earlier ones.
- **Complexity:** O(n) time and memory in the number of arguments.
- **Satisfies:** FR-02, FR-06, FR-07, FR-08, FR-10, CONV-07 … CONV-12, CONV-22.
- **Unit tests:** `options_test.rb` (18 tests, for example `test_bundled_short_option_consumes_rest_of_token`, `test_operand_and_value_errors_do_not_precede_help`, `test_syntax_error_before_help_wins`).

### 3.3 `Validation.validate` / `validate_name`
- **Signature:** `validate(parsed) → Config`; raises `UsageError`.
- **Algorithm:** (1) any operand → `extra operand` with the first one; (2) name: the default,
  or `validate_name` (non-empty, else `invalid argument ''`); (3) count: the default, or
  `validate_count`.
- **Satisfies:** FR-01, FR-03, FR-05, FR-06, FR-09. **Unit tests:** `validation_test.rb::test_defaults`, `test_name_is_kept_verbatim`, `test_empty_name_is_rejected_with_spelling`, `test_operands_are_rejected_first`, `test_name_is_checked_before_count`.

### 3.4 `Validation.validate_count`
- **Signature:** `validate_count(option) → Integer`; raises `UsageError`.
- **Algorithm:** the bytes must match `\A[0-9]+\z`; strip leading zeros; a significant part
  longer than 4 digits is out of range without being converted; the value must be 1–1000.
- **Satisfies:** FR-04, FR-05. **Unit tests:** `test_count_boundaries`, `test_leading_zeros`, `test_huge_counts`, `test_non_digits`.

### 3.5 `Greeting.text`
- **Signature:** `text(name, count) → String` — pure, no I/O.
- **Algorithm:** `"Hello, #{name}!\n" * count`.
- **Satisfies:** FR-01, FR-02, FR-04, NFR-05. **Unit tests:** `greeting_test.rb` (6 tests).

### 3.6 `Output.write`
- **Signature:** `write(stream, text) → true | false`.
- **Algorithm:** `stream.binmode`; `stream.write(text.b)`; `stream.flush`; `Errno::EPIPE`,
  `Errno::EINVAL` (a closed pipe on Windows), or `IOError` → `false`.
- **Satisfies:** CONV-03, CONV-25, NFR-01. **Unit tests:** `cli_test.rb::test_main_writes_binary_lf_output`, `test_main_stops_quietly_on_broken_pipe`.

### 3.7 `CLI.run` / `CLI.main`
- **Signatures:** `run(args) → [stdout_text, stderr_text, status]` (pure);
  `main(argv, stdout: $stdout, stderr: $stderr) → Integer`.
- **Algorithm (run):** parse; `:help` → `HELP_TEXT`, `:version` → `VERSION_TEXT`, `:greet` →
  validate, then `Greeting.text`; status 0. `UsageError` → `['', diagnostic, 2]`.
- **Algorithm (main):** normalize ARGV, run, write stdout (EPIPE → 141), write stderr if it
  is non-empty, return the status.
- **Satisfies:** FR-07, FR-08, FR-11, CONV-01, CONV-02, CONV-13, CONV-14, CONV-23, CONV-24.
- **Unit tests:** `cli_test.rb` (10 tests).

## 4. Algorithms
The only non-trivial algorithm is the scan (§3.2). It has no table of short flags, because
dp-hello has none: the first letter after `-` is either a value option, which consumes the
rest of the token (CONV-07), or an invalid option. Values are recorded, never checked,
during the scan, so the CONV-12 precedence rules follow from the control flow: the scan
returns as soon as it reaches `--help`/`--version`, and only syntax errors can be raised
before that point.

## 5. Platform-specific details

| Concern | Linux | macOS | Windows | Abstraction |
| :-- | :-- | :-- | :-- | :-- |
| Line endings | LF | LF | Text mode would write CRLF; binary mode writes LF | `Output.write` (`binmode`) |
| Argument encoding | Bytes, tagged with the locale encoding | Same | UTF-16 command line converted by Ruby; may be tagged with a code page | `Arguments.normalize` |
| Broken pipe | `Errno::EPIPE` | `Errno::EPIPE` | `Errno::EPIPE` or `Errno::EINVAL` | `Output.write` |
| Starting the launcher | `#!` line | `#!` line | The runner (or Git Bash / MSYS2) reads the `#!` line | — |

## 6. Resource management
No files, sockets, or child processes. The output is at most 1000 greeting lines held in one
string; memory is O(count × name length). The streams belong to the process and are flushed
before `main` returns.

## 7. Sequence of one invocation
`dp-hello` (P01): the launcher requires `lib/dp_hello` and calls `CLI.main([])`;
`Arguments.normalize([])` → `[]`; `CLI.run([])` → `Options.parse` returns
`Parsed(:greet, nil, nil, [])` → `Validation.validate` returns `Config('World', 1)` →
`Greeting.text` returns `"Hello, World!\n"`; `Output.write($stdout, …)` writes 14 bytes in
binary mode; `main` returns 0 and the launcher calls `exit 0`.

## 8. Design-to-code checklist

| HLD component | LLD section | Source file(s) | Unit-test file(s) |
| :-- | :-- | :-- | :-- |
| Arguments | §3.1 | `src/lib/dp_hello/arguments.rb` | `src/test/arguments_test.rb` |
| Options | §3.2 | `src/lib/dp_hello/options.rb` | `src/test/options_test.rb` |
| Validation | §3.3, §3.4 | `src/lib/dp_hello/validation.rb` | `src/test/validation_test.rb` |
| Greeting | §3.5 | `src/lib/dp_hello/greeting.rb` | `src/test/greeting_test.rb` |
| Output | §3.6 | `src/lib/dp_hello/output.rb` | `src/test/cli_test.rb` |
| CLI, launcher | §3.7 | `src/lib/dp_hello/cli.rb`, `usage_error.rb`, `src/bin/dp-hello` | `src/test/cli_test.rb` |
