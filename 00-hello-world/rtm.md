# Requirements Traceability Matrix (RTM) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |

Code paths are relative to `src/lib/dp_hello/` (launcher: `src/bin/dp-hello`); unit tests are
in `src/test/` and cited as `file::test_name`. Black-box tests: public `P01` … `P10`. The
hidden suite runs in CI on Linux, macOS, and Windows and is not cited.

## 1. User requirements to system requirements

| User requirement (URD) | Derived system requirements (SRS) |
| :-- | :-- |
| UR-01 | FR-01 |
| UR-02 | FR-02 |
| UR-03 | FR-04 |
| UR-04 | FR-07 |
| UR-05 | FR-08 |
| UR-06 | FR-03, FR-05, FR-09, FR-10, FR-11 |
| UR-07 | FR-01, SRS §3.7 |
| UR-08 | NFR-01, CONV-03 |
| UR-09 | FR-02, CONV-05 |
| UR-10 | FR-06, FR-10, CONV-01 … CONV-15, CONV-22 … CONV-26 |
| UR-11 | NFR-02 |
| UR-12 | NFR-06 |

## 2. Forward traceability

| Req. ID | Summary | Design (HLD/LLD) | Code (file::function) | Verification (unit / black-box) | Status |
| :-- | :-- | :-- | :-- | :-- | :-- |
| UR-01 … UR-12 | User needs | HLD §2 | via the derived FR/NFR (§1) | via the derived FR/NFR | Verified |
| FR-01 | Default greeting | HLD §3.3, LLD §3.3, §3.5 | `validation.rb::validate`, `greeting.rb::text` | `validation_test.rb::test_defaults`, `greeting_test.rb::test_default_name_once`, `cli_test.rb::test_default_greeting`, P01 | Verified |
| FR-02 | Named greeting, verbatim | LLD §3.2, §3.5 | `options.rb::Scanner#scan_long`, `#scan_short`, `greeting.rb::text` | `options_test.rb::test_name_forms`, `::test_values_may_start_with_a_dash`, `greeting_test.rb::test_name_is_used_verbatim`, `::test_non_ascii_name_is_utf8`, P02, P03, P04 | Verified |
| FR-03 | Empty name rejected | LLD §3.3 | `validation.rb::validate_name` | `validation_test.rb::test_empty_name_is_rejected_with_spelling`, `cli_test.rb::test_main_reports_usage_errors_on_stderr` | Verified |
| FR-04 | Repetition 1–1000 | LLD §3.4, §3.5 | `validation.rb::validate_count`, `greeting.rb::text` | `validation_test.rb::test_count_boundaries`, `::test_leading_zeros`, `greeting_test.rb::test_repetition`, `::test_maximum_count`, P05, P06 | Verified |
| FR-05 | Invalid count rejected | LLD §3.4 | `validation.rb::validate_count` | `validation_test.rb::test_count_boundaries`, `::test_huge_counts`, `::test_non_digits`, `cli_test.rb::test_usage_error_writes_nothing_to_stdout` | Verified |
| FR-06 | Last occurrence wins | LLD §3.2, §3.3 | `options.rb::Scanner#scan_long`, `#scan_short` | `options_test.rb::test_last_occurrence_wins` | Verified |
| FR-07 | Help, scan order | LLD §3.2, §3.7 | `options.rb::Scanner#scan_long`, `cli.rb::run`, `HELP_TEXT` | `cli_test.rb::test_help_text`, `::test_help_after_operand`, `options_test.rb::test_help_stops_the_scan`, `::test_operand_and_value_errors_do_not_precede_help`, P07 | Verified |
| FR-08 | Version | LLD §3.7 | `cli.rb::run`, `VERSION_TEXT` | `cli_test.rb::test_version`, `options_test.rb::test_first_of_help_and_version_wins`, P08 | Verified |
| FR-09 | Operands rejected | LLD §3.2, §3.3 | `options.rb::Scanner#scan_token`, `validation.rb::validate` | `options_test.rb::test_operands_are_collected`, `::test_terminator`, `validation_test.rb::test_operands_are_rejected_first`, P10 | Verified |
| FR-10 | Unknown / malformed options | LLD §2.4, §3.2 | `options.rb::Scanner#scan_long`, `#scan_short`, `#next_value` | `options_test.rb::test_unknown_short_option`, `::test_unknown_long_option_reports_whole_token`, `::test_missing_arguments`, `::test_flags_reject_arguments`, P09 | Verified |
| FR-11 | Nothing on stdout on error | HLD D3, LLD §3.7 | `cli.rb::run`, `::main` | `cli_test.rb::test_usage_error_writes_nothing_to_stdout`, `::test_main_reports_usage_errors_on_stderr`, P09, P10 | Verified |
| NFR-01 | Byte-identical, LF only | HLD §5, LLD §3.6, §5 | `output.rb::write` | `cli_test.rb::test_main_writes_binary_lf_output`, P01–P10 on three OSes in CI | Verified |
| NFR-02 | < 300 ms (interpreted), < 32 MiB above baseline | HLD §7, D6 | `src/bin/dp-hello` (standard library only) | Measurement, MTP §4.4 | Verified |
| NFR-03 | No crash or stack trace | HLD §6 | `cli.rb::run`, `arguments.rb::to_utf8` | `arguments_test.rb::test_invalid_utf8_bytes_are_passed_through`, `validation_test.rb::test_huge_counts`, MTP §4.3 | Verified |
| NFR-04 | Separate units | HLD §3.2, LLD §8 | `options.rb`, `validation.rb`, `greeting.rb`, `output.rb` | Design review (LLD §8) | Verified |
| NFR-05 | Pure greeting function | LLD §3.5 | `greeting.rb::text` | `greeting_test.rb` (all), `::test_is_pure` | Verified |
| NFR-06 | Every Makefile target works | README, `Makefile` hooks | `00-hello-world/Makefile` | CI: `make check roundtrip` (native), `make check` (container) | Verified |
| NFR-07 | No files, environment, subprocesses | HLD §1.1, §7 | all of `src/lib/` (inspection: no `File`, `ENV`, `system`) | Inspection | Verified |
| CONV-01 | Canonical name | LLD §3.7 | `dp_hello.rb::PROGRAM`, `cli.rb::run` | `cli_test.rb::test_usage_error_writes_nothing_to_stdout`, P07–P10 | Verified |
| CONV-02 | Version line | LLD §3.7 | `cli.rb::VERSION_TEXT` | `cli_test.rb::test_version`, P08 | Verified |
| CONV-03 | LF output, binary mode | HLD §5 | `output.rb::write` | `cli_test.rb::test_main_writes_binary_lf_output`, P01–P10 | Verified |
| CONV-04 | Byte-for-byte copying | — | not applicable: dp-hello copies no input | — | N/A |
| CONV-05 | UTF-8 arguments | HLD §5, LLD §3.1 | `arguments.rb::normalize`, `::to_utf8` | `arguments_test.rb` (all), `cli_test.rb::test_main_normalizes_locale_tagged_arguments` | Verified |
| CONV-06 | Locale-independent | HLD §5 | `arguments.rb::to_utf8` (ignores locale tags) | `arguments_test.rb::test_locale_tags_are_ignored_for_posix_bytes`, P01–P10 (no `LANG`) | Verified |
| CONV-07 | Short options, attached values | LLD §3.2, §4 | `options.rb::Scanner#scan_short` | `options_test.rb::test_bundled_short_option_consumes_rest_of_token`, P06 | Verified |
| CONV-08 | Long options, no abbreviation | LLD §3.2 | `options.rb::Scanner#scan_long` | `options_test.rb::test_name_forms`, `::test_unknown_long_option_reports_whole_token`, P04 | Verified |
| CONV-09 | `--` terminator | LLD §3.2 | `options.rb::Scanner#scan_token` | `options_test.rb::test_terminator` | Verified |
| CONV-10 | Operands, `-` | LLD §3.2 | `options.rb::Scanner#scan_token` | `options_test.rb::test_operands_are_collected` | Verified |
| CONV-11 | Repetition | LLD §3.2 | `options.rb::Scanner` | `options_test.rb::test_last_occurrence_wins`, `::test_first_of_help_and_version_wins` | Verified |
| CONV-12 | Scan order | HLD D2, LLD §4 | `options.rb::Scanner#scan`, `validation.rb::validate` | `options_test.rb::test_help_stops_the_scan`, `::test_operand_and_value_errors_do_not_precede_help`, `::test_syntax_error_before_help_wins`, `cli_test.rb::test_help_after_operand` | Verified |
| CONV-13 | Diagnostic formats | LLD §2.4 | `options.rb`, `validation.rb::invalid` | `options_test.rb` error tests, `validation_test.rb` error tests, P09, P10 | Verified |
| CONV-14 | "Try" line, exit 2 | HLD §6 | `cli.rb::run` | `cli_test.rb::test_usage_error_writes_nothing_to_stdout`, P09, P10 | Verified |
| CONV-15 | Values verbatim, `''` | LLD §2.1 | `validation.rb::invalid` | `validation_test.rb::test_empty_name_is_rejected_with_spelling`, `::test_non_digits` | Verified |
| CONV-16, CONV-17 | File errors, multiple operands | — | not applicable: dp-hello uses no files and accepts no operands | — | N/A |
| CONV-18 | Exit statuses 0 / 2 (never 1, SRS §3.7) | HLD §6 | `cli.rb::EXIT_SUCCESS`, `::EXIT_USAGE`, `::run` | `cli_test.rb::test_default_greeting`, `::test_usage_error_writes_nothing_to_stdout`, P01–P10 | Verified |
| CONV-19 … CONV-21 | Paths and traversal | — | not applicable: dp-hello uses no paths | — | N/A |
| CONV-22 | `--help`, `--version`, no argument | LLD §3.2 | `options.rb::Scanner#scan_long` | `options_test.rb::test_help_and_version`, `::test_flags_reject_arguments` | Verified |
| CONV-23 | Help text verbatim | LLD §3.7 | `cli.rb::HELP_TEXT` | `cli_test.rb::test_help_text`, P07 | Verified |
| CONV-24 | No crash | HLD §6 | `cli.rb::run`, `arguments.rb::to_utf8` | MTP §4.3, `arguments_test.rb::test_invalid_utf8_bytes_are_passed_through` | Verified |
| CONV-25 | EPIPE: quiet exit | LLD §3.6 | `output.rb::write`, `cli.rb::main` | `cli_test.rb::test_main_stops_quietly_on_broken_pipe` | Verified |
| CONV-26 | No stdin | HLD §1.1 | nothing reads `$stdin` | Inspection | Verified |
| CONV-27 … CONV-30 | Harness conditions | HLD §5 | `src/bin/dp-hello` (`#!/usr/bin/env ruby`) | P01–P10 | Verified |
| CONV-31 | Memory above runtime baseline | HLD §7 | — | Measurement, MTP §4.4 | Verified |

