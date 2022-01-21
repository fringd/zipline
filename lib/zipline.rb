require "zipline/version"
require 'zip_tricks'
require "zipline/zip_generator"
require 'uri'

# class MyController < ApplicationController
#   include Zipline
#   def index
#     users = User.all
#     files = users.map{ |user| [user.avatar, "#{user.username}.png", modification_time: 1.day.ago] }
#     zipline(files, 'avatars.zip')
#   end
# end
module Zipline
  def zipline(files, zipname = 'zipline.zip')
    zip_generator = ZipGenerator.new(files)
    headers['Content-Disposition'] = "attachment; filename=\"#{zipname.gsub '"', '\"'}\"; filename*=UTF-8''#{URI.encode_www_form_component(zipname)}"
    headers['Content-Type'] = Mime::Type.lookup_by_extension('zip').to_s
    response.sending_file = true
    response.cache_control[:public] ||= false
    self.response_body = zip_generator
    self.response.headers['Last-Modified'] = Time.now.httpdate
  end
end
