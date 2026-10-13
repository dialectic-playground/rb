# frozen_string_literal: true

module DpHello
  # Hand-written option parser (CONV-07 ... CONV-12): syntax only, no value validation.
  module Options
    # A recorded option value and the option as the user wrote it ("-n" or "--name").
    OptionValue = Data.define(:value, :spelled)

    # The scan result. +action+ is :help, :version, or :greet. For :greet, +name+ and +count+
    # are the last occurrences (CONV-11) or nil, and +operands+ are all operands in order.
    Parsed = Data.define(:action, :name, :count, :operands)

    # Options that take a value (long name and short letter) and the flags.
    LONG_VALUE_OPTIONS = { 'name' => :name, 'count' => :count }.freeze
    SHORT_VALUE_OPTIONS = { 'n' => :name, 'c' => :count }.freeze
    FLAGS = { 'help' => :help, 'version' => :version }.freeze

    # Scans +args+ left to right. Returns a Parsed at the first --help/--version, or after the
    # last argument. Raises UsageError for the first option syntax error before that point.
    def self.parse(args)
      Scanner.new(args).scan
    end

    # The state of one left-to-right scan: the remaining tokens, recorded values, operands.
    class Scanner
      def initialize(args)
        @tokens = args.dup
        @values = {}
        @operands = []
      end

      def scan
        until @tokens.empty?
          token = @tokens.shift
          action = scan_token(token)
          return Parsed.new(action: action, name: nil, count: nil, operands: []) if action
        end
        Parsed.new(action: :greet, name: @values[:name], count: @values[:count], operands: @operands)
      end

      private

      # Handles one token; returns :help or :version to stop the scan, otherwise nil.
      def scan_token(token)
        return scan_long(token) if token.start_with?('--') && token != '--'

        if token == '--'
          @operands.concat(@tokens.shift(@tokens.length))
        elsif token.start_with?('-') && token != '-'
          scan_short(token)
        else
          @operands << token
        end
        nil
      end

      # Returns :help or :version for those flags, otherwise records the value and returns nil.
      def scan_long(token)
        name, separator, attached = token[2..].partition('=')
        if (flag = FLAGS[name])
          raise UsageError, "option '--#{name}' doesn't allow an argument" unless separator.empty?

          return flag
        end
        key = LONG_VALUE_OPTIONS.fetch(name) { raise UsageError, "unrecognized option '#{token}'" }
        value = separator.empty? ? next_value("option '--#{name}' requires an argument") : attached
        @values[key] = OptionValue.new(value: value, spelled: "--#{name}")
        nil
      end

      # A short option takes its value from the rest of the token or, if that is empty, from
      # the next token (CONV-07). dp-hello has no short flags, so the first letter decides.
      def scan_short(token)
        letter = token[1]
        key = SHORT_VALUE_OPTIONS.fetch(letter) { raise UsageError, "invalid option -- '#{letter}'" }
        attached = token[2..]
        value = attached.empty? ? next_value("option requires an argument -- '#{letter}'") : attached
        @values[key] = OptionValue.new(value: value, spelled: "-#{letter}")
      end

      def next_value(missing_message)
        raise UsageError, missing_message if @tokens.empty?

        @tokens.shift
      end
    end
  end
end
