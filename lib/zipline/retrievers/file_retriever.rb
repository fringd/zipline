class Zipline::FileRetriever
  def self.build_for(item)
    return new(item) if item.is_a?(File)
  end

  def initialize(file)
    @file = file
  end

  def retrieve_into(destination)
    @file.rewind
    @file.binmode
    IO.copy_stream(@file, destination)
  ensure
    @file.close
  end

  def restartable?(_exception)
    false
  end
end
