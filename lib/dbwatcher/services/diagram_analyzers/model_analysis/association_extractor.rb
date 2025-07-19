# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      module ModelAnalysis
        # Service responsible for analyzing ActiveRecord model associations
        #
        # This service handles the extraction and analysis of model associations,
        # converting them into standardized relationship data for diagram generation.
        class AssociationExtractor
          attr_reader :session_tables

          # Initialize with optional session tables for scope filtering
          #
          # @param session_tables [Array<String>] table names from session (empty for global analysis)
          def initialize(session_tables = [])
            @session_tables = session_tables || []
          end

          # Extract associations from all provided models
          #
          # @param models [Array<Class>] ActiveRecord model classes to analyze
          # @return [Array<Hash>] associations array
          def extract_all(models)
            associations = []

            models.each do |model|
              model_associations = get_model_associations(model)

              model_associations.each do |association|
                # Skip polymorphic associations for now
                next if association.options[:polymorphic]

                # Skip if target model is not in scope
                next unless target_model_in_scope?(association)

                # Build relationship based on association type
                relationship = build_association_relationship(model, association)
                associations << relationship if relationship
              end
            end

            associations
          end

          # Generate placeholder associations for models without associations
          #
          # @param models [Array<Class>] models to create placeholders for
          # @return [Array<Hash>] placeholder associations
          def generate_placeholder_associations(models)
            result = models.map do |model|
              {
                type: "node_only",
                source_model: model.name,
                source_table: model.table_name,
                target_model: nil,
                target_table: nil,
                association_name: nil
              }
            end

            Rails.logger.info "AssociationExtractor: Generated #{result.size} placeholder nodes"
            result
          end

          private

          # Get associations for a model
          #
          # @param model [Class] ActiveRecord model class
          # @return [Array] association objects
          def get_model_associations(model)
            model.reflect_on_all_associations
          rescue StandardError => e
            Rails.logger.warn "AssociationExtractor: Could not get associations for #{model.name}: #{e.message}"
            []
          end

          # Check if target model is in analysis scope
          #
          # @param association [Object] association object
          # @return [Boolean] true if target model should be included
          def target_model_in_scope?(association)
            target_table = get_association_table_name(association)

            # If analyzing session, both tables must be in session
            # If analyzing globally, include all
            return true if session_tables.empty?

            # Skip if target table is not in session
            return false if target_table && !session_tables.include?(target_table)

            true
          end

          # Build relationship hash based on association type
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_association_relationship(model, association)
            case association.macro
            when :belongs_to
              build_belongs_to_relationship(model, association)
            when :has_one
              build_has_one_relationship(model, association)
            when :has_many
              if association.options[:through]
                build_has_many_through_relationship(model, association)
              else
                build_has_many_relationship(model, association)
              end
            when :has_and_belongs_to_many
              build_habtm_relationship(model, association)
            else
              # Handle special cases like has_one_attached from Active Storage
              if association.name.to_s.end_with?("_attachment") || association.name.to_s.end_with?("_attachments")
                build_active_storage_relationship(model, association)
              else
                Rails.logger.warn "AssociationExtractor: Unknown association type: " \
                                  "#{association.macro} for #{model.name}.#{association.name}"
                nil
              end
            end
          end

          # Build a standardized relationship hash
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @param type [String] relationship type
          # @return [Hash] relationship data
          def build_relationship_hash(model, association, type)
            return nil unless association&.class_name

            {
              source_model: model.name,
              source_table: model.table_name,
              target_model: association.class_name,
              target_table: get_association_table_name(association),
              type: type,
              association_name: association.name.to_s
            }
          end

          # Build belongs_to relationship
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_belongs_to_relationship(model, association)
            build_relationship_hash(model, association, "belongs_to")
          end

          # Build has_one relationship
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_has_one_relationship(model, association)
            build_relationship_hash(model, association, "has_one")
          end

          # Build has_many relationship
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_has_many_relationship(model, association)
            build_relationship_hash(model, association, "has_many")
          end

          # Build has_many :through relationship
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_has_many_through_relationship(model, association)
            relationship = build_relationship_hash(model, association, "has_many_through")
            relationship[:association_name] = "#{association.name} (through #{association.options[:through]})"
            relationship
          end

          # Build has_and_belongs_to_many relationship
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_habtm_relationship(model, association)
            build_relationship_hash(model, association, "has_and_belongs_to_many")
          end

          # Build Active Storage relationship
          #
          # @param model [Class] source model class
          # @param association [Object] association object
          # @return [Hash] relationship data
          def build_active_storage_relationship(model, association)
            {
              source_model: model.name,
              source_table: model.table_name,
              target_model: "ActiveStorage::Attachment",
              target_table: "active_storage_attachments",
              type: "has_one",
              association_name: association.name.to_s
            }
          end

          # Get table name for association target
          #
          # @param association [Object] association object
          # @return [String, nil] table name
          def get_association_table_name(association)
            association.table_name
          rescue StandardError => e
            Rails.logger.warn "AssociationExtractor: Could not get table name for #{association.name}: #{e.message}"
            nil
          end
        end
      end
    end
  end
end
