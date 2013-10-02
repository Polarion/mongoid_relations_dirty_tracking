# coding: utf-8
require File.expand_path('../lib/mongoid/track_embedded_changes/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "mongoid_track_embedded_changes"
  spec.version       = Mongoid::TrackEmbeddedChanges::VERSION
  spec.authors       = ["David Sevcik"]
  spec.email         = ["david.sevcik@gmail.com"]
  spec.description   = "Adds to mongoid support for tracking changes on embedded documents"
  spec.summary       = "Adds to mongoid support for tracking changes on embedded documents"
  spec.homepage      = "http://github.com/versative/mongoid_track_embedded_changes"
  spec.license       = "MIT"

  spec.add_runtime_dependency 'activesupport', '~> 3.0'
  spec.add_runtime_dependency 'mongoid', '>= 3.1.0', '< 4.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.8"
  spec.add_development_dependency "pry"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
