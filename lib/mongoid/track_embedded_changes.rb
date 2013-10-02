require 'mongoid'
require 'active_support/concern'

module Mongoid
  module TrackEmbeddedChanges
    extend ActiveSupport::Concern

    included do
      after_initialize  :store_embedded_shadow
      after_save        :store_embedded_shadow
    end

    def embedded_changes
      changes = {}
      @embedded_shadow.each_pair do |name, shadow_content|
        embedded_attributes = send(name)
        embedded_attributes &&= send(name).is_a?(Array) ? send(name).map(&:attributes) : send(name).attributes
        if embedded_attributes != shadow_content
          changes[name] = [shadow_content, embedded_attributes]
        end
      end
      changes
    end

    def embedded_changed?
      !embedded_changes.empty?
    end

    def changed_with_embedded?
      changed? or embedded_changed?
    end

    def changes_with_embedded
      (changes || {}).merge embedded_changes
    end

    def store_embedded_shadow
      @embedded_shadow = {}
      relations.each_pair do |name, options|
        if options[:relation] == Mongoid::Relations::Embedded::One
          @embedded_shadow[name] = send(name) && send(name).attributes.clone
        elsif options[:relation] == Mongoid::Relations::Embedded::Many
          @embedded_shadow[name] = send(name) && send(name).map {|child| child.attributes.clone }
        end
      end
    end
  end
end
