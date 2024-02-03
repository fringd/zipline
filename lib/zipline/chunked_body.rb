module Zipline
  # A body wrapper that emits chunked responses, creating valid
  # "Transfer-Encoding: chunked" HTTP response body. This is copied from Rack::Chunked::Body,
  # because Rack is not going to include that class after version 3.x
  # Rails has a substitute class for this inside ActionController::Streaming,
  # but that module is a private constant in the Rails codebase, and is thus
  # considered "private" from the Rails standpoint. It is not that much code to
  # carry, so we copy it into our code.
  class Chunked
    TERM = "\r\n"
    TAIL = "0#{TERM}"

    def initialize(body)
      @body = body
    end

    # For each string yielded by the response body, yield
    # the element in chunked encoding - and finish off with a terminator
    def each
      term = TERM
      @body.each do |chunk|
        size = chunk.bytesize
        next if size == 0

        yield [size.to_s(16), term, chunk.b, term].join
      end
      yield TAIL
      yield term
    end
  end
end
