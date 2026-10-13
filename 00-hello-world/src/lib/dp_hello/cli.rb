# frozen_string_literal: true

module DpHello
  # Wires the units together: a pure run function and a thin process shell around it.
  module CLI
    EXIT_SUCCESS = 0
    EXIT_USAGE = 2
    # CONV-25 leaves the status after a broken pipe unspecified; use the shell's SIGPIPE status.
    EXIT_BROKEN_PIPE = 141

    VERSION_TEXT = "#{PROGRAM} (dialectic-playground) 1.0.0\n".freeze
    HELP_TEXT = <<~HELP.freeze
      Usage: #{PROGRAM} [OPTION]...
      Print a greeting to standard output.

      Options:
        -n, --name=NAME     greet NAME instead of World
        -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)
            --help          display this help and exit
            --version       output version information and exit
    HELP

    module_function

    # Runs dp-hello on +args+ (UTF-8 strings, without the program name) and returns
    # [stdout text, stderr text, exit status]. Performs no I/O.
    def run(args)
      [stdout_text(Options.parse(args)), '', EXIT_SUCCESS]
    rescue UsageError => e
      ['', "#{PROGRAM}: #{e.message}\nTry '#{PROGRAM} --help' for more information.\n", EXIT_USAGE]
    end

    def stdout_text(parsed)
      case parsed.action
      when :help then HELP_TEXT
      when :version then VERSION_TEXT
      else
        config = Validation.validate(parsed)
        Greeting.text(config.name, config.count)
      end
    end

    # Process entry point: normalizes ARGV, runs, writes, and returns the exit status.
    def main(argv, stdout: $stdout, stderr: $stderr)
      out, err, status = run(Arguments.normalize(argv))
      return EXIT_BROKEN_PIPE unless Output.write(stdout, out)

      Output.write(stderr, err) unless err.empty?
      status
    end
  end
end
