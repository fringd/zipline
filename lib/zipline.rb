require 'content_disposition'
require "zipline/version"
require 'zip_tricks'
require "zipline/zip_generator"
require "zipline/chunked_body"
require "zipline/tempfile_body"

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
    zip_generator = ZipGenerator.new(files, **kwargs_for_new)
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

      # If we use Rack::ContentLength it would run through our ZIP block twice - once to calculate the content length
      # of the response, and once - to serve. We can trade performance for disk space and buffer the response into a Tempfile
      # since we are already buffering.
      tempfile_body = Zipline::TempfileBody.new(request.env, zip_generator)
      headers["Content-Length"] = tempfile_body.size.to_s
      headers["X-Zipline-Output"] = "buffered"
      self.response_body = tempfile_body
    else
      # Disable buffering for both nginx and Google Load Balancer, see
      # https://cloud.google.com/appengine/docs/flexible/how-requests-are-handled?tab=python#x-accel-buffering
      response.headers["X-Accel-Buffering"] = "no"

      # Make sure Rack::ContentLength does not try to compute a content length,
      # and remove the one already set
      headers.delete("Content-Length")

      # and send out in chunked encoding
      headers["Transfer-Encoding"] = "chunked"
      headers["X-Zipline-Output"] = "streamed"
      self.response_body = Zipline::Chunked.new(zip_generator)
    end
  end
end
