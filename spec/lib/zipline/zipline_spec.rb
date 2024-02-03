require 'spec_helper'
require 'action_controller'

describe Zipline do
  before { Fog.mock! }

  class FakeController < ActionController::Base
    include Zipline
    def download_zip
      files = [
        [StringIO.new("File content goes here"), "one.txt"],
        [StringIO.new("Some other content goes here"), "two.txt"]
      ]
      zipline(files, 'myfiles.zip', auto_rename_duplicate_filenames: false)
    end
  end

  it 'passes keyword parameters to ZipTricks::Streamer' do
    fake_rack_env = {
      "HTTP_VERSION" => "HTTP/1.0",
      "REQUEST_METHOD" => "GET",
      "SCRIPT_NAME" => "",
      "PATH_INFO" => "/download",
      "QUERY_STRING" => "",
      "SERVER_NAME" => "host.example",
      "rack.input" => StringIO.new,
    }
    expect(ZipTricks::Streamer).to receive(:new).with(anything, auto_rename_duplicate_filenames: false).and_call_original

    status, headers, body = FakeController.action(:download_zip).call(fake_rack_env)

    expect(headers['Content-Disposition']).to eq("attachment; filename=\"myfiles.zip\"; filename*=UTF-8''myfiles.zip")
  end
end
