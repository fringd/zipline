# Zipline

A gem to stream dynamically generated zip files from a rails application

## Installation

Add this line to your application's Gemfile:

    gem 'zipline'

And then execute:

    $ bundle

## Usage

set up some models with [carrierwave](https://github.com/jnicklas/carrierwave) Right now only plain file storage and S3 are supported

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
    
## Notes
MacOS built in archive support does not seem to work. Some other archivers don't work.
I am beginning to believe pretty strongly that this is just be a limitation of those archivers.
Other projects that stream zips seem to run into the same problem. Setting general purpose bit
3 like this and putting size and crc after the data is outlined over a decade ago in the zip standard,
so it is not a new feature. It seems that some simpler zip programs don't support it properly, though,
so If that is a deal breaker then you need to give up the dream and build the zip in memory or on disk.
If you do go with zipline, you might want to be ready with a "trouble unzipping? try installing 7zip."

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
