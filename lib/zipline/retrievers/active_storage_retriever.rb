class Zipline::ActiveStorageRetriever
  def self.build_for(item)
    return unless defined?(ActiveStorage)
    return new(item.blob) if is_active_storage_attachment?(item) || is_active_storage_one?(item)
    return new(item) if is_active_storage_blob?(item)
    nil
  end

  def self.is_active_storage_attachment?(item)
    item.is_a?(ActiveStorage::Attachment)
  end

  def self.is_active_storage_one?(item)
    item.is_a?(ActiveStorage::Attached::One)
  end

  def self.is_active_storage_blob?(item)
    item.is_a?(ActiveStorage::Blob)
  end

  def initialize(blob)
    @blob = blob
  end

  def retrieve_into(destination)
    @blob.download do |bytes|
      destination.write(bytes)
    end
  end

  def restartable?(_exception)
    false
  end
end
