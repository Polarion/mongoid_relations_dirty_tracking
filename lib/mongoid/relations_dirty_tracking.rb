require 'mongoid'
require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

module Mongoid
  module RelationsDirtyTracking
    extend ActiveSupport::Concern

    included do
      after_initialize  :store_relations_shadow
      after_save        :store_relations_shadow

      alias_method_chain :changes, :relations
      alias_method_chain :changed?, :relations
    end

    def store_relations_shadow
      @relations_shadow = {}
      relations.keys.each do |rel_name|
        @relations_shadow[rel_name] = tracked_relation_attributes(rel_name) if track_relation?(rel_name)
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

    def track_relation?(rel_name)
      [Mongoid::Relations::Embedded::One, Mongoid::Relations::Embedded::Many,
      Mongoid::Relations::Referenced::One, Mongoid::Relations::Referenced::Many,
      Mongoid::Relations::Referenced::In].include? relations[rel_name].try(:relation)
    end

    def tracked_relation_attributes(rel_name)
      rel_name = rel_name.to_s
      values = nil
      if meta = relations[rel_name]
        values = if meta.relation == Mongoid::Relations::Embedded::One
          send(rel_name) && send(rel_name).attributes.clone
        elsif meta.relation == Mongoid::Relations::Embedded::Many
          send(rel_name) && send(rel_name).map {|child| child.attributes.clone }
        elsif meta.relation == Mongoid::Relations::Referenced::One
          send(rel_name) && { "#{meta.key}" => send(rel_name)[meta.key] }
        elsif meta.relation == Mongoid::Relations::Referenced::Many
          send("#{rel_name.singularize}_ids").map {|id| { "#{meta.key}" => id } }
        elsif meta.relation == Mongoid::Relations::Referenced::In
          send(meta.foreign_key) && { "#{meta.foreign_key}" => send(meta.foreign_key)}
        end
      end
      values
    end
  end
end
