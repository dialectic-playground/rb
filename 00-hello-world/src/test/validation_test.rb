# frozen_string_literal: true

require_relative 'test_helper'

class ValidationTest < Minitest::Test
  Options = DpHello::Options

  def validate(name: nil, count: nil, operands: [])
    DpHello::Validation.validate(
      Options::Parsed.new(action: :greet, name: name, count: count, operands: operands)
    )
  end

  def count_option(value, spelled = '--count')
    Options::OptionValue.new(value: value, spelled: spelled)
  end

  def name_option(value, spelled = '--name')
    Options::OptionValue.new(value: value, spelled: spelled)
  end

  def assert_usage(message, **)
    error = assert_raises(DpHello::UsageError) { validate(**) }
    assert_equal message, error.message
  end

  def test_defaults
    assert_equal DpHello::Validation::Config.new(name: 'World', count: 1), validate
  end

  def test_name_is_kept_verbatim
    assert_equal ' Zoë! ', validate(name: name_option(' Zoë! ')).name
  end

  def test_empty_name_is_rejected_with_spelling
    assert_usage "invalid argument '' for '--name'", name: name_option('')
    assert_usage "invalid argument '' for '-n'", name: name_option('', '-n')
  end

  def test_count_boundaries
    assert_equal 1, validate(count: count_option('1')).count
    assert_equal 1000, validate(count: count_option('1000')).count
    assert_usage "invalid argument '0' for '--count'", count: count_option('0')
    assert_usage "invalid argument '1001' for '-c'", count: count_option('1001', '-c')
  end

  def test_leading_zeros
    assert_equal 7, validate(count: count_option('007')).count
    assert_equal 1000, validate(count: count_option('0001000')).count
    assert_usage "invalid argument '000' for '--count'", count: count_option('000')
  end

  def test_huge_counts
    assert_usage "invalid argument '99999999999999999999' for '--count'", count: count_option('99999999999999999999')
    assert_usage "invalid argument '00010000' for '--count'", count: count_option('00010000')
  end

  def test_non_digits
    ['', 'abc', '-1', '+1', ' 1', '1 ', '1.0', '1e3', '0x10', '١', "1\n"].each do |value|
      assert_usage "invalid argument '#{value}' for '--count'", count: count_option(value)
    end
  end

  def test_operands_are_rejected_first
    assert_usage "extra operand 'extra'", operands: %w[extra more], count: count_option('0')
    assert_usage "extra operand '-n'", operands: ['-n']
  end

  def test_name_is_checked_before_count
    assert_usage "invalid argument '' for '-n'", name: name_option('', '-n'), count: count_option('0')
  end
end
