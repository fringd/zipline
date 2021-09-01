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
      # ZipTricks outputs lots of strings in rapid succession, and with
      # servers it can be beneficial to avoid doing too many tiny writes so that
      # the number of syscalls is minimized. See https://github.com/WeTransfer/zip_tricks/issues/78
      # There is a built-in facility for this in ZipTricks which can be used to implement
      # some cheap buffering here (it exists both in version 4 and version 5). The buffer is really
      # tiny and roughly equal to the medium Linux socket buffer size (16 KB). Although output
      # will be not so immediate with this buffering the overall performance will be better,
      # especially with multiple clients being serviced at the same time.
      # Note that the WriteBuffer writes the same, retained String object - but the contents
      # of that object changes between calls. This should work fine with servers where the
      # contents of the string gets written to a socket immediately before the execution inside
      # the WriteBuffer resumes), but if the strings get retained somewhere - like in an Array -
      # this might pose a problem. Unlikely that it will be an issue here though.
      write_buffer_size = 16 * 1024
      write_buffer = ZipTricks::WriteBuffer.new(fake_io_writer, write_buffer_size)
      ZipTricks::Streamer.open(write_buffer) do |streamer|
        @files.each do |file, name, options = {}|
          handle_file(streamer, file, name.to_s, options)
        end
      end
      write_buffer.flush! # for any remaining writes
    end

    def handle_file(streamer, file, name, options)
      file = normalize(file)
      write_file(streamer, file, name, options)
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
      elsif is_io?(file)
        {file: file}
      elsif defined?(ActiveStorage::Blob) && file.is_a?(ActiveStorage::Blob)
        {blob: file}
      elsif is_active_storage_attachment?(file) || is_active_storage_one?(file)
        {blob: file.blob}
      elsif file.respond_to? :url
        {url: file.url}
      elsif file.respond_to? :path
        {file: File.open(file.path)}
      elsif file.respond_to? :file
        {file: File.open(file.file)}
      elsif is_url?(file)
        {url: file}
      else
        raise(ArgumentError, 'Bad File/Stream')
      end
    end

    def write_file(streamer, file, name, options)
      streamer.write_deflated_file(name, **options.slice(:modification_time)) do |writer_for_file|
        if file[:url]
          the_remote_uri = URI(file[:url])

          Net::HTTP.get_response(the_remote_uri) do |response|
            response.read_body do |chunk|
              writer_for_file << chunk
            end
          end
        elsif file[:file]
          IO.copy_stream(file[:file], writer_for_file)
          file[:file].close
        elsif file[:blob]
          file[:blob].download { |chunk| writer_for_file << chunk }
        else
          raise(ArgumentError, 'Bad File/Stream')
        end
      end
    end

    def is_io?(io_ish)
      io_ish.respond_to? :read
    end

    private

    def is_active_storage_attachment?(file)
      defined?(ActiveStorage::Attachment) && file.is_a?(ActiveStorage::Attachment)
    end

    def is_active_storage_one?(file)
      defined?(ActiveStorage::Attached::One) && file.is_a?(ActiveStorage::Attached::One)
    end

    def is_url?(url)
      url = URI.parse(url) rescue false
      url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    end
  end
end
