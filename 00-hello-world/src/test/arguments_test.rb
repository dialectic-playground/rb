# frozen_string_literal: true

require_relative 'test_helper'

class ArgumentsTest < Minitest::Test
  ZOE = 'Zoë'

  def normalize(arg)
    DpHello::Arguments.normalize([arg]).first
  end

  def test_utf8_arguments_are_kept
    result = normalize(ZOE)

    assert_equal Encoding::UTF_8, result.encoding
    assert_equal ZOE, result
  end

  def test_locale_tags_are_ignored_for_posix_bytes
    [Encoding::US_ASCII, Encoding::BINARY].each do |encoding|
      assert_equal ZOE, normalize(ZOE.b.force_encoding(encoding))
    end
  end

  def test_invalid_utf8_bytes_are_passed_through
    result = normalize("\xFF".b)

    assert_equal Encoding::UTF_8, result.encoding
    assert_equal "\xFF".b, result.b
  end

  def test_legacy_code_page_is_converted
    assert_equal ZOE, normalize(ZOE.encode(Encoding::Windows_1252))
  end

  def test_utf8_bytes_tagged_with_code_page_are_kept
    assert_equal ZOE, normalize(ZOE.b.force_encoding(Encoding::Windows_1252))
  end

  def test_input_is_not_mutated
    arg = ZOE.b

    normalize(arg)

    assert_equal Encoding::BINARY, arg.encoding
  end
end
