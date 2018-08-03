# this class acts as a streaming body for rails
# initialize it with an array of the files you want to zip
module Zipline
  class ZipGenerator
    # takes an array of pairs [[uploader, filename], ... ]
    def initialize(files)
      @files = files
    end

    #this is supposed to be streamed!
    def to_s
      throw "stop!"
    end

    def each(&block)
      fake_io_writer = ZipTricks::BlockWrite.new(&block)
      ZipTricks::Streamer.open(fake_io_writer) do |streamer|
        @files.each {|file, name| handle_file(streamer, file, name) }
      end
    end

    def handle_file(streamer, file, name)
      file = normalize(file)
      write_file(streamer, file, name)
    end

    # This extracts either a url or a local file from the provided file.
    # Currently support carrierwave and paperclip local and remote storage.
    # returns a hash of the form {url: aUrl} or {file: anIoObject}
    def normalize(file)
      if defined?(CarrierWave::Uploader::Base) && file.is_a?(CarrierWave::Uploader::Base)
        file = file.file
      end

      if defined?(Paperclip) && file.is_a?(Paperclip::Attachment)
        if file.options[:storage] == :filesystem
          {file: File.open(file.path)}
        else
          {url: file.expiring_url}
        end
      elsif defined?(CarrierWave::Storage::Fog::File) && file.is_a?(CarrierWave::Storage::Fog::File)
        {url: file.url}
      elsif defined?(CarrierWave::SanitizedFile) && file.is_a?(CarrierWave::SanitizedFile)
        {file: File.open(file.path)}
      elsif file.respond_to? :url
        {url: file.url}
      elsif is_io?(file)
        {file: file}
      elsif defined?(ActiveStorage::Blob) && file.is_a?(ActiveStorage::Blob)
        {url: file.service_url}
      elsif file.respond_to? :path
        {file: File.open(file.path)}
      elsif file.respond_to? :file
        {file: File.open(file.file)}
      else
        raise(ArgumentError, 'Bad File/Stream')
      end
    end

    def write_file(streamer, file, name)
      streamer.write_deflated_file(name) do |writer_for_file|
        if file[:url]
          the_remote_url = file[:url]
          c = Curl::Easy.new(the_remote_url) do |curl|
            curl.on_body do |data|
              writer_for_file << data
              data.bytesize
            end
          end
          c.perform
        elsif file[:file]
          IO.copy_stream(file[:file], writer_for_file)
          file[:file].close
        else
          raise(ArgumentError, 'Bad File/Stream')
        end
      end
    end

    def is_io?(io_ish)
      io_ish.respond_to? :read
    end
  end
end
