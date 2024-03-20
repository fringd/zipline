class Zipline::IORetriever
  def self.build_for(item)
    return new(item) if item.respond_to?(:read) && item.respond_to?(:read_nonblock)
  end

  def initialize(io)
    @io = io
  end

  def download_and_write_into(destination)
    IO.copy_stream(@io, destination)
  end
end

class Zipline::FileRetriever < Zipline::IORetriever
  def self.build_for(item)
    return super(item) if item.is_a?(File)
  end

  def download_and_write_into(destination)
    @io.rewind
    super(destination)
  ensure
    @io.close
  end
end

class Zipline::HTTPRetriever
  def self.build_for(url_or_uri)
    uri = begin
      URI.parse(url_or_uri)
    rescue
      return
    end
    return new(uri) if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  end

  def initialize(uri)
    @uri = uri
  end

  def download_and_write_into(destination)
    Net::HTTP.get_response(@uri) do |response|
      response.read_body do |chunk|
        destination.write(destination)
      end
    end
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

  def download_and_write_into(destination)
    chunk_size = 1024
    offset = 0
    loop do
      bytes = @string.byteslice(offset, chunk_size)
      offset += chunk_size
      destination.write(bytes)
      break if bytes.nil?
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

  def download_and_write_into(destination)
    @blob.download do |bytes|
      destination.write(bytes)
    end
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
