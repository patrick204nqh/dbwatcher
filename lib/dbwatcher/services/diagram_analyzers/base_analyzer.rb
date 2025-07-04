# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Abstract base class for diagram analyzers
      #
      # This class provides a standard interface that all diagram analyzers must implement
      # to ensure consistent data flow and transformation to Dataset format.
      #
      # @example
      #   class CustomAnalyzer < BaseAnalyzer
      #     def analyze(context)
      #       # Perform analysis and return raw data
      #     end
      #
      #     def transform_to_dataset(raw_data)
      #       # Transform raw data to Dataset
      #     end
      #
      #     def analyzer_type
      #       "custom"
      #     end
      #   end
      class BaseAnalyzer < BaseService
        # Standard interface that all analyzers must implement
        #
        # @param context [Hash] analysis context (session, options, etc.)
        # @return [Object] raw analysis data in analyzer-specific format
        # @raise [NotImplementedError] if not implemented by subclass
        def analyze(context)
          raise NotImplementedError, "Subclasses must implement analyze method"
        end

        # Transform raw data to standard Dataset
        #
        # @param raw_data [Object] raw data from analyze method
        # @return [DiagramData::Dataset] standardized dataset
        # @raise [NotImplementedError] if not implemented by subclass
        def transform_to_dataset(raw_data)
          raise NotImplementedError, "Subclasses must implement transform_to_dataset"
        end

        # Get analyzer type classification
        #
        # @return [String] analyzer type identifier
        # @raise [NotImplementedError] if not implemented by subclass
        def analyzer_type
          raise NotImplementedError, "Subclasses must implement analyzer_type"
        end

        # Main entry point - analyze and transform
        #
        # @return [DiagramData::Dataset] standardized dataset
        def call
          log_service_start "Starting #{self.class.name}", analysis_context
          start_time = Time.current

          begin
            # Perform analysis
            raw_data = analyze(analysis_context)

            # Transform to standard format
            dataset = transform_to_dataset(raw_data)

            # Validate result
            unless dataset.is_a?(Dbwatcher::Services::DiagramData::Dataset)
              raise StandardError, "transform_to_dataset must return a Dataset instance"
            end

            unless dataset.valid?
              Rails.logger.warn "#{self.class.name}: Generated invalid dataset: #{dataset.validation_errors.join(", ")}"
            end

            log_service_completion(start_time, {
                                     entities_count: dataset.entities.size,
                                     relationships_count: dataset.relationships.size,
                                     dataset_valid: dataset.valid?
                                   })

            dataset
          rescue StandardError => e
            Rails.logger.error "#{self.class.name} error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
            # Return empty dataset instead of failing
            create_empty_dataset
          end
        end

        protected

        # Build analysis context for this analyzer
        #
        # @return [Hash] analysis context
        def analysis_context
          # Override in subclasses to provide specific context
          {}
        end

        # Create empty dataset with metadata
        #
        # @return [DiagramData::Dataset] empty dataset
        def create_empty_dataset
          Dbwatcher::Services::DiagramData::Dataset.new(
            metadata: {
              analyzer: self.class.name,
              analyzer_type: analyzer_type,
              empty_reason: "No data found or analysis failed",
              generated_at: Time.current.iso8601
            }
          )
        end

        # Helper method to create entities
        #
        # @param id [String] entity ID
        # @param name [String] entity name
        # @param type [String] entity type
        # @param attributes [Array<Attribute>] entity attributes/properties
        # @param metadata [Hash] entity metadata
        # @return [DiagramData::Entity] new entity
        def create_entity(id:, name:, type: "default", attributes: [], metadata: {})
          Dbwatcher::Services::DiagramData::Entity.new(
            id: id,
            name: name,
            type: type,
            attributes: attributes,
            metadata: metadata
          )
        end

        # Helper method to create relationships
        #
        # @param source_id [String] source entity ID
        # @param target_id [String] target entity ID
        # @param type [String] relationship type
        # @param options [Hash] additional options including label, cardinality, and metadata
        # @return [DiagramData::Relationship] new relationship
        def create_relationship(source_id:, target_id:, type:, **options)
          Dbwatcher::Services::DiagramData::Relationship.new(
            source_id: source_id,
            target_id: target_id,
            type: type,
            **options
          )
        end

        # Helper method to create attributes
        #
        # @param name [String] attribute name
        # @param type [String] attribute data type
        # @param nullable [Boolean] whether attribute can be null
        # @param default [Object] default value
        # @param metadata [Hash] additional type-specific information
        # @return [DiagramData::Attribute] new attribute
        def create_attribute(name:, type: nil, nullable: true, default: nil, metadata: {})
          Dbwatcher::Services::DiagramData::Attribute.new(
            name: name,
            type: type,
            nullable: nullable,
            default: default,
            metadata: metadata
          )
        end
      end
    end
  end
end
