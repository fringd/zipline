# Zipline
[![Tests](https://github.com/fringd/zipline/actions/workflows/ci.yml/badge.svg)](https://github.com/fringd/zipline/actions/workflows/ci.yml)
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
  # enable zipline
  include Zipline

  def index
    users = User.all
    # you can replace user.avatar with any stream or any object that
    # responds to :url, :path or :file.
    # :modification_time is an optional third argument you can use.
    files = users.map{ |user| [user.avatar, "#{user.username}.png", modification_time: 1.day.ago] }

    # we can force duplicate file names to be renamed, or raise an error
    # we can also pass in our own writer if required to conform with the Delegated [ZipTricks::Streamer object](https://github.com/WeTransfer/zip_tricks/blob/main/lib/zip_tricks/streamer.rb#L147) object.
    zipline(files, 'avatars.zip', auto_rename_duplicate_filenames: true) 
  end
end
```

### ActiveStorage

```Ruby
users = User.all
files = users.map{ |user| [user.avatar, user.avatar.filename] }
zipline(files, 'avatars.zip')
```

### Carrierwave

```Ruby
users = User.all
files = users.map{ |user| [user.avatar, user.avatar_identifier] }
zipline(files, 'avatars.zip')
```

### Paperclip ([deprecated](https://thoughtbot.com/blog/closing-the-trombone))

```Ruby
users = User.all
files = users.map{ |user| [user.avatar, user.avatar_file_name] }
zipline(files, 'avatars.zip')
```

### Url

If you know the URL of the remote file you want to include, you can just pass in the
URL directly in place of the attachment object.
```Ruby
avatars = [
  ['http://www.example.com/user1.png', 'user1.png']
  ['http://www.example.com/user2.png', 'user2.png']
  ['http://www.example.com/user3.png', 'user3.png']
]
zipline(avatars, 'avatars.zip')
```

### Directories

For directories, just give the files names like "directory/file".


```Ruby
avatars = [
  # remote_url                          zip_path             zip_tricks_options
  [ 'http://www.example.com/user1.png', 'avatars/user1.png', modification_time: Time.now.utc ]
  [ 'http://www.example.com/user2.png', 'avatars/user2.png', modification_time: 1.day.ago ]
  [ 'http://www.example.com/user3.png', 'avatars/user3.png' ]
]

zipline(avatars, 'avatars.zip')
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
