# frozen_string_literal: true

require_relative 'test_helper'

class OptionsTest < Minitest::Test
  def parse(*args)
    DpHello::Options.parse(args)
  end

  def assert_usage(message, *)
    error = assert_raises(DpHello::UsageError) { parse(*) }
    assert_equal message, error.message
  end

  def option(value, spelled)
    DpHello::Options::OptionValue.new(value: value, spelled: spelled)
  end

  def test_no_arguments
    parsed = parse

    assert_equal :greet, parsed.action
    assert_nil parsed.name
    assert_nil parsed.count
    assert_empty parsed.operands
  end

  def test_name_forms
    assert_equal option('Ada', '--name'), parse('--name', 'Ada').name
    assert_equal option('Ada', '--name'), parse('--name=Ada').name
    assert_equal option('Ada', '-n'), parse('-n', 'Ada').name
    assert_equal option('Ada', '-n'), parse('-nAda').name
  end

  def test_count_forms
    assert_equal option('3', '--count'), parse('--count', '3').count
    assert_equal option('3', '--count'), parse('--count=3').count
    assert_equal option('3', '-c'), parse('-c', '3').count
    assert_equal option('3', '-c'), parse('-c3').count
  end

  def test_bundled_short_option_consumes_rest_of_token
    parsed = parse('-c2', '-nKen')

    assert_equal option('2', '-c'), parsed.count
    assert_equal option('Ken', '-n'), parsed.name
    assert_equal option('n5', '-c'), parse('-cn5').count
  end

  def test_values_may_start_with_a_dash
    assert_equal option('-x', '--name'), parse('--name=-x').name
    assert_equal option('-x', '-n'), parse('-n-x').name
    assert_equal option('-x', '--name'), parse('--name', '-x').name
    assert_equal option('--help', '-n'), parse('-n', '--help').name
  end

  def test_empty_values_are_recorded_not_rejected
    assert_equal option('', '--name'), parse('--name=').name
    assert_equal option('', '-n'), parse('-n', '').name
  end

  def test_last_occurrence_wins
    assert_equal option('B', '-n'), parse('-n', 'A', '--name=X', '-n', 'B').name
    assert_equal option('abc', '--count'), parse('-c', '2', '--count', 'abc').count
  end

  def test_operands_are_collected
    assert_equal %w[extra more], parse('extra', '-n', 'A', 'more').operands
    assert_equal ['-'], parse('-').operands
  end

  def test_terminator
    assert_equal ['-n', '--help'], parse('--', '-n', '--help').operands
    assert_equal ['--'], parse('--', '--').operands
    assert_empty parse('--').operands
  end

  def test_help_and_version
    assert_equal :help, parse('--help').action
    assert_equal :version, parse('--version').action
  end

  def test_first_of_help_and_version_wins
    assert_equal :help, parse('--help', '--version').action
    assert_equal :version, parse('--version', '--help').action
  end

  def test_help_stops_the_scan
    assert_equal :help, parse('--help', 'extra', '-x').action
  end

  def test_operand_and_value_errors_do_not_precede_help
    assert_equal :help, parse('extra', '--help').action
    assert_equal :help, parse('--count', '0', '--help').action
    assert_equal :version, parse('-n', '', '--version').action
  end

  def test_syntax_error_before_help_wins
    assert_usage "invalid option -- 'x'", '-x', '--help'
  end

  def test_unknown_short_option
    assert_usage "invalid option -- 'x'", '-x'
    assert_usage "invalid option -- 'x'", '-xn', 'A'
    assert_usage "invalid option -- 'ë'", '-ë'
  end

  def test_unknown_long_option_reports_whole_token
    assert_usage "unrecognized option '--nme'", '--nme', 'Ada'
    assert_usage "unrecognized option '--nam'", '--nam', 'Ada'
    assert_usage "unrecognized option '--colour=red'", '--colour=red'
    assert_usage "unrecognized option '---name'", '---name'
  end

  def test_missing_arguments
    assert_usage "option requires an argument -- 'n'", '-n'
    assert_usage "option requires an argument -- 'c'", '-c'
    assert_usage "option '--name' requires an argument", '--name'
    assert_usage "option '--count' requires an argument", '--count'
  end

  def test_flags_reject_arguments
    assert_usage "option '--help' doesn't allow an argument", '--help='
    assert_usage "option '--version' doesn't allow an argument", '--version=1'
  end
end
