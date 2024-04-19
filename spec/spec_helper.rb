require "rspec"
require "active_support"
require "active_support/core_ext"
require "action_dispatch"

require "zipline"
require "paperclip"
require "fog-aws"
require "carrierwave"

Dir["#{File.expand_path("..", __FILE__)}/support/**/*.rb"].sort.each { |f| require f }

CarrierWave.configure do |config|
  config.fog_provider = "fog/aws"
  config.fog_credentials = {
    provider: "AWS",
    aws_access_key_id: "dummy",
    aws_secret_access_key: "data",
    region: "us-west-2"
  }
end

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.run_all_when_everything_filtered = true
end
