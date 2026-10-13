# High-Level Design (HLD) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Implementation language | Ruby 4.0 (rb) |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |
| Status | Approved |
| Inputs | `specs/URD.md`, `specs/SRS.md`, `specs/user-manual.md`, `shared/CLI-CONVENTIONS.md` |

## 1. Introduction

### 1.1 Scope
`dp-hello` writes the greeting `Hello, NAME!` + LF to standard output COUNT times (SRS §1.2),
with `--name`, `--count`, `--help`, and `--version`, and reports usage errors with the exact
CONV-13/14 diagnostics and exit status 2. It reads no input, takes no operands, touches no
files or environment variables, and runs no subprocesses (SRS §3.3, §3.4, NFR-07).

### 1.2 Definitions and acronyms
| Term | Meaning |
| :-- | :-- |
| Scan | The single left-to-right pass over the arguments (CONV-12) |
| Syntax error | Unknown option, missing option argument, or `=value` on a flag; reported during the scan |
| Value error | Empty NAME, invalid COUNT, or an operand; reported after the scan |
| Launcher | The extensionless `#!/usr/bin/env ruby` script `src/bin/dp-hello` |

### 1.3 References
- SRS §3 (interfaces), §4 (FR-01 … FR-11), §5 (NFR-01 … NFR-07), §6 (diagnostics)
- CLI-CONV §2 (CONV-03, CONV-05), §3 (CONV-07 … CONV-12), §4 (CONV-13 … CONV-15), §8, CONV-31
- User manual, "HELP OUTPUT" (normative help text)

## 2. Requirements summary

| Area | SRS requirements | Architectural impact |
| :-- | :-- | :-- |
| Option parsing | FR-02, FR-06, FR-07, FR-08, FR-10, CONV-07 … CONV-12 | A hand-written scanner (`Options`) that only records values and stops at `--help`/`--version` |
| Validation | FR-03, FR-05, FR-09, FR-11 | A separate `Validation` unit run after the scan, so value and operand errors never precede help |
| Greeting | FR-01, FR-02, FR-04, NFR-05 | A pure function `Greeting.text(name, count)` |
| Output and encoding | NFR-01, CONV-03, CONV-05, CONV-25 | `Arguments` (UTF-8 arguments) and `Output` (binary-mode writes) isolate the platform concerns |
| Errors | FR-10, FR-11, CONV-13, CONV-14, CONV-24 | One `UsageError` type, formatted in exactly one place (`CLI.run`) |
| Build | NFR-06 | Makefile hooks over Ruby, Bundler, minitest, and RuboCop |

## 3. Architectural overview

### 3.1 Context diagram

```text
              argv ──▶ ┌──────────────────────────┐ ──▶ stdout (greeting / help / version)
  (no stdin, no files, │ dp-hello (Ruby launcher) │ ──▶ stderr (usage diagnostics)
   no environment)     └──────────────────────────┘ ──▶ exit status 0 or 2
```

### 3.2 Component (module) decomposition

| Component | Responsibility | Depends on |
| :-- | :-- | :-- |
| Launcher (`src/bin/dp-hello`) | Load the library and exit with `CLI.main(ARGV)` | CLI |
| `DpHello::Arguments` | Turn ARGV into UTF-8 strings on every OS | — |
| `DpHello::Options` | Scan arguments into a `Parsed` result or a syntax `UsageError` | UsageError |
| `DpHello::Validation` | Turn a `Parsed` greeting request into a `Config(name, count)` or a value `UsageError` | Options (types), UsageError |
| `DpHello::Greeting` | Build the greeting text (pure) | — |
| `DpHello::Output` | Write bytes to a stream in binary mode; swallow EPIPE | — |
| `DpHello::CLI` | `run(args) → [stdout, stderr, status]` (pure) and `main(argv)` (I/O shell) | all of the above |

### 3.3 Data flow
`ARGV` → `Arguments.normalize` → `CLI.run`: `Options.parse` returns `:help`, `:version`, or
`:greet` with the last `--name`/`--count` values and the operands; for `:greet`,
`Validation.validate` produces a `Config`, and `Greeting.text` the output text. Any
`UsageError` becomes the two-line diagnostic and status 2. `CLI.main` then writes stdout and
stderr through `Output.write` and returns the status, which the launcher passes to `exit`.

