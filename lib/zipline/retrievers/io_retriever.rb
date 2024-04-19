class Zipline::IORetriever
  def self.build_for(item)
    return new(item) if item.respond_to?(:read) && item.respond_to?(:read_nonblock)
  end

  def initialize(io)
    @io = io
  end

  def retrieve_into(destination)
    IO.copy_stream(@io, destination)
  end

  def restartable?(_exception)
    false
  end
end
