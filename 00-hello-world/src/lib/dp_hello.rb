# frozen_string_literal: true

# dp-hello: print a greeting to standard output (curriculum project 00-hello-world).
#
# Units (NFR-04): Arguments (UTF-8 command line), Options (parsing), Validation, Greeting
# (pure text construction), Output (binary-mode streams), and CLI (the pure run function and
# the thin process shell that wires them together).
module DpHello
  PROGRAM = 'dp-hello'
end

require_relative 'dp_hello/usage_error'
require_relative 'dp_hello/arguments'
require_relative 'dp_hello/options'
require_relative 'dp_hello/validation'
require_relative 'dp_hello/greeting'
require_relative 'dp_hello/output'
require_relative 'dp_hello/cli'