## 3. Backward traceability (test → requirement)

| Test | Type | Requirement(s) verified |
| :-- | :-- | :-- |
| P01 | black-box, public | FR-01, NFR-01, CONV-03 |
| P02, P03, P04 | black-box, public | FR-02, CONV-08 (P04) |
| P05, P06 | black-box, public | FR-04, CONV-07 (P06) |
| P07 | black-box, public | FR-07, CONV-23 |
| P08 | black-box, public | FR-08, CONV-02 |
| P09 | black-box, public | FR-10, FR-11, CONV-13, CONV-14 |
| P10 | black-box, public | FR-09, FR-11, CONV-13, CONV-14 |
| `arguments_test.rb` (6) | unit | CONV-05, CONV-06, NFR-03 |
| `options_test.rb` (18) | unit | FR-02, FR-06 … FR-10, CONV-07 … CONV-13, CONV-22 |
| `validation_test.rb` (9) | unit | FR-01, FR-03 … FR-06, FR-09, CONV-13, CONV-15 |
| `greeting_test.rb` (6) | unit | FR-01, FR-02, FR-04, NFR-05 |
| `cli_test.rb` (10) | unit (end to end, in process) | FR-01, FR-07, FR-08, FR-11, NFR-01, CONV-01 … CONV-03, CONV-05, CONV-14, CONV-23, CONV-25 |

## 4. Coverage summary

| Category | Total | Designed | Implemented | Verified |
| :-- | :-- | :-- | :-- | :-- |
| User requirements (UR) | 12 | 12 | 12 | 12 |
| Functional (FR) | 11 | 11 | 11 | 11 |
| Non-functional (NFR) | 7 | 7 | 7 | 7 |
| Conventions (CONV) | 31 | 25 applicable | 25 | 25 (6 N/A) |

## 5. Gaps and justifications
None. CONV-04, CONV-16, CONV-17, and CONV-19 … CONV-21 do not apply to dp-hello (no input, files, or paths).
NFR-02 is verified by measurement rather than an automated test (MTP §4.4).
