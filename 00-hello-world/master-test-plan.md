<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [Master Test Plan (MTP) — Standard Terminal Hello World](#master-test-plan-mtp--standard-terminal-hello-world)
  - [1. Introduction and scope](#1-introduction-and-scope)
    - [1.1 Objectives](#11-objectives)
    - [1.2 In scope / out of scope](#12-in-scope--out-of-scope)
  - [2. Test items](#2-test-items)
  - [3. Test levels and approach](#3-test-levels-and-approach)
  - [4. Test design](#4-test-design)
    - [4.1 Equivalence partitions and boundaries](#41-equivalence-partitions-and-boundaries)
    - [4.2 Additional test cases (beyond the supplied suite)](#42-additional-test-cases-beyond-the-supplied-suite)
    - [4.3 Negative and robustness testing](#43-negative-and-robustness-testing)
    - [4.4 Performance and resource testing](#44-performance-and-resource-testing)
  - [5. Test environments](#5-test-environments)
  - [6. Entry and exit criteria](#6-entry-and-exit-criteria)
  - [7. Defect management](#7-defect-management)
  - [8. Schedule and deliverables](#8-schedule-and-deliverables)
  - [9. Risks and contingencies](#9-risks-and-contingencies)
  - [10. Test summary (complete at the end)](#10-test-summary-complete-at-the-end)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Master Test Plan (MTP) — Standard Terminal Hello World

| Field                   | Value                                                  |
| :---------------------- | :----------------------------------------------------- |
| Project                 | `00-hello-world`                                       |
| Tools                   | dp-hello                                               |
| Implementation language | Ruby 4.0 (rb)                                          |
| Author                  | Brandon Perkins                                        |
| Version / date          | 1.0 — 2026-10-13                                       |
| Standard                | Structure adapted from IEEE 829 / ISO/IEC/IEEE 29119-3 |

## 1. Introduction and scope

### 1.1 Objectives

"Tested enough" means: every SRS acceptance criterion (FR-01 … FR-11) is exercised by a unit
test or a black-box test, every CONV-13 diagnostic is produced exactly, the public and hidden
suites pass on Linux, macOS, and Windows, and RuboCop reports no offenses.

### 1.2 In scope / out of scope

| In scope                                                  | Out of scope                                                             |
| :-------------------------------------------------------- | :----------------------------------------------------------------------- |
| Every FR and NFR in the SRS, on Linux, macOS, and Windows | Terminal rendering of non-ASCII names (the consumer's concern)           |
| Applicable CONV requirements (RTM §2)                     | CONV-04, CONV-16, CONV-17, CONV-19 … CONV-21 (no input, files, or paths) |
| Install / uninstall round trip                            | Packaging as a gem                                                       |

## 2. Test items

| Item                   | Version / location                                    |
| :--------------------- | :---------------------------------------------------- |
| dp-hello               | `00-hello-world/src/` on branch `feat/00-hello-world` |
| Unit tests             | `00-hello-world/src/test/` (49 minitest tests)        |
| Public black-box suite | `tests/public/` (10 tests)                            |
| Hidden black-box suite | `tests/private/` (10 tests, run by CI)                |

## 3. Test levels and approach

| Level              | Purpose                                                           | Technique(s)                                                                        | Tooling                                        | Owner            |
| :----------------- | :---------------------------------------------------------------- | :---------------------------------------------------------------------------------- | :--------------------------------------------- | :--------------- |
| Unit               | Each unit in isolation (arguments, options, validation, greeting) | Equivalence partitioning, boundary-value analysis                                   | minitest (`make test-unit`)                    | Implementer      |
| Integration        | Parser → validation → greeting → output, in process               | Scenario tests on `CLI.run` and `CLI.main` with `StringIO` streams (binary capture) | minitest (`cli_test.rb`)                       | Implementer      |
| System (black-box) | The specified CLI behavior, byte-exact                            | Specification-based                                                                 | `make test` → `run-tests.py`                   | Implementer      |
| Acceptance         | Hidden suite passes on all OSes                                   | —                                                                                   | CI `make check` (runs `test-hidden`)           | CI               |
| Static analysis    | Style and lint                                                    | —                                                                                   | RuboCop (`make lint`), `ruby -w` for the tests | Implementer / CI |

## 4. Test design

### 4.1 Equivalence partitions and boundaries

| Input             | Valid partitions                                                    | Invalid partitions                                                                   | Boundaries                                      |
| :---------------- | :------------------------------------------------------------------ | :----------------------------------------------------------------------------------- | :---------------------------------------------- |
| NAME              | Any non-empty string: ASCII, spaces, non-ASCII (`Zoë`), leading `-` | Empty string                                                                         | `''` vs one character                           |
| COUNT             | ASCII digits with value 1–1000, leading zeros                       | Empty, non-digits (`abc`, `-1`, `+1`, spaces, `1.0`, Arabic-Indic digits), 0, > 1000 | 0, 1, 1000, 1001; `000`; 20-digit values        |
| Options           | `-n`/`-c` attached or separate, `--name=`/`--name V`, repeated      | Unknown short/long, abbreviated long, missing value, `--help=x`                      | Value at end of the argument list               |
| Operands          | none                                                                | Any operand, `-`, tokens after `--`                                                  | `--` alone (valid)                              |
| Help/version      | `--help`, `--version` anywhere before a syntax error                | Syntax error before them                                                             | `extra --help`, `--count 0 --help`, `-x --help` |
| Argument encoding | UTF-8 bytes with any locale tag; Windows code page                  | —                                                                                    | Invalid UTF-8 bytes (passed through)            |

### 4.2 Additional test cases (beyond the supplied suite)

| ID   | Requirement(s) | Preconditions    | Steps / command                                                    | Expected result                                                     | Level       |
| :--- | :------------- | :--------------- | :----------------------------------------------------------------- | :------------------------------------------------------------------ | :---------- |
| T-01 | FR-04          | —                | `validate_count` with `1`, `1000`, `0`, `1001`                     | 1 and 1000 accepted; 0 and 1001 rejected (`test_count_boundaries`)  | unit        |
| T-02 | FR-04          | —                | `007`, `0001000`, `000`                                            | 7, 1000, rejected (`test_leading_zeros`)                            | unit        |
| T-03 | FR-05, NFR-03  | —                | `99999999999999999999`, `00010000`                                 | Rejected without a big-integer conversion (`test_huge_counts`)      | unit        |
| T-04 | FR-05          | —                | 11 non-digit values                                                | Each rejected verbatim (`test_non_digits`)                          | unit        |
| T-05 | FR-03          | —                | `--name=` and `-n ''`                                              | `invalid argument '' for '--name'` / `'-n'`                         | unit        |
| T-06 | CONV-07        | —                | `-c2 -nKen`, `-cn5`                                                | Rest of the token is the value                                      | unit        |
| T-07 | FR-02          | —                | `--name=-x`, `-n-x`, `--name -x`, `-n --help`                      | Values beginning with `-` are names                                 | unit        |
| T-08 | CONV-12        | —                | `extra --help`, `--count 0 --help`, `-n '' --version`, `-x --help` | Help, help, version, invalid option                                 | unit        |
| T-09 | CONV-09, FR-09 | —                | `-- -n --help`, `-- --`                                            | Operands; `extra operand '-n'`                                      | unit        |
| T-10 | FR-10          | —                | `--nam`, `---name`, `--colour=red`, `-ë`                           | `unrecognized option` with the whole token; `invalid option -- 'ë'` | unit        |
| T-11 | CONV-05        | —                | Argument `Zoë` tagged US-ASCII / BINARY / Windows-1252 bytes       | `Hello, Zoë!` in UTF-8 (`arguments_test.rb`, `cli_test.rb`)         | unit        |
| T-12 | CONV-03        | —                | `CLI.main(['-në'])` into a `StringIO`                              | Exactly `Hello, ë!\n` bytes, no CR                                  | integration |
| T-13 | CONV-25        | Closed stdout    | `CLI.main([])`                                                     | Returns 141, nothing on stderr                                      | integration |
| T-14 | NFR-06         | Temporary PREFIX | `make roundtrip`                                                   | Launcher installed, prints the version, then removed                | system      |

### 4.3 Negative and robustness testing

Invalid options, values, and operands: T-03 … T-10 and P09, P10. Invalid UTF-8 bytes in
every position (`--\xFF=x`, `-\xFF`, `--name=\xFF`, `-c\xFF`, a bare `\xFF` operand) were run
by hand under `LANG=C`: each produced the specified diagnostic or greeting with the bytes
passed through, and no stack trace; `arguments_test.rb::test_invalid_utf8_bytes_are_passed_through`
keeps this covered. stdin is never read (CONV-26), so empty, large, or binary input does not
apply; files are not used.

### 4.4 Performance and resource testing

Measured with `/usr/bin/time -f "%e s %M KiB"` on Fedora 44 (Ruby 4.0.6, x86_64), three runs
each: the runtime baseline `ruby -e ''` took 0.04–0.06 s with a peak RSS of about 14.6 MiB;
`dp-hello -c 1000` took 0.04 s with a peak RSS of 14.5–14.8 MiB, so less than 0.3 MiB above
the baseline. This meets NFR-02 (under 300 ms for an interpreted runtime; under 32 MiB above
the baseline, CONV-31). The tool loads no gems at run time.

## 5. Test environments

| Environment | OS / version                                          | Toolchain                                                                       | How provisioned               |
| :---------- | :---------------------------------------------------- | :------------------------------------------------------------------------------ | :---------------------------- |
| Container   | Debian trixie (`ruby:4.0-slim-trixie`, digest-pinned) | Ruby 4.0, Bundler, gcc for gem extensions, python3                              | `Containerfile`, `make check` |
| Local       | Fedora 44                                             | Ruby 4.0.6 (black-box suite and round trip; the gems need `ruby-devel`)         | `DP_RUNTIME=local`            |
| CI          | ubuntu-latest, macos-latest, windows-latest           | ruby/setup-ruby 4.0 (Windows: RubyInstaller with the MSYS2 devkit), Python 3.12 | `.github/workflows/ci.yml`    |

## 6. Entry and exit criteria

- **Entry:** HLD and LLD complete, `make all` succeeds, `make lint` is clean.
- **Exit:** all unit tests and all public and hidden black-box tests pass on all three
  operating systems and in the container, `make format` leaves no diff, `make roundtrip`
  passes, and the RTM shows every applicable requirement as Verified.
- **Suspension / resumption:** suspend on any CI failure; resume once the failing case has a
  reproducing unit test and a fix.

## 7. Defect management

Defects are recorded as GitHub issues in `dialectic-playground/rb` with the severity below
and the failing command. A fix is accepted only with a new unit test that fails before the
fix, and is re-tested by the full CI matrix.

| Severity     | Definition                                                                                   |
| :----------- | :------------------------------------------------------------------------------------------- |
| 1 — Critical | Crash, stack trace, or wrong output on a mainline path                                       |
| 2 — Major    | Wrong diagnostic, exit status, or platform-specific difference (for example CRLF on Windows) |
| 3 — Minor    | Lint, documentation, or build-script issue with no behavioral impact                         |

## 8. Schedule and deliverables

| Milestone               | Deliverable                      | Target date |
| :---------------------- | :------------------------------- | :---------- |
| Design complete         | hld.md, lld.md                   | 2026-10-13  |
| Implementation complete | src/, unit tests, Makefile hooks | 2026-10-13  |
| Verification complete   | RTM all Verified, CI green       | 2026-10-13  |

## 9. Risks and contingencies

| Risk                                       | Mitigation                                                                     |
| :----------------------------------------- | :----------------------------------------------------------------------------- |
| Windows-only failure (ARGV encoding, CRLF) | CI on all three OSes from the first commit; encoding unit tests                |
| Gem C extensions fail to build on a runner | Locked versions; compilers in the container; setup-ruby provides the toolchain |
| RuboCop version drift between environments | One Gemfile.lock for every environment                                         |

## 10. Test summary (complete at the end)

| Metric                                | Value                                                                             |
| :------------------------------------ | :-------------------------------------------------------------------------------- |
| Unit tests (pass / total)             | 49 / 49 (152 assertions)                                                          |
| Coverage (line / branch)              | Not measured (no coverage gem added); every public function has direct unit tests |
| Public black-box (pass / 10)          | 10 / 10 (container, local, and CI)                                                |
| Hidden black-box (pass / 10, from CI) | 10 / 10                                                                           |
| Open defects by severity              | 0 / 0 / 0                                                                         |
