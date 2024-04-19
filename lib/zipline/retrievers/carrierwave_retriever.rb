class Zipline::CarrierwaveRetriever
  def self.build_for(item)
    if defined?(CarrierWave::Storage::Fog::File) && item.is_a?(CarrierWave::Storage::Fog::File)
      Zipline::HTTPRetriever.new(item.url)
    end
  end
end
