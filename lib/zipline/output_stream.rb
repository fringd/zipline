# a ZipOutputStream that never rewinds output
# in order for that to be possible we store only uncompressed files
module Zipline
  class OutputStream < Zip::OutputStream

    #we need to be able to hand out own custom output in order to stream to browser
    def initialize(io, stream=false, encrypter=nil)
      # Create an io stream thing
      super StringIO.new, true
      # Overwrite it with my own
      @output_stream = io
    end

    def stream
      @output_stream
    end

    def put_next_entry(entry_name, size)
      new_entry = Zip::Entry.new(@file_name, entry_name)

      #THIS IS THE MAGIC, tells zip to look after data for size, crc
      new_entry.gp_flags = new_entry.gp_flags | 0x0008

      super(new_entry)

      # Uncompressed size in the local file header must be zero when bit 3
      # of the general purpose flags is set, so set the size after the header
      # has been written.
      new_entry.size = size
    end

    # just reset state, no rewinding required
    def finalize_current_entry
      if current_entry
        entry = current_entry
        super
        write_local_footer(entry)
      end
    end

    def write_local_footer(entry)
      @output_stream << [ 0x08074b50, entry.crc, entry.compressed_size, entry.size].pack('VVVV')
    end

    #never need to do this because we set correct sizes up front
    def update_local_headers
      nil
    end

    # helper to deal with difference between rubyzip 1.0 and 1.1
    def current_entry
      @currentEntry || @current_entry
    end
  end
end
