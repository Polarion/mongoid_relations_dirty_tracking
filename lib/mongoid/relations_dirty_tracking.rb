# frozen_string_literal: true

require 'mongoid'
require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

module Mongoid
  module RelationsDirtyTracking
    extend ActiveSupport::Concern

    module ClassMethods
      def relations_dirty_tracking(options = {})
        relations_dirty_tracking_options[:only] += [options[:only] || []].flatten.map(&:to_s)
        relations_dirty_tracking_options[:except] += [options[:except] || []].flatten.map(&:to_s)
      end

      def track_relation?(rel_name)
        rel_name = rel_name.to_s
        options = relations_dirty_tracking_options
        to_track = (!options[:only].blank? && options[:only].include?(rel_name)) \
          || (options[:only].blank? && !options[:except].include?(rel_name))

        to_track && [
          Mongoid::Association::Embedded::EmbedsOne::Proxy,
          Mongoid::Association::Embedded::EmbedsMany::Proxy,
          Mongoid::Association::Referenced::HasOne::Proxy,
          Mongoid::Association::Referenced::HasMany::Proxy,
          Mongoid::Association::Referenced::HasAndBelongsToMany::Proxy,
          Mongoid::Association::Referenced::BelongsTo::Proxy
        ].include?(relations[rel_name].try(:relation))
      end

      def tracked_relations
        @tracked_relations ||= relations.keys.select { |rel_name| track_relation?(rel_name) }
      end
    end

    included do
      after_initialize  :store_relations_shadow
      after_save        :store_relations_shadow

      cattr_accessor :relations_dirty_tracking_options
      self.relations_dirty_tracking_options = { only: [], except: ['versions'] }
    end

    def store_relations_shadow
      @relations_shadow = {}
      self.class.tracked_relations.each do |rel_name|
        @relations_shadow[rel_name] = tracked_relation_attributes(rel_name)
      end
    end

    def relation_changes
      changes = {}
      @relations_shadow.each_pair do |rel_name, shadow_values|
        current_values = tracked_relation_attributes(rel_name)
        changes[rel_name] = [shadow_values, current_values] if current_values != shadow_values
      end
      changes
    end

    def relations_changed?
      !relation_changes.empty?
    end

    def changed_with_relations?
      changed? || relations_changed?
    end

    def changes_with_relations
      (changes || {}).merge relation_changes
    end

    def tracked_relation_attributes(rel_name)
      rel_name = rel_name.to_s
      meta = relations[rel_name]
      return nil unless meta
      case meta
      when association_embeds_one
        send(rel_name) && send(rel_name).attributes.clone.delete_if { |key, _| key == 'updated_at' }
      when association_embeds_many
        send(rel_name)&.map { |child| child.attributes.clone.delete_if { |key, _| key == 'updated_at' } }
      when association_has_one
        send(rel_name) && { meta.key.to_s => send(rel_name)[meta.key] }
      when association_has_many
        send(rel_name).map { |child| { meta.key.to_s => child.id } }
      when association_habtm
        send(rel_name).map { |child| { meta.primary_key.to_s => child.id } }
      when association_belongs_to
        begin
          send(meta.foreign_key) && { meta.foreign_key.to_s => send(meta.foreign_key) }
        rescue ActiveModel::MissingAttributeError
          nil
        end
      end
    end

    def association_belongs_to
      if defined?(Mongoid::Association)
        Mongoid::Association::Referenced::BelongsTo
      else
        Mongoid::Relations::Referenced::In
      end
    end

    def association_has_one
      if defined?(Mongoid::Association)
        Mongoid::Association::Referenced::HasOne
      else
        Mongoid::Relations::Referenced::One
      end
    end

    def association_has_many
      if defined?(Mongoid::Association)
        Mongoid::Association::Referenced::HasMany
      else
        Mongoid::Relations::Referenced::Many
      end
    end

    def association_habtm
      if defined?(Mongoid::Association)
        Mongoid::Association::Referenced::HasAndBelongsToMany
      else
        Mongoid::Relations::Referenced::ManyToMany
      end
    end

    def association_embeds_one
      if defined?(Mongoid::Association)
        Mongoid::Association::Embedded::EmbedsOne
      else
        Mongoid::Relations::Embedded::One
      end
    end

    def association_embeds_many
      if defined?(Mongoid::Association)
        Mongoid::Association::Embedded::EmbedsMany
      else
        Mongoid::Relations::Embedded::Many
      end
    end
  end
end
