# frozen_string_literal: true

module Dbwatcher
  module Services
    module Analyzers
      # Abstract base class for all analyzers
      #
      # This class provides a standard interface that all analyzers must implement
      # to ensure consistent data flow and transformation to DiagramDataset format.
      #
      # @example
      #   class CustomAnalyzer < BaseAnalyzer
      #     def analyze(context)
      #       # Perform analysis and return raw data
      #     end
      #
      #     def transform_to_dataset(raw_data)
      #       # Transform raw data to DiagramDataset
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

        # Transform raw data to standard DiagramDataset
        #
        # @param raw_data [Object] raw data from analyze method
        # @return [DiagramData::DiagramDataset] standardized dataset
        # @raise [NotImplementedError] if not implemented by subclass
        def transform_to_dataset(raw_data)
          raise NotImplementedError, "Subclasses must implement transform_to_dataset"
        end

        # Analyzer capabilities declaration
        #
        # @return [Array<Symbol>] array of capabilities this analyzer provides
        def capabilities
          []
        end

        # Main entry point - analyze and transform
        #
        # @return [DiagramData::DiagramDataset] standardized dataset
        def call
          log_service_start "Starting #{self.class.name}", analysis_context
          start_time = Time.current

          begin
            # Perform analysis
            raw_data = analyze(analysis_context)

            # Transform to standard format
            dataset = transform_to_dataset(raw_data)

            # Validate result
            unless dataset.is_a?(Dbwatcher::Services::DiagramData::DiagramDataset)
              raise StandardError, "transform_to_dataset must return a DiagramDataset instance"
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

        # Check if analyzer can handle given context
        #
        # @param context [Hash] analysis context
        # @return [Boolean] true if analyzer can handle context
        def can_handle?(context)
          # Default implementation - subclasses should override
          true
        end

        # Get analyzer metadata
        #
        # @return [Hash] analyzer metadata
        def metadata
          {
            name: analyzer_name,
            description: analyzer_description,
            capabilities: capabilities,
            supported_contexts: supported_contexts
          }
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
        # @return [DiagramData::DiagramDataset] empty dataset
        def create_empty_dataset
          Dbwatcher::Services::DiagramData::DiagramDataset.new(
            metadata: {
              analyzer: self.class.name,
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
        # @param metadata [Hash] entity metadata
        # @return [DiagramData::BaseEntity] new entity
        def create_entity(id:, name:, type: "default", metadata: {})
          Dbwatcher::Services::DiagramData::BaseEntity.new(
            id: id,
            name: name,
            type: type,
            metadata: metadata
          )
        end

        # Helper method to create relationships
        #
        # @param source_id [String] source entity ID
        # @param target_id [String] target entity ID
        # @param type [String] relationship type
        # @param label [String] relationship label
        # @param metadata [Hash] relationship metadata
        # @return [DiagramData::Relationship] new relationship
        def create_relationship(source_id:, target_id:, type:, label: nil, metadata: {})
          Dbwatcher::Services::DiagramData::Relationship.new(
            source_id: source_id,
            target_id: target_id,
            type: type,
            label: label,
            metadata: metadata
          )
        end

        # Apply data transformers to raw data
        #
        # @param raw_data [Object] raw data to transform
        # @param transformers [Array<Proc>] array of transformer functions
        # @return [Object] transformed data
        def apply_transformers(raw_data, transformers = [])
          transformers.reduce(raw_data) do |data, transformer|
            transformer.call(data)
          end
        end

        private

        # Abstract methods that subclasses must implement

        # Get analyzer name
        #
        # @return [String] human-readable analyzer name
        # @raise [NotImplementedError] if not implemented by subclass
        def analyzer_name
          raise NotImplementedError, "Subclasses must implement analyzer_name"
        end

        # Get analyzer description
        #
        # @return [String] analyzer description
        # @raise [NotImplementedError] if not implemented by subclass
        def analyzer_description
          raise NotImplementedError, "Subclasses must implement analyzer_description"
        end

        # Get supported context types
        #
        # @return [Array<Symbol>] supported context types
        def supported_contexts
          %i[session global]
        end
      end
    end
  end
end