## 4. Key design decisions

| # | Decision | Alternatives considered | Rationale |
| :-- | :-- | :-- | :-- |
| D1 | Hand-written scanner; no `OptionParser` | Ruby's `optparse` | `optparse` accepts abbreviations and has its own messages, both forbidden (CONV-08, CONV-13) |
| D2 | Two phases: scan (syntax only), then validate | Validate values while scanning | CONV-12 (v1.4.0): value and operand errors must not precede `--help`/`--version` |
| D3 | Build the whole output in memory, then write once | Stream line by line | At most 1000 short lines; guarantees nothing reaches stdout on error (FR-11) |
| D4 | Pure `CLI.run` with a thin `CLI.main` shell | Write from inside the units | End-to-end unit tests without a subprocess; I/O in one place |
| D5 | Exceptions (`UsageError`) for usage errors | Result objects | Idiomatic Ruby; the single `rescue` in `CLI.run` is the only formatting point |
| D6 | Only the standard library at run time | Gems via Bundler at run time | Fast start (NFR-02); the launcher needs no `bundle exec` and installs as plain files |

## 5. Cross-platform strategy
`DpHello::Output` writes with `IO#binmode` and `IO#write` of the string's raw bytes, so Ruby
never converts LF to CRLF on Windows (CONV-03) or transcodes the text. `DpHello::Arguments`
makes every argument a UTF-8 string (CONV-05): on POSIX the bytes are taken as UTF-8
whatever the locale tag (the test environment has no `LANG`, CONV-06/29); on Windows, where
RubyInstaller builds ARGV from the UTF-16 command line, an argument that arrives in a legacy
code page is transcoded to UTF-8 and one that is already UTF-8 is kept. Paths are not used
(CONV-19 … CONV-21 do not apply). On Windows the black-box runner starts the launcher's
`#!` interpreter itself; users run it from Git Bash or MSYS2.

## 6. Error handling and diagnostics
Every usage error is a `DpHello::UsageError` whose message is the CONV-13 text after
`dp-hello: `. Syntax errors are raised by `Options`, value and operand errors by
`Validation`. `CLI.run` is the single place that formats `dp-hello: <message>` + LF +
`Try 'dp-hello --help' for more information.` + LF and maps it to status 2 (CONV-14). There
are no runtime errors apart from EPIPE, which `Output.write` reports as `false`; `CLI.main`
then exits quietly with status 141 (CONV-25). The tool never prints a stack trace (CONV-24):
all argument bytes, including invalid UTF-8, are handled as data.

## 7. Non-functional design

| Quality attribute | SRS reference | How the design achieves it |
| :-- | :-- | :-- |
| Performance / memory | NFR-02, CONV-31 | Standard library only, one write; measured about 45 ms and 0.2 MiB above the `ruby -e ''` baseline (MTP §4.4) |
| Portability | NFR-01 | Binary-mode output, UTF-8 argument normalization, CI on Linux, macOS, and Windows |
| Robustness | NFR-03 | Every argument list ends in a greeting, help, version, or a CONV-13 diagnostic |
| Security / input validation | NFR-07 | Reads only ARGV; no files, environment, or subprocesses |
| Maintainability | NFR-04, NFR-05 | One module per concern; pure parsing, validation, and greeting functions |

## 8. Risks and open issues

| Risk / issue | Likelihood | Impact | Mitigation |
| :-- | :-- | :-- | :-- |
| ARGV encoding differs between Ruby builds on Windows | M | H | `Arguments` handles both UTF-8 and code-page arguments; unit tests and the black-box suites in Windows CI |
| Interpreter start-up exceeds 300 ms on slow runners | L | M | No gems loaded at run time; measured well below the limit |
| Development gems with C extensions fail to build | L | M | Versions locked in Gemfile.lock; compilers in the container and via ruby/setup-ruby |

## 9. Approval

| Role | Name | Date | Decision |
| :-- | :-- | :-- | :-- |
| Author | Brandon Perkins | 2026-10-13 | Submitted |
| Reviewer | CI (container and native) | 2026-10-13 | Approved when all checks pass |
