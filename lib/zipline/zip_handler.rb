class Zipline::ZipHandler
  def initialize(streamer, logger)
    @streamer = streamer
    @logger = logger
  end
  
  def handle_file(file, name, options)
    write_item(file, name, options)
  rescue => e
    # Since most APM packages do not trace errors occurring within streaming
    # Rack bodies, it can be helpful to print the error to the Rails log at least
    error_message = "zipline: an exception (#{e.inspect}) was raised  when serving the ZIP body."
    error_message += " The error occurred when handling file #{name.inspect}"
    @logger&.error(error_message)
    raise
  end

  def write_item(item, name, options)
    retriever = pick_retriever_for(item)
    @streamer.write_file(name, **options.slice(:modification_time)) do |writer_for_file|
      retriever.each_chunk do |bytes|
        writer_for_file << bytes
      end
    end
  end

  def pick_retriever_for(item)
    retriever_classes = [
      Zipline::CarrierwaveRetriever,
      Zipline::ActiveStorageRetriever,
      Zipline::PaperclipRetriever,
      Zipline::FileRetriever,
      Zipline::IORetriever,
      Zipline::HTTPRetriever,
      Zipline::StringRetriever,
    ]
    retriever_classes.each do |retriever_class|
      maybe_retriever = retriever_class.build_for(item)
      return maybe_retriever if maybe_retriever
    end

    raise "Don't know how to handle a file in the shape of #{file_argument.inspect}" unless retriever
  end
end
