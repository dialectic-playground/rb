# frozen_string_literal: true

module DpHello
  # Command-line arguments as UTF-8 strings on every operating system (CONV-05).
  module Arguments
    # Encodings whose tag carries no information about the bytes: on POSIX the locale (often
    # US-ASCII under the minimal test environment) is ignored and the bytes are taken as UTF-8.
    TAG_ONLY = [Encoding::UTF_8, Encoding::US_ASCII, Encoding::BINARY].freeze

    module_function

    # Returns a copy of +args+ with every element tagged UTF-8 and never transcoded on POSIX.
    #
    # On Windows, Ruby builds ARGV from the UTF-16 command line. If an element arrives in a
    # legacy code page (for example Windows-1252) instead of UTF-8, it is converted from that
    # encoding; bytes that are already valid UTF-8 are kept as they are (CONV-05, CONV-06).
    def normalize(args)
      args.map { |arg| to_utf8(arg) }
    end

    def to_utf8(arg)
      return arg.dup.force_encoding(Encoding::UTF_8) if TAG_ONLY.include?(arg.encoding)

      as_utf8 = arg.dup.force_encoding(Encoding::UTF_8)
      return as_utf8 if as_utf8.valid_encoding? || !arg.valid_encoding?

      arg.encode(Encoding::UTF_8)
    rescue EncodingError
      as_utf8
    end
  end
end
