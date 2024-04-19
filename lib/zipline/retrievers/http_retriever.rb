class Zipline::HTTPRetriever
  def self.build_for(url_or_uri)
    return unless url_or_uri.is_a?(URI) || url_or_uri.is_a?(String) && url_or_uri.start_with?("http")

    uri = begin
      URI.parse(url_or_uri)
    rescue
      return
    end

    return new(uri) if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  end

  def initialize(uri)
    @uri = uri
  end

  def retrieve_into(destination)
    Net::HTTP.get_response(@uri) do |response|
      response.read_body do |chunk|
        destination.write(chunk)
      end
    end
  end

  def restartable?(exception)
    restartables = [
      Net::HTTPServerError,
      Net::HTTPClientException,
      Net::HTTPServiceUnavailable
    ]
    restartables.any? { |net_http_server_error_class| net_http_server_error_class === exception }
  end
end
