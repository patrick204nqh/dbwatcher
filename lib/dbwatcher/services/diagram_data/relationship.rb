# frozen_string_literal: true

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
      class Relationship
        attr_accessor :source_id, :target_id, :type, :label, :cardinality, :metadata

        # Valid cardinality types
        VALID_CARDINALITIES = [
          "one_to_one",
          "one_to_many",
          "many_to_one",
          "many_to_many",
          nil
        ].freeze

        # Initialize relationship
        #
        # @param source_id [String] ID of the source entity
        # @param target_id [String] ID of the target entity
        # @param type [String] relationship type (has_many, belongs_to, foreign_key, etc.)
        # @param options [Hash] additional options including label, cardinality, and metadata
        def initialize(source_id:, target_id:, type:, **options)
          @source_id = source_id.to_s
          @target_id = target_id.to_s
          @type = type.to_s
          @label = options[:label]&.to_s
          @cardinality = options[:cardinality]&.to_s
          @metadata = options[:metadata].is_a?(Hash) ? options[:metadata] : {}
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

          {
            "has_many" => "one_to_many",
            "belongs_to" => "many_to_one",
            "has_one" => "one_to_one",
            "has_and_belongs_to_many" => "many_to_many"
          }[type]
        end

        # Get cardinality for ERD notation
        #
        # @return [String] ERD cardinality notation
        def erd_cardinality_notation
          # Default to one-to-many if not recognized
          notation = "||--o{"

          case infer_cardinality
          when "one_to_many"
            notation = "||--o{"
          when "many_to_one"
            notation = "}o--||"
          when "one_to_one"
            notation = "||--||"
          when "many_to_many"
            notation = "}|--|{"
          end

          notation
        end

        # Serialize relationship to hash
        #
        # @return [Hash] serialized relationship data
        def to_h
          {
            source_id: source_id,
            target_id: target_id,
            type: type,
            label: label,
            cardinality: cardinality,
            metadata: metadata
          }
        end

        # Serialize relationship to JSON
        #
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Create relationship from hash
        #
        # @param hash [Hash] relationship data
        # @return [Relationship] new relationship instance
        def self.from_h(hash)
          hash = hash.transform_keys(&:to_sym) if hash.keys.first.is_a?(String)

          new(
            source_id: hash[:source_id],
            target_id: hash[:target_id],
            type: hash[:type],
            label: hash[:label],
            cardinality: hash[:cardinality],
            metadata: hash[:metadata] || {}
          )
        end

        # Create relationship from JSON
        #
        # @param json [String] JSON string
        # @return [Relationship] new relationship instance
        def self.from_json(json)
          from_h(JSON.parse(json))
        end

        # Check equality with another relationship
        #
        # @param other [Relationship] other relationship to compare
        # @return [Boolean] true if relationships are equal
        def ==(other)
          return false unless other.is_a?(Relationship)

          source_id == other.source_id &&
            target_id == other.target_id &&
            type == other.type &&
            label == other.label &&
            cardinality == other.cardinality &&
            metadata == other.metadata
        end

        # Generate hash code for relationship
        #
        # @return [Integer] hash code
        def hash
          [source_id, target_id, type, label, cardinality, metadata].hash
        end

        # String representation of relationship
        #
        # @return [String] string representation
        def to_s
          "#{self.class.name}(source: #{source_id}, target: #{target_id}, type: #{type})"
        end

        # Detailed string representation
        #
        # @return [String] detailed string representation
        def inspect
          "#{self.class.name}(source: #{source_id.inspect}, target: #{target_id.inspect}, " \
            "type: #{type.inspect}, label: #{label.inspect}, cardinality: #{cardinality.inspect})"
        end
      end
    end
  end
end
