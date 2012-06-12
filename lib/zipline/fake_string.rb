module Zipline
  #this pretends to be longer than it is
  class FakeString < String
    attr_accessor :fakesize

    #don't let to_s let people
    def to_s
      self
    end

    def bytesize
      @fakesize
    end

    def length
      @fakesize
    end
  end
end
