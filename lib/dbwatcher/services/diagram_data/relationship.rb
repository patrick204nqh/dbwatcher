# frozen_string_literal: true

require_relative "base"
require_relative "relationship_params"

module Dbwatcher
  module Services
    module DiagramData
      # Standard relationship between entities
      #
      # This class provides a standardized representation for all diagram relationships
      # (edges, connections, associations, foreign keys, etc.) with consistent validation.
      #
      # @example
      #   relationship = Relationship.new(
      #     source_id: "users",
      #     target_id: "orders",
      #     type: "has_many",
      #     label: "orders",
      #     cardinality: "one_to_many",
      #     metadata: { association_type: "has_many" }
      #   )
      #   relationship.valid? # => true
      #   relationship.to_h   # => { source_id: "users", target_id: "orders", ... }
      class Relationship < Base
        attr_accessor :source_id, :target_id, :type, :label, :cardinality, :metadata

        # Valid cardinality types
        VALID_CARDINALITIES = [
          "one_to_one",
          "one_to_many",
          "many_to_one",
          "many_to_many",
          nil
        ].freeze

        # Cardinality mapping for relationship types
        CARDINALITY_MAPPING = {
          "has_many" => "one_to_many",
          "belongs_to" => "many_to_one",
          "has_one" => "one_to_one",
          "has_and_belongs_to_many" => "many_to_many"
        }.freeze

        # ERD cardinality notations
        ERD_NOTATIONS = {
          "one_to_many" => "||--o{",
          "many_to_one" => "}o--||",
          "one_to_one" => "||--||",
          "many_to_many" => "}|--|{"
        }.freeze

        # Default ERD notation
        DEFAULT_ERD_NOTATION = "||--o{" # Default to one-to-many

        # Initialize relationship
        #
        # @param params [RelationshipParams, Hash] relationship parameters
        # @return [Relationship] new relationship instance
        def initialize(params)
          super() # Initialize parent class
          params = RelationshipParams.new(params) if params.is_a?(Hash)

          @source_id = params.source_id.to_s
          @target_id = params.target_id.to_s
          @type = params.type.to_s
          @label = params.label&.to_s
          @cardinality = params.cardinality&.to_s
          @metadata = params.metadata.is_a?(Hash) ? params.metadata : {}
        end

        # Check if relationship is valid
        #
        # @return [Boolean] true if relationship has required fields
        def valid?
          validation_errors.empty?
        end

        # Get validation errors
        #
        # @return [Array<String>] array of validation error messages
        def validation_errors
          errors = []
          errors << "Source ID cannot be blank" if source_id.nil? || source_id.to_s.strip.empty?
          errors << "Target ID cannot be blank" if target_id.nil? || target_id.to_s.strip.empty?
          errors << "Type cannot be blank" if type.nil? || type.to_s.strip.empty?

          # Allow self-referential relationships when explicitly marked as such
          errors << "Source and target cannot be the same" if !metadata[:self_referential] && (source_id == target_id)

          errors << "Invalid cardinality: #{cardinality}" if cardinality && !VALID_CARDINALITIES.include?(cardinality)
          errors << "Metadata must be a Hash" unless metadata.is_a?(Hash)
          errors
        end

        # Infer cardinality from relationship type if not explicitly set
        #
        # @return [String, nil] inferred cardinality or nil if can't be determined
        def infer_cardinality
          return cardinality if cardinality

          CARDINALITY_MAPPING[type]
        end

        # Get cardinality for ERD notation
        #
        # @return [String] ERD cardinality notation
        def erd_cardinality_notation
          # Default to one-to-many if not recognized
          ERD_NOTATIONS[infer_cardinality] || DEFAULT_ERD_NOTATION
        end

        # Override base class method to handle simple hash initialization
        def self.extract_constructor_args(hash)
          hash
        end

        # Implementation for Base class
        def comparable_attributes
          [source_id, target_id, type, label, cardinality, metadata]
        end

        # Implementation for Base class
        def serializable_attributes
          {
            source_id: source_id,
            target_id: target_id,
            type: type,
            label: label,
            cardinality: cardinality,
            metadata: metadata
          }
        end
      end
    end
  end
end
