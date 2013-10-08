require 'rubygems'
require 'bundler/setup'
require 'mongoid'
require 'mongoid/relations_dirty_tracking'

require 'rspec'

class TestDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_one  :one_document,    class_name: 'TestEmbeddedDocument'
  embeds_many :many_documents,  class_name: 'TestEmbeddedDocument'

  has_one     :one_related,     class_name: 'TestRelatedDocument'
  has_many    :many_related,    class_name: 'TestRelatedDocument'
end

class TestEmbeddedDocument
  include Mongoid::Document

  embedded_in :test_document

  field :title, type: String
end

class TestRelatedDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  belongs_to :test_document, inverse_of: :one_related

  field :title, type: String
end

class TestDocumentWithOnlyOption
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :many_documents,  class_name: 'TestEmbeddedDocument'
  has_one     :one_related,     class_name: 'TestRelatedDocument'

  relations_dirty_tracking only: :many_documents
end

class TestDocumentWithExceptOption
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :many_documents,  class_name: 'TestEmbeddedDocument'
  has_one     :one_related,     class_name: 'TestRelatedDocument'

  relations_dirty_tracking except: :many_documents
end


Mongoid.configure do |config|
  config.connect_to('mongoid_relations_dirty_tracking_test')
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:each) { Mongoid.purge! }
end
