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
        if send(name) != shadow_content
          changes[name] = [shadow_content, send(name)]
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
          @embedded_shadow[name] = send(name)
        elsif options[:relation] == Mongoid::Relations::Embedded::Many
          @embedded_shadow[name] = send(name) && send(name).clone
        end
      end
    end
  end
end
