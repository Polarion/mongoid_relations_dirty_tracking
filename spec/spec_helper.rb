require 'rubygems'
require 'bundler/setup'
require 'mongoid'
require 'mongoid/track_embedded_changes'

require 'rspec'

class TestDocument
  include Mongoid::Document
  include Mongoid::TrackEmbeddedChanges

  embeds_one  :one_document,    class_name: 'TestDocument'
  embeds_many :many_documents,  class_name: 'TestDocument'
end

class TestEmbeddedDocument
  include Mongoid::Document

  embedded_in :test_document

  field :title, type: String
end


Mongoid.configure do |config|
  config.connect_to('mongoid_track_embedded_changes_test')
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:each) { Mongoid.purge! }
end
