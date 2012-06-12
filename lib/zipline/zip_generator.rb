# this class acts as a streaming body for rails
# initialize it with an array of the files you want to zip
# right now only carrierwave is supported with file storage or S3
module Zipline
  class ZipGenerator
    # takes an array of pairs [[uploader, filename], ... ]
    def initialize(files)
      @files = files
    end

    def precalculate_size
      ZipSizeCalculator.new(@files).size
    end

    #this is supposed to be streamed!
    def to_s
      throw "stop!"
    end

    def each(&block)
      output = new_output(&block)
      ZipOutputStream.open(output) do |zip|
        @files.each do |file, name|
          file = file.file

          #normalize file
          if file.class.to_s == 'CarrierWave::Storage::Fog::File'
            file = file.send(:file)
          end
          if file.class.to_s == 'CarrierWave::SanitizedFile'
            path = file.send(:file)
            file = File.open(path)
          end
          throw "bad_file" unless %w{Fog::Storage::AWS::File File}.include? file.class.to_s

          name = uniquify_name(name)
          write_file(zip, file, name)
        end
      end
    end

    def new_output(&block)
      FakeStream.new(&block)
    end

    def write_file(zip, file, name)
      size = get_size(file)

      zip.put_next_entry name, size

      if file.is_a? File
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
      case file.class.to_s
      when 'File'
        file.size
      when 'Fog::Storage::AWS::FILE'
        file.content_length
      end
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
