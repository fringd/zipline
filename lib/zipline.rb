require "zip_kit"
require "zipline/version"
require "zipline/zip_handler"
require "zipline/retrievers"

# class MyController < ApplicationController
#   include Zipline
#   def index
#     users = User.all
#     files = users.map{ |user| [user.avatar, "#{user.username}.png", modification_time: 1.day.ago] }
#     zipline(files, 'avatars.zip')
#   end
# end
module Zipline
  def self.included(into_controller)
    into_controller.include(ZipKit::RailsStreaming)
    super
  end

  def zipline(files, zipname = "zipline.zip", **kwargs_for_zip_kit_stream)
    zip_kit_stream(filename: zipname, **kwargs_for_zip_kit_stream) do |zip_kit_streamer|
      handler = Zipline::ZipHandler.new(zip_kit_streamer, logger)
      files.each do |file, name, options = {}|
        handler.handle_file(file, name.to_s, options)
      end
    end
  end
end
