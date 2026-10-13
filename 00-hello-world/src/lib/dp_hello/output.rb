# frozen_string_literal: true

module DpHello
  # Writes bytes to the process streams in binary mode, so LF is never translated to CRLF on
  # Windows and no transcoding happens (CONV-03, CONV-05).
  module Output
    module_function

    # Writes +text+ to +stream+ as raw bytes. Returns false if the reader has gone away
    # (EPIPE, CONV-25), true otherwise.
    def write(stream, text)
      stream.binmode
      stream.write(text.b)
      stream.flush
      true
    rescue Errno::EPIPE, Errno::EINVAL, IOError
      false
    end
  end
end
