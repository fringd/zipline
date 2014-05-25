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
      output = new_output(&block)
      OutputStream.open(output) do |zip|
        @files.each {|file, name| handle_file(zip, file, name) }
      end
    end

    def handle_file(zip, file, name)
      file = normalize(file)
      name = uniquify_name(name)
      write_file(zip, file, name)
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

    def new_output(&block)
      FakeStream.new(&block)
    end

    def write_file(zip, file, name)
      size = get_size(file)
      zip.put_next_entry name, size

      if is_io?(file)
        while buffer = file.read(2048)
          zip << buffer
        end
      else
        the_remote_url = file.url(Time.now + 1.minutes)
        c = Curl::Easy.new(the_remote_url) do |curl|
          curl.on_body do |data|
            zip << data
            data.bytesize
          end
        end
        c.perform
      end
    end

    def get_size(file)
      if is_io?(file) || file.respond_to?(:size)
        file.size
      elsif file.respond_to? :content_length
        file.content_length
      else
        throw 'cannot determine file size'
      end
    end

    def is_io?(file)
      file.is_a?(IO) || (defined?(StringIO) && file.is_a?(StringIO))
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
