require 'spec_helper'
require 'ostruct'

describe Zipline do
  before { Fog.mock! }

  let (:undertest) {
    class TestZipline

      attr_accessor :headers
      attr_accessor :response
      attr_accessor :response_body
      def initialize 
        @headers = {}
        @response = OpenStruct.new(:cache_control => {}, :headers => {} )
      end
      include Zipline
    end 
    return TestZipline.new()
  }


  it 'passes arguments along' do
    expect(Zipline::ZipGenerator).to receive(:new)
          .with(['some', 'fake', 'files'], { some: 'options' })
    undertest.zipline(['some', 'fake', 'files'], 'myfiles.zip', some: 'options')
    expect(undertest.headers['Content-Disposition']).to eq("attachment; filename=\"myfiles.zip\"; filename*=UTF-8''myfiles.zip")
  end
end
