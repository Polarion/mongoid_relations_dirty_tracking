module Mongoid
  module RelationsDirtyTracking
    module Versioning
      extend ActiveSupport::Concern

      included do
        alias_method_chain :revise, :relations
        alias_method_chain :versioned_changes, :relations
        alias_method_chain :revisable?, :relations
      end


      def revise_with_relations
        previous = previous_revision
        if previous && (versioned_attributes_changed? || relations_changed?)
          new_version = versions.build

          new_version.assign_attributes(previous.versioned_attributes, without_protection: true) if versioned_attributes_changed?
          new_version._id = nil
          new_version.version = version || 1

          self.class.tracked_relations.each do |rel_name|
            new_version[rel_name.to_sym] = preserve_versioned_relation(reflect_on_association(rel_name), previous[rel_name.to_sym])
          end

          if version_max.present? && versions.length > version_max
            deleted = versions.first
            if deleted.paranoid?
              versions.delete_one(deleted)
              collection.find(atomic_selector).
                update({ "$pull" => { "versions" => { "version" => deleted.version }}})
            else
              versions.delete(deleted)
            end
          end
          self.version = (version || 1) + 1
        end
      end

      def revisable_with_relations?
        (versioned_attributes_changed? || relations_changed?) && !versionless?
      end

      def versioned_changes_with_relations
        only_versioned_attributes(changes_without_relations.except("updated_at"))
      end

      def preserve_versioned_relation(rel_meta, value)
        value
      end
    end
  end
end
