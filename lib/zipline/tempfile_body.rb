# Contains a file handle which can be closed once the response finishes sending.
# It supports `to_path` so that `Rack::Sendfile` can intercept it
class Zipline::TempfileBody
  TEMPFILE_NAME_PREFIX = "zipline-tf-body-"
  attr_reader :tempfile

  # @param body[#each] the enumerable that yields bytes, usually a `RackBody`.
  #   The `body` will be read in full immediately and closed.
  def initialize(env, body)
    @tempfile = Tempfile.new(TEMPFILE_NAME_PREFIX)
    # Rack::TempfileReaper calls close! on tempfiles which get buffered
    # We wil assume that it works fine with Rack::Sendfile (i.e. the path
    # to the file getting served gets used before we unlink the tempfile)
    env['rack.tempfiles'] ||= []
    env['rack.tempfiles'] << @tempfile

    @tempfile.binmode

    body.each { |bytes| @tempfile << bytes }
    body.close if body.respond_to?(:close)

    @tempfile.flush
  end

  # Returns the size of the contained `Tempfile` so that a correct
  # Content-Length header can be set
  #
  # @return [Integer]
  def size
    @tempfile.size
  end

  # Returns the path to the `Tempfile`, so that Rack::Sendfile can send this response
  # using the downstream webserver
  #
  # @return [String]
  def to_path
    @tempfile.to_path
  end

  # Stream the file's contents if `Rack::Sendfile` isn't present.
  #
  # @return [void]
  def each
    @tempfile.rewind
    while chunk = @tempfile.read(16384)
      yield chunk
    end
  end
end
