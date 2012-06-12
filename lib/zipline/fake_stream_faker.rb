module Zipline

  #this is just to facilitate precalculation
  #it just tracks the size of the input given it
  class FakeStreamFaker < FakeStream
    def initialize
      @pos = 0
    end

    def <<(x)
      return if x.nil?
      @pos += x.bytesize
    end
  end
end
