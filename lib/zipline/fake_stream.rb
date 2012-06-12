#this is a class that acts like an IO::Stream, but really puts to the browser
module Zipline
  class FakeStream

    # &block is the block that each gets from rails... we pass it strings to send data
    def initialize(&block)
      @block = block
      @pos = 0
    end

    def tell
      @pos
    end

    def pos
      @pos
    end

    def seek
      throw :fit
    end

    def pos=
      throw :fit
    end

    def to_s
      throw :fit
    end

    def <<(x)
      return if x.nil?
      throw "bad class #{x.class}" unless x.class == String
      @pos += x.bytesize
      @block.call(x.to_s)
    end

    def close
      nil
    end

  end
end
