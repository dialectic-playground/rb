# frozen_string_literal: true

require_relative 'test_helper'

class GreetingTest < Minitest::Test
  def test_default_name_once
    assert_equal "Hello, World!\n", DpHello::Greeting.text('World', 1)
  end

  def test_name_is_used_verbatim
    assert_equal "Hello, Ada Lovelace!\n", DpHello::Greeting.text('Ada Lovelace', 1)
  end

  def test_non_ascii_name_is_utf8
    assert_equal "Hello, Zoë!\n".b, DpHello::Greeting.text('Zoë', 1).b
  end

  def test_repetition
    assert_equal "Hello, Ken!\nHello, Ken!\n", DpHello::Greeting.text('Ken', 2)
  end

  def test_maximum_count
    text = DpHello::Greeting.text('X', 1000)

    assert_equal 1000, text.lines.length
    assert(text.lines.all?("Hello, X!\n"))
  end

  def test_is_pure
    first = DpHello::Greeting.text('A', 3)

    assert_equal first, DpHello::Greeting.text('A', 3)
  end
end
