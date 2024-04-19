class Zipline::PaperclipRetriever
  def self.build_for(item)
    return unless defined?(Paperclip) && item.is_a?(Paperclip::Attachment)
    if item.options[:storage] == :filesystem
      Zipline::FileRetriever.build_for(File.open(item.path, "rb"))
    else
      Zipline::HTTPRetriever.build_for(file.expiring_url)
    end
  end
end
