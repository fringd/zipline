require "zipline/version"
require 'curb'
require 'zip_tricks'
require "zipline/zip_generator"

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
    headers['Content-Disposition'] = "attachment; filename=\"#{zipname.gsub '"', '\"'}\""
    headers['Content-Type'] = Mime::Type.lookup_by_extension('zip').to_s
    response.sending_file = true
    response.cache_control[:public] ||= false
    self.response_body = zip_generator
    self.response.headers['Last-Modified'] = Time.now.httpdate
  end
end
