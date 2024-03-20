require "spec_helper"
require "action_controller"

describe Zipline do
  before do
    Fog.mock!
    FakeController.logger = nil
  end

  class FakeController < ActionController::Base
    include Zipline
    def download_zip
      files = [
        [StringIO.new("File content goes here"), "one.txt"],
        [StringIO.new("Some other content goes here"), "two.txt"]
      ]
      zipline(files, "myfiles.zip", auto_rename_duplicate_filenames: false)
    end

    class FailingIO < StringIO
      def read(*)
        raise "Something wonky"
      end
    end

    def download_zip_with_error_during_streaming
      files = [
        [StringIO.new("File content goes here"), "one.txt"],
        [FailingIO.new("This will fail half-way"), "two.txt"]
      ]
      zipline(files, "myfiles.zip", auto_rename_duplicate_filenames: false)
    end
  end

  it "passes keyword parameters to ZipKit::OutputEnumerator" do
    fake_rack_env = {
      "HTTP_VERSION" => "HTTP/1.0",
      "REQUEST_METHOD" => "GET",
      "SCRIPT_NAME" => "",
      "PATH_INFO" => "/download",
      "QUERY_STRING" => "",
      "SERVER_NAME" => "host.example",
      "rack.input" => StringIO.new
    }
    expect(ZipKit::OutputEnumerator).to receive(:new).with(auto_rename_duplicate_filenames: false).and_call_original

    status, headers, body = FakeController.action(:download_zip).call(fake_rack_env)

    expect(status).to eq(200)
    expect(headers["Content-Disposition"]).to eq("attachment; filename=\"myfiles.zip\"; filename*=UTF-8''myfiles.zip")
    expect {
      body.each {}
    }.not_to raise_error
  end

  it "sends the exception raised in the streaming body to the Rails logger" do
    fake_rack_env = {
      "HTTP_VERSION" => "HTTP/1.0",
      "REQUEST_METHOD" => "GET",
      "SCRIPT_NAME" => "",
      "PATH_INFO" => "/download",
      "QUERY_STRING" => "",
      "SERVER_NAME" => "host.example",
      "rack.input" => StringIO.new
    }
    fake_logger = double
    allow(fake_logger).to receive(:warn)
    expect(fake_logger).to receive(:error).with(a_string_matching(/when serving the ZIP/))

    FakeController.logger = fake_logger

    expect {
      _status, _headers, body = FakeController.action(:download_zip_with_error_during_streaming).call(fake_rack_env)
      body.each {}
    }.to raise_error(/Something wonky/)
  end
end
