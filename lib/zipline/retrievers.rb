class Zipline::IORetriever
  def self.build_for(item)
    return new(item) if item.respond_to?(:read) && item.respond_to?(:read_nonblock)
  end

  def initialize(io)
    @io = io
  end

  def each_chunk
    chunk_size = 1024
    while (bytes = @io.read(chunk_size))
      yield(bytes)
    end
  end
end

class Zipline::FileRetriever < Zipline::IORetriever
  def self.build_for(item)
    return super(item) if item.is_a?(File)
  end

  def each_chunk(&blk)
    @io.rewind
    super(&blk)
  ensure
    @io.close
  end
end

class Zipline::HTTPRetriever
  def self.build_for(url)
    return unless item && item.is_a?(String) && item.start_with?("http")
    new(item)
  end

  def initialize(url)
    @uri = URI(url)
  end

  def each_chunk(&block)
    Net::HTTP.get_response(@uri) do |response|
      response.read_body(&block)
    end
  end

  def may_restart_after?(e)
    # Server error, IO error etc
    false
  end
end

class Zipline::StringRetriever
  def self.build_for(item)
    return unless item.is_a?(String)
    new(item)
  end

  def initialize(string)
    @string = string
  end

  def each_chunk
    chunk_size = 1024
    offset = 0
    loop do
      bytes = @string.byteslice(offset, chunk_size)
      offset += chunk_size
      break if bytes.nil?
      yield(bytes)
    end
  end

  def may_restart_after?(e)
    false
  end
end

class Zipline::CarrierwaveRetriever
  def self.build_for(item)
    if defined?(CarrierWave::Storage::Fog::File) && item.is_a?(CarrierWave::Storage::Fog::File)
      return Zipline::HTTPRetriever.new(item.url)
    end
  end
end

class Zipline::ActiveStorageRetriever
  def self.build_for(item)
    return unless defined?(ActiveStorage)
    return new(item.blob) if is_active_storage_attachment?(item) || is_active_storage_one?(item)
    return new(item) if is_active_storage_blob?(item)
    nil
  end


  def self.is_active_storage_attachment?(item)
    defined?(ActiveStorage::Attachment) && item.is_a?(ActiveStorage::Attachment)
  end

  def self.is_active_storage_one?(item)
    defined?(ActiveStorage::Attached::One) && item.is_a?(ActiveStorage::Attached::One)
  end

  def self.is_active_storage_blob?(item)
    defined?(ActiveStorage::Blob) && item.is_a?(ActiveStorage::Blob)
  end

  def initialize(blob)
    @blob = blob
  end

  def each_chunk(&block)
    @blob.download(&block)
  end
end

class Zipline::PaperclipRetriever
  def self.build_for(item)
    return unless defined?(Paperclip) && item.is_a?(Paperclip::Attachment)
    if item.options[:storage] == :filesystem
      Zipline::FileRetriever.build_for(File.open(item.path, "rb"))
    else
      Zipline::HTTPRetriever.build_for(file.expiring_url)
    end
  end
end
