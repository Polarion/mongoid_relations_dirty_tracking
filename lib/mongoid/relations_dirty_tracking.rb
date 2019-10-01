require 'mongoid'
require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'
require_relative '../alias_method_chain'

module Mongoid
  module RelationsDirtyTracking
    extend ActiveSupport::Concern
    include AliasMethodChain

    included do
      after_initialize  :store_relations_shadow
      after_save        :store_relations_shadow

      #alias_method_chain :changes, :relations
      #alias_method_chain :changed?, :relations

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
        if current_values != shadow_values
          changes[rel_name] = [shadow_values, current_values]
        end
      end
      changes
    end

    def relations_changed?
      !relation_changes.empty?
    end

    def changed_with_relations?
      changed_without_relations? or relations_changed?
    end

    def changes_with_relations
      (changes_without_relations || {}).merge relation_changes
    end

    def tracked_relation_attributes(rel_name)
      rel_name = rel_name.to_s
      meta = relations[rel_name]
      return nil unless meta

      case meta
      when Mongoid::Association::Embedded::EmbedsOne
        send(rel_name) && send(rel_name).attributes.clone.delete_if {|key, _| key == 'updated_at' }
      when Mongoid::Association::Embedded::EmbedsMany
        send(rel_name) && send(rel_name).map {|child| child.attributes.clone.delete_if {|key, _| key == 'updated_at' } }
      when Mongoid::Association::Referenced::HasOne
        send(rel_name) && { "#{meta.key}" => send(rel_name)[meta.key] }
      when Mongoid::Association::Referenced::HasMany
        send(rel_name).map {|child| { "#{meta.key}" => child.id } }
      when Mongoid::Association::Referenced::HasAndBelongsToMany
        send(rel_name).map {|child| { "#{meta.primary_key}" => child.id } }
      when Mongoid::Association::Referenced::BelongsTo
        begin
          send(meta.foreign_key) && { "#{meta.foreign_key}" => send(meta.foreign_key)}
        rescue ActiveModel::MissingAttributeError
          nil
        end
      end
    end

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
        @tracked_relations ||= relations.keys.select {|rel_name| track_relation?(rel_name) }
      end
    end
  end
end
