# a ZipOutputStream that never rewinds output
# in order for that to be possible we store only uncompressed files
module Zipline
  class ZipOutputStream < Zip::ZipOutputStream

    #we need to be able to hand out own custom output in order to stream to browser
    def initialize(io)
      # Create an io stream thing
      super '-', true
      # Overwrite it with my own
      @outputStream = io
    end

    def stream
      @outputStream
    end

    def put_next_entry(entry_name, size)
      @givenSize = size
      #same as normal ZipOutputStream
      new_entry = Zip::ZipEntry.new(@filename, entry_name)

      #always use passthrough compressor
      new_entry.compression_method = Zip::ZipEntry::DEFLATED

      #defer crc and size until the footer
      new_entry.gp_flags = new_entry.gp_flags | 0x0008

      #will write header and set @current_entry and whatever else needs doing
      init_next_entry(new_entry)

      @currentEntry = new_entry
    end

    # just reset state, no rewinding required
    def finalize_current_entry
      if @currentEntry
        entry = @currentEntry
        super
        write_local_footer(entry)
      end
    end

    def write_local_footer(entry)
      @outputStream << [ 0x08074b50, entry.crc, 0, entry.compressed_size, 0, entry.size].pack('VVVVVV')
    end

    #never need to do this because we set correct sizes up front
    def update_local_headers
      nil
    end
  end
end
