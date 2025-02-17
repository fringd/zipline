# -*- encoding: utf-8 -*-
require File.expand_path('../lib/zipline/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ram Dobson"]
  gem.email         = ["ram.dobson@solsystemscompany.com"]
  gem.description   = %q{a module for streaming dynamically generated zip files}
  gem.summary       = %q{stream zip files from rails}
  gem.homepage      = "http://github.com/fringd/zipline"

  gem.files         = `git ls-files`.split($\) - %w{.gitignore}
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "zipline"
  gem.require_paths = ["lib"]
  gem.version       = Zipline::VERSION
  gem.licenses      = ['MIT']

  gem.required_ruby_version = ">= 2.7"

  gem.add_dependency 'actionpack', ['>= 6.0', '< 8.1']
  gem.add_dependency 'content_disposition', '~> 1.0'
  gem.add_dependency 'zip_kit', ['~> 6', '>= 6.2.0', '< 7']

  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'fog-aws'
  gem.add_development_dependency 'aws-sdk-s3'
  gem.add_development_dependency 'carrierwave'
  gem.add_development_dependency 'paperclip'
  gem.add_development_dependency 'rake'

  # https://github.com/rspec/rspec-mocks/issues/1457
  gem.add_development_dependency 'rspec-mocks', '~> 3.12'
end
