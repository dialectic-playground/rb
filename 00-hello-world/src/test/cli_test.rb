# frozen_string_literal: true

require 'stringio'
require_relative 'test_helper'

class CLITest < Minitest::Test
  CLI = DpHello::CLI
  TRY = "Try 'dp-hello --help' for more information.\n"

  def test_default_greeting
    assert_equal ["Hello, World!\n", '', 0], CLI.run([])
  end

  def test_named_repeated_greeting
    assert_equal ["Hello, Ken!\nHello, Ken!\n", '', 0], CLI.run(['-c2', '-n', 'Ken'])
  end

  def test_help_text
    out, err, status = CLI.run(['--help'])

    assert_equal <<~HELP, out
      Usage: dp-hello [OPTION]...
      Print a greeting to standard output.

      Options:
        -n, --name=NAME     greet NAME instead of World
        -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)
            --help          display this help and exit
            --version       output version information and exit
    HELP
    assert_equal ['', 0], [err, status]
  end

  def test_help_after_operand
    assert_equal [CLI::HELP_TEXT, '', 0], CLI.run(%w[extra --help])
  end

  def test_version
    assert_equal ["dp-hello (dialectic-playground) 1.0.0\n", '', 0], CLI.run(['--version'])
  end

  def test_usage_error_writes_nothing_to_stdout
    assert_equal ['', "dp-hello: invalid option -- 'x'\n#{TRY}", 2], CLI.run(['-x'])
    assert_equal ['', "dp-hello: extra operand 'extra'\n#{TRY}", 2], CLI.run(['extra'])
    assert_equal ['', "dp-hello: invalid argument '0' for '--count'\n#{TRY}", 2], CLI.run(%w[--count 0])
  end

  def test_main_writes_binary_lf_output
    stdout = StringIO.new
    stderr = StringIO.new

    assert_equal 0, CLI.main(['-në'], stdout: stdout, stderr: stderr)
    assert_equal "Hello, ë!\n".b, stdout.string.b
    assert_empty stderr.string
  end

  def test_main_reports_usage_errors_on_stderr
    stdout = StringIO.new
    stderr = StringIO.new

    assert_equal 2, CLI.main(['--name='], stdout: stdout, stderr: stderr)
    assert_empty stdout.string
    assert_equal "dp-hello: invalid argument '' for '--name'\n#{TRY}", stderr.string
  end

  def test_main_normalizes_locale_tagged_arguments
    stdout = StringIO.new
    arg = '-nZoë'.b.force_encoding(Encoding::US_ASCII)

    assert_equal 0, CLI.main([arg], stdout: stdout, stderr: StringIO.new)
    assert_equal "Hello, Zoë!\n".b, stdout.string.b
  end

  def test_main_stops_quietly_on_broken_pipe
    closed = StringIO.new
    closed.close_write
    stderr = StringIO.new

    assert_equal CLI::EXIT_BROKEN_PIPE, CLI.main([], stdout: closed, stderr: stderr)
    assert_empty stderr.string
  end
end
