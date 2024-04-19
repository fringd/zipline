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
    error_message += " The error occurred when handling file #{name.inspect} which was a #{file.class}"
    @logger&.error(error_message)
    raise
  end

  def write_item(item, name, options)
    retriever = pick_retriever_for(item)
    attempts = 0
    begin
      attempts += 1
      @streamer.write_file(name, **options.slice(:modification_time)) do |writable|
        ActiveSupport::Notifications.instrument("zipline.retrieve_and_write", {retriever_class: retriever.class.to_s, filename: name}) do
          retriever.retrieve_into(writable)
        end
      end
    rescue => exception
      # If an exception is raised and it is known to be caused by the data retrieval from
      # remote, we can retry outputting this particular file. ZipKit will rollback the file
      # before raising the exception to us, so we can just redo the `write_file` call.
      if retriever.restartable?(exception)
        @logger.warn { "Reattempting of #{name.inspect} will be reattempted after #{exception}" }
        retry
      else
        @logger.warn { "Retrieval of #{name.inspect} cannot be restarted after #{exception}, abprting" }
        raise
      end
    end
  end

  def pick_retriever_for(item)
    retriever_classes = [
      Zipline::CarrierwaveRetriever,
      Zipline::ActiveStorageRetriever,
      Zipline::PaperclipRetriever,
      Zipline::ShrineRetriever,
      Zipline::FileRetriever,
      Zipline::IORetriever,
      Zipline::HTTPRetriever,
      Zipline::StringRetriever
    ]
    retriever_classes.each do |retriever_class|
      maybe_retriever = retriever_class.build_for(item)
      return maybe_retriever if maybe_retriever
    end

    raise "Don't know how to handle a file in the shape of #{item.inspect}"
  end
end
