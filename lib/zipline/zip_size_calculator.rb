# this class does a "dry run" of the zip generator
# it only pays attention to the file names and their sizes
# all data is faked with strings that lie about their size
# and it is all written to a stream that ignores data and
# just checks for size

module Zipline
  class ZipSizeCalculator < ZipGenerator

    def new_output(&block)
      @output = FakeStreamFaker.new
    end

    def write_file(zip, file, name)
      size = get_size(file)
      zip.put_next_entry name, size
      f=FakeString.new(' ')
      f.fakesize=size
      zip << f
      size
    end

    def size
      #fake rendering
      self.each do |blah|
        #nooop
      end

      @output.pos
    end
  end
end
