# Zipline

A gem to stream dynamically generated zip files from a rails application

## Installation

Add this line to your application's Gemfile:

    gem 'zipline'

And then execute:

    $ bundle

## Usage

set up some models with [carrierwave](https://github.com/jnicklas/carrierwave) or [paperclip](https://github.com/thoughtbot/paperclip).
 Right now only plain file storage and S3 are supported

You'll need to be using [unicorn](http://unicorn.bogomips.org/) or rainbows or some other server that supports streaming output.

    class MyController < ApplicationController
      # enable streaming responses
      include ActionController::Streaming
      # enable zipline
      include Zipline
      
      def index
        users= User.all
        files =  users.map{ |user| [user.avatar, "#{user.username}.png"] }
        zipline( files, 'avatars.zip')
      end
    end
    
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO (possible contributions?)

* support plain File objects, although... you should be just using rubyzip directly maybe.
* tests!
* support rails 4.0 streaming
* extract library for plain ruby streaming zips, which this will depend on.
