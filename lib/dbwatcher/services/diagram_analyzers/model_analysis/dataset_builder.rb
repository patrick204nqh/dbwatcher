# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      module ModelAnalysis
        # Service responsible for building datasets from model associations
        #
        # This service handles the transformation of model association data into
        # standardized Dataset format with entities and relationships.
        class DatasetBuilder
          # Create entities from discovered model classes
          #
          # @param dataset [DiagramData::Dataset] dataset to add entities to
          # @param models [Array<Class>] ActiveRecord model classes
          # @return [void]
          def create_entities_from_models(dataset, models)
            models.each do |model_class|
              attributes = extract_model_attributes(model_class)
              methods = extract_model_methods(model_class)

              entity = create_entity(
                id: model_class.table_name,
                name: model_class.name,
                type: "model",
                attributes: attributes,
                metadata: {
                  table_name: model_class.table_name,
                  model_class: model_class.name,
                  methods: methods
                }
              )
              dataset.add_entity(entity)
            end
          end

          # Create relationships from association data
          #
          # @param dataset [DiagramData::Dataset] dataset to add relationships to
          # @param raw_data [Array<Hash>] raw association data
          # @return [void]
          def create_relationships_from_associations(dataset, raw_data)
            raw_data.each do |association|
              next if association[:type] == "node_only" || !association[:target_model]

              source_id = association[:source_table]
              target_id = association[:target_table]

              # Skip if we don't have valid table IDs
              next unless source_id && target_id

              # Determine cardinality based on relationship type
              cardinality = determine_cardinality(association[:type])

              relationship = create_relationship({
                                                   source_id: source_id,
                                                   target_id: target_id,
                                                   type: association[:type],
                                                   label: association[:association_name],
                                                   cardinality: cardinality,
                                                   metadata: {
                                                     association_name: association[:association_name],
                                                     source_model: association[:source_model],
                                                     target_model: association[:target_model],
                                                     original_type: association[:type],
                                                     self_referential: source_id == target_id
                                                   }
                                                 })

              dataset.add_relationship(relationship)
            end
          end

          # Build complete dataset from associations and models
          #
          # @param raw_associations [Array<Hash>] raw association data
          # @param models [Array<Class>] ActiveRecord model classes
          # @return [DiagramData::Dataset] standardized dataset
          def build_from_associations(raw_associations, models)
            dataset = create_empty_dataset
            dataset.metadata.merge!({
                                      total_relationships: raw_associations.count { |a| a[:target_model] },
                                      total_models: models.length,
                                      model_names: models.map(&:name)
                                    })

            # Create entities from actual discovered models (no inference)
            create_entities_from_models(dataset, models)

            # Create relationships from association data
            create_relationships_from_associations(dataset, raw_associations)

            dataset
          end

          private

          # Extract attributes from model class
          #
          # @param model_class [Class, nil] ActiveRecord model class
          # @return [Array<Attribute>] model attributes
          def extract_model_attributes(model_class)
            return [] unless model_class.respond_to?(:columns)

            begin
              model_class.columns.map do |column|
                create_attribute(
                  name: column.name,
                  type: column.type.to_s,
                  nullable: column.null,
                  default: column.default,
                  metadata: {
                    primary_key: column.name == model_class.primary_key,
                    foreign_key: column.name.end_with?("_id"),
                    visibility: "+" # Public visibility for all columns
                  }
                )
              end
            rescue StandardError => e
              Rails.logger.warn "DatasetBuilder: Could not extract attributes for " \
                                "#{model_class.name}: #{e.message}"
              []
            end
          end

          # Extract methods from model class
          #
          # @param model_class [Class, nil] ActiveRecord model class
          # @return [Array<Hash>] model methods
          def extract_model_methods(model_class)
            return [] unless model_class && Dbwatcher.configuration.diagram_show_methods

            methods = []

            begin
              # Get instance methods defined in the model (not inherited from ActiveRecord::Base)
              model_methods = model_class.instance_methods - ActiveRecord::Base.instance_methods
              model_methods.each do |method_name|
                # Skip association methods and attribute methods
                next if method_name.to_s.end_with?("=") || model_class.column_names.include?(method_name.to_s)

                methods << {
                  name: method_name.to_s,
                  visibility: "+" # Public visibility for all methods
                }
              end
            rescue StandardError => e
              Rails.logger.warn "DatasetBuilder: Could not extract methods for " \
                                "#{model_class.name}: #{e.message}"
            end

            methods
          end

          # Determine cardinality based on relationship type
          #
          # @param relationship_type [String] relationship type
          # @return [String, nil] cardinality type
          def determine_cardinality(relationship_type)
            case relationship_type
            when "has_many"
              "one_to_many"
            when "belongs_to"
              "many_to_one"
            when "has_one"
              "one_to_one"
            when "has_and_belongs_to_many", "has_many_through"
              "many_to_many"
            end
          end

          # Helper method to create entities (delegated to base analyzer)
          #
          # @param params [Hash] entity parameters
          # @return [DiagramData::Entity] new entity
          def create_entity(**params)
            Dbwatcher::Services::DiagramData::Entity.new(
              id: params[:id],
              name: params[:name],
              type: params[:type] || "default",
              attributes: params[:attributes] || [],
              metadata: params[:metadata] || {}
            )
          end

          # Helper method to create relationships (delegated to base analyzer)
          #
          # @param params [Hash] relationship parameters
          # @return [DiagramData::Relationship] new relationship
          def create_relationship(params)
            params_obj = Dbwatcher::Services::DiagramData::RelationshipParams.new(params)
            Dbwatcher::Services::DiagramData::Relationship.new(params_obj)
          end

          # Helper method to create attributes (delegated to base analyzer)
          #
          # @param params [Hash] attribute parameters
          # @return [DiagramData::Attribute] new attribute
          def create_attribute(**params)
            Dbwatcher::Services::DiagramData::Attribute.new(
              name: params[:name],
              type: params[:type],
              nullable: params[:nullable] || true,
              default: params[:default],
              metadata: params[:metadata] || {}
            )
          end

          # Helper method to create empty dataset (delegated to base analyzer)
          #
          # @return [DiagramData::Dataset] empty dataset
          def create_empty_dataset
            Dbwatcher::Services::DiagramData::Dataset.new(
              metadata: {
                analyzer: "ModelAssociationAnalyzer",
                analyzer_type: "model_association",
                empty_reason: "No data found or analysis failed",
                generated_at: Time.current.iso8601
              }
            )
          end
        end
      end
    end
  end
end
