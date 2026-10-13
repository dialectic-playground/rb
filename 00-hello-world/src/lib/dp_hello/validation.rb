# frozen_string_literal: true

module DpHello
  # Turns a :greet parse result into a validated Config (FR-03, FR-05, FR-06, FR-09).
  module Validation
    # A validated greeting request: +name+ is non-empty and 1 <= +count+ <= 1000.
    Config = Data.define(:name, :count)

    DEFAULT_NAME = 'World'
    DEFAULT_COUNT = 1
    MAX_COUNT = 1000
    DIGITS = /\A[0-9]+\z/

    module_function

    # Checks operands first, then the winning --name and --count values (in that order).
    def validate(parsed)
      raise UsageError, "extra operand '#{parsed.operands.first}'" unless parsed.operands.empty?

      name = parsed.name ? validate_name(parsed.name) : DEFAULT_NAME
      count = parsed.count ? validate_count(parsed.count) : DEFAULT_COUNT
      Config.new(name: name, count: count)
    end

    # Any non-empty name is accepted verbatim (FR-02, FR-03).
    def validate_name(option)
      raise invalid(option) if option.value.empty?

      option.value
    end

    # ASCII digits only, leading zeros allowed, value 1-1000 (FR-04, FR-05). Leading zeros are
    # stripped before conversion so that a huge digit string is never turned into an Integer.
    def validate_count(option)
      text = option.value
      raise invalid(option) unless text.b.match?(DIGITS)

      significant = text.sub(/\A0+/, '')
      value = significant.length > MAX_COUNT.to_s.length ? MAX_COUNT + 1 : significant.to_i
      raise invalid(option) unless value.between?(1, MAX_COUNT)

      value
    end

    def invalid(option)
      UsageError.new("invalid argument '#{option.value}' for '#{option.spelled}'")
    end
  end
end
