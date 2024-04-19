class Zipline::StringRetriever
  def self.build_for(item)
    return unless item.is_a?(String)
    new(item)
  end

  def initialize(string)
    @string = string
  end

  def retrieve_into(destination)
    chunk_size = 1024
    offset = 0
    loop do
      bytes = @string.byteslice(offset, chunk_size)
      offset += chunk_size
      destination.write(bytes)
      break if bytes.nil?
    end
  end

  def restartable?(_exception)
    false
  end
end
