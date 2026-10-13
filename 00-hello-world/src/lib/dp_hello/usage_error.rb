# frozen_string_literal: true

module DpHello
  # A usage error (CONV-13): the message is the diagnostic text after "dp-hello: ".
  # The CLI turns it into the two-line diagnostic and exit status 2 (CONV-14).
  class UsageError < StandardError; end
end
