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
      #     metadata: { cardinality: "1:n" }
      #   )
      #   relationship.valid? # => true
      #   relationship.to_h   # => { source_id: "users", target_id: "orders", ... }
      class Relationship
        attr_accessor :source_id, :target_id, :type, :label, :metadata

        # Initialize relationship
        #
        # @param source_id [String] ID of the source entity
        # @param target_id [String] ID of the target entity
        # @param type [String] relationship type (has_many, belongs_to, foreign_key, etc.)
        # @param label [String] optional display label for the relationship
        # @param metadata [Hash] additional type-specific information
        def initialize(source_id:, target_id:, type:, label: nil, metadata: {})
          @source_id = source_id.to_s
          @target_id = target_id.to_s
          @type = type.to_s
          @label = label&.to_s
          @metadata = metadata.is_a?(Hash) ? metadata : {}
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
          errors << "Source and target cannot be the same" if source_id == target_id
          errors << "Metadata must be a Hash" unless metadata.is_a?(Hash)
          errors
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
          new(
            source_id: hash[:source_id] || hash["source_id"],
            target_id: hash[:target_id] || hash["target_id"],
            type: hash[:type] || hash["type"],
            label: hash[:label] || hash["label"],
            metadata: hash[:metadata] || hash["metadata"] || {}
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
            metadata == other.metadata
        end

        # Generate hash code for relationship
        #
        # @return [Integer] hash code
        def hash
          [source_id, target_id, type, label, metadata].hash
        end

        # Check if relationship is bidirectional
        #
        # @return [Boolean] true if relationship should be treated as bidirectional
        def bidirectional?
          metadata[:bidirectional] == true || metadata["bidirectional"] == true
        end

        # Get reverse relationship
        #
        # @return [Relationship] relationship with source and target swapped
        def reverse
          self.class.new(
            source_id: target_id,
            target_id: source_id,
            type: reverse_type,
            label: reverse_label,
            metadata: metadata.merge(reversed: true)
          )
        end

        # String representation of relationship
        #
        # @return [String] string representation
        def to_s
          label_part = label ? " (#{label})" : ""
          "#{self.class.name}(#{source_id} --#{type}#{label_part}--> #{target_id})"
        end

        # Detailed string representation
        #
        # @return [String] detailed string representation
        def inspect
          "#{self.class.name}(source_id: #{source_id.inspect}, target_id: #{target_id.inspect}, " \
            "type: #{type.inspect}, label: #{label.inspect}, metadata: #{metadata.inspect})"
        end

        private

        # Get reverse relationship type
        #
        # @return [String] reverse type or original type if no mapping exists
        def reverse_type
          reverse_mappings = {
            "has_many" => "belongs_to",
            "belongs_to" => "has_many",
            "has_one" => "belongs_to",
            "has_and_belongs_to_many" => "has_and_belongs_to_many"
          }

          reverse_mappings[type] || type
        end

        # Get reverse relationship label
        #
        # @return [String, nil] reverse label or nil
        def reverse_label
          # For now, don't auto-generate reverse labels
          # Subclasses or specific implementations can override this
          nil
        end
      end
    end
  end
end
