# Zipline
[![Build Status](https://travis-ci.org/fringd/zipline.svg?branch=master)](https://travis-ci.org/fringd/zipline)
[![Gem Version](https://badge.fury.io/rb/zipline.svg)](https://badge.fury.io/rb/zipline)

A gem to stream dynamically generated zip files from a rails application. Unlike other solutions that generate zips for user download, zipline does not wait for the entire zip file to be created (or even for the entire input file in the cloud to be downloaded) before it begins sending the zip file to the user. It does this by never seeking backwards during zip creation, and streaming the zip file over http as it is constructed. The advantages of this are:

- Removes need for large disk space or memory allocation to generate zips, even huge zips. So it works on Heroku.
- The user begins downloading immediately, which decreaceses latency, download time, and timeouts on Heroku.

Zipline now depends on [zip tricks](https://github.com/WeTransfer/zip_tricks), and you might want to just use that directly if you have more advanced use cases.

## Installation

Add this line to your application's Gemfile:

    gem 'zipline'

And then execute:

    $ bundle

## Usage

Set up some models with [ActiveStorage](http://edgeguides.rubyonrails.org/active_storage_overview.html)
[carrierwave](https://github.com/jnicklas/carrierwave), [paperclip](https://github.com/thoughtbot/paperclip), or
[shrine](https://github.com/janko-m/shrine). Right now only plain file storage and S3 are supported in the case of
[carrierwave](https://github.com/jnicklas/carrierwave) and only plain file storage and S3 are supported in the case of
[paperclip](https://github.com/thoughtbot/paperclip). [Mutiple file storages](http://shrinerb.com/#external) are
supported with [shrine](https://github.com/janko-m/shrine).

You'll need to be using puma or some other server that supports streaming output.

```Ruby
class MyController < ApplicationController
  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  include Zipline

  def index
    users = User.all
    # you can replace user.avatar with any stream or any object that
    # responds to :url.
    # :modification_time is an optional third argument you can use.
    files =  users.map{ |user| [user.avatar, "#{user.username}.png", modification_time: 1.day.ago] }
    zipline(files, 'avatars.zip')
  end
end
```

For directories, just give the files names like "directory/file".

To stream files from a remote URL, use open-uri with a [lazy enumerator](http://ruby-doc.org/core-2.0.0/Enumerator/Lazy.html):

```Ruby
require 'open-uri'
avatars = [
  # remote_url                          zip_path
  [ 'http://www.example.com/user1.png', 'avatars/user1.png', modification_time: Time.now.utc ]
  [ 'http://www.example.com/user2.png', 'avatars/user2.png', modification_time: 1.day.ago ]
  [ 'http://www.example.com/user3.png', 'avatars/user3.png' ]
]
file_mappings = avatars
  .lazy  # Lazy allows us to begin sending the download immediately instead of waiting to download everything
  .map { |url, path, options| [open(url), path, options] }
zipline(file_mappings, 'avatars.zip')
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO (possible contributions?)

* Add support for your favorite attachment plugin.
* Tests.
