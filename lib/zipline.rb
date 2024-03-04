require 'content_disposition'
require 'zip_kit'
require 'zipline/version'
require 'zipline/zip_generator'

# class MyController < ApplicationController
#   include Zipline
#   def index
#     users = User.all
#     files = users.map{ |user| [user.avatar, "#{user.username}.png", modification_time: 1.day.ago] }
#     zipline(files, 'avatars.zip')
#   end
# end
module Zipline
  def zipline(files, zipname = 'zipline.zip', **kwargs_for_new)
    headers['Content-Disposition'] = ContentDisposition.format(disposition: 'attachment', filename: zipname)
    headers['Content-Type'] = Mime::Type.lookup_by_extension('zip').to_s
    response.sending_file = true
    response.cache_control[:public] ||= false

    # Disables Rack::ETag if it is enabled (prevent buffering)
    # see https://github.com/rack/rack/issues/1619#issuecomment-606315714
    self.response.headers['Last-Modified'] = Time.now.httpdate
    if request.get_header("HTTP_VERSION") == "HTTP/1.0"
      # If HTTP/1.0 is used it is not possible to stream, and if that happens it usually will be
      # unclear why buffering is happening. Some info in the log is the least one can do.
      logger.warn { "The downstream HTTP proxy/LB insists on HTTP/1.0 protocol, ZIP response will be buffered." } if logger
    end

    zip_generator = ZipGenerator.new(request.env, files, **kwargs_for_new)
    response.headers.merge!(zip_generator.headers)
    self.response_body = zip_generator
  end
end
