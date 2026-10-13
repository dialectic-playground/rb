# frozen_string_literal: true

module DpHello
  # Greeting construction: a pure function of its arguments (NFR-05).
  module Greeting
    module_function

    # The greeting line "Hello, NAME!" + LF, repeated +count+ times (FR-01, FR-02, FR-04).
    def text(name, count)
      "Hello, #{name}!\n" * count
    end
  end
end
