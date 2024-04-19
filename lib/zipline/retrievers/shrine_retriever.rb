class Zipline::ShrineRetriever
  def self.build_for(item)
    return unless defined?(Shrine::UploadedFile) && item.is_a?(Shrine::UploadedFile)
    new(item)
  end

  def initialize(shrine_uploaded_file)
    @shrine_uploaded_file = shrine_uploaded_file
  end

  def retrieve_into(destination)
    @shrine_uploaded_file.stream(destination)
  end

  def restartable?(_exception)
    false
  end
end
