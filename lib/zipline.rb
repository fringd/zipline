require "zipline/version"

require 'zip/zip'

require "zipline/fake_stream"
require "zipline/zip_output_stream"
require "zipline/zip_generator"

require "zipline/fake_stream_faker"
require "zipline/fake_string"
require "zipline/zip_size_calculator"

# class MyController < ApplicationController
#   include Zipline
#   def index
#     users= User.all
#     files =  users.map{ |user| [user.avatar, "#{user.username}.png"] }
#     zipline( files, 'avatars.zip')
#   end
# end
module Zipline
  def zipline(files, zipname = 'zipline.zip')
    zip_generator = ZipGenerator.new(files)
    headers['Content-Disposition'] = "attachment; filename=#{zipname}"
    headers['Content-Type'] = Mime::Type.lookup_by_extension('zip').to_s
    headers['Content-Length'] = zip_generator.precalculate_size.to_s
    response.sending_file = true
    response.cache_control[:public] ||= false
    self.response_body = zip_generator
    self.response.headers['Last-Modified'] = Time.now.to_s
  end
end
