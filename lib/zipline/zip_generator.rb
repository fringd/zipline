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
      name = uniquify_name(name)
      write_file(streamer, file, name)
    end

    def normalize(file)
      unless is_io?(file)
        if file.respond_to?(:url) && (!defined?(::Paperclip::Attachment) || !file.is_a?(::Paperclip::Attachment))
          file = file
        elsif file.respond_to? :file
          file = File.open(file.file)
        elsif file.respond_to? :path
          file = File.open(file.path)
        else
          raise(ArgumentError, 'Bad File/Stream')
        end
      end
      file
    end

    def write_file(streamer, file, name)
      streamer.add_stored_entry(name) do |writer_for_file|
        if is_io?(file)
          IO.copy_stream(file, writer_for_file)
        else
          the_remote_url = file.url(Time.now + 1.minutes)
          c = Curl::Easy.new(the_remote_url) do |curl|
            curl.on_body do |data|
              writer_for_file << data
              data.bytesize
            end
          end
          c.perform
        end
      end
    end

    def is_io?(io_ish)
      io_ish.respond_to? :read
    end

    def uniquify_name(name)
      @used_names ||= Set.new

      if @used_names.include?(name)

        #remove suffix e.g. ".foo"
        parts = name.split '.'
        name, extension =
          if parts.length == 1
            #no suffix, e.g. README
            parts << ''
          else
            extension = parts.pop
            [parts.join('.'), ".#{extension}"]
          end

        #trailing _#{number}
        pattern = /_(\d+)$/

        unless name.match pattern
          name = "#{name}_1"
        end

        while @used_names.include? name + extension
          #increment trailing number
          name = name.sub( pattern ) { |x| "_#{$1.to_i + 1}" }
        end

        #reattach suffix
        name += extension
      end

      @used_names << name
      name
    end
  end
end
