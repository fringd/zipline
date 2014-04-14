require 'spec_helper'
require 'tempfile'

describe Zipline::ZipGenerator do

  before { Fog.mock! }
  let(:file_attributes){ {
    key: 'fog_file_tests',
    body: 'some body',
    public: true
  }}
  let(:directory_attributes){{
    key: 'fog_directory'
  }}
  let(:storage_attributes){{
    aws_access_key_id: 'fake_access_key_id',
    aws_secret_access_key: 'fake_secret_access_key',
    provider: 'AWS'
  }}
  let(:storage){ Fog::Storage.new(storage_attributes)}
  let(:directory){ storage.directories.create(directory_attributes) }
  let(:file){ directory.files.create(file_attributes) }

  describe '.normalize' do
    let(:generator){ Zipline::ZipGenerator.new([])}
    context "CarrierWave" do
      context "Remote" do
        let(:file){ CarrierWave::Storage::Fog::File.new(nil,nil,nil) }
        it "passes through" do
          expect(File).not_to receive(:open)
          expect(generator.normalize(file)).to be file
        end
      end
      context "Local" do
        let(:file){ CarrierWave::SanitizedFile.new(Tempfile.new('t')) }
        it "creates a File" do
          expect(generator.normalize(file)).to be_a File
        end
      end
    end
    context "Paperclip" do
      let(:file){ Paperclip::Attachment.new(:name, :instance) }
      it "creates a File" do
        expect(File).to receive(:open).once
        generator.normalize(file)
      end
    end
    context "Fog" do
      it "passes through" do
        expect(File).not_to receive(:open)
        expect(generator.normalize(file)).to be file
      end
    end
    context "IOStream" do
      let(:file){ StringIO.new('passthrough')}
      it "passes through" do
        expect(generator.normalize(file)).to be file
      end
    end
    context "invalid" do
      let(:file){ Thread.new{} }
      it "raises error" do
        expect{generator.normalize(file)}.to raise_error(ArgumentError)
      end
    end
  end

end
