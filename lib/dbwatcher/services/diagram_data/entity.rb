# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramData
      # Entity representing a node in any diagram
      #
      # This class provides a standardized representation for all diagram entities
      # (nodes, tables, models, etc.) with consistent validation and serialization.
      #
      # @example
      #   entity = Entity.new(
      #     id: "users",
      #     name: "User",
      #     type: "table",
      #     metadata: { columns: ["id", "name", "email"] }
      #   )
      #   entity.valid? # => true
      #   entity.to_h   # => { id: "users", name: "User", ... }
      class Entity
        attr_accessor :id, :name, :type, :metadata

        # Initialize entity
        #
        # @param id [String] unique identifier for the entity
        # @param name [String] display name for the entity
        # @param type [String] entity type (table, model, etc.)
        # @param metadata [Hash] additional type-specific information
        def initialize(id:, name:, type: "default", metadata: {})
          @id = id.to_s
          @name = name.to_s
          @type = type.to_s
          @metadata = metadata.is_a?(Hash) ? metadata : {}
        end

        # Check if entity is valid
        #
        # @return [Boolean] true if entity has required fields
        def valid?
          validation_errors.empty?
        end

        # Get validation errors
        #
        # @return [Array<String>] array of validation error messages
        def validation_errors
          errors = []
          errors << "ID cannot be blank" if id.nil? || id.to_s.strip.empty?
          errors << "Name cannot be blank" if name.nil? || name.to_s.strip.empty?
          errors << "Type cannot be blank" if type.nil? || type.to_s.strip.empty?
          errors << "Metadata must be a Hash" unless metadata.is_a?(Hash)
          errors
        end

        # Serialize entity to hash
        #
        # @return [Hash] serialized entity data
        def to_h
          {
            id: id,
            name: name,
            type: type,
            metadata: metadata
          }
        end

        # Serialize entity to JSON
        #
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Create entity from hash
        #
        # @param hash [Hash] entity data
        # @return [Entity] new entity instance
        def self.from_h(hash)
          new(
            id: hash[:id] || hash["id"],
            name: hash[:name] || hash["name"],
            type: hash[:type] || hash["type"] || "default",
            metadata: hash[:metadata] || hash["metadata"] || {}
          )
        end

        # Create entity from JSON
        #
        # @param json [String] JSON string
        # @return [Entity] new entity instance
        def self.from_json(json)
          from_h(JSON.parse(json))
        end

        # Check equality with another entity
        #
        # @param other [Entity] other entity to compare
        # @return [Boolean] true if entities are equal
        def ==(other)
          return false unless other.is_a?(Entity)

          id == other.id &&
            name == other.name &&
            type == other.type &&
            metadata == other.metadata
        end

        # Generate hash code for entity
        #
        # @return [Integer] hash code
        def hash
          [id, name, type, metadata].hash
        end

        # String representation of entity
        #
        # @return [String] string representation
        def to_s
          "#{self.class.name}(id: #{id}, name: #{name}, type: #{type})"
        end

        # Detailed string representation
        #
        # @return [String] detailed string representation
        def inspect
          "#{self.class.name}(id: #{id.inspect}, name: #{name.inspect}, " \
            "type: #{type.inspect}, metadata: #{metadata.inspect})"
        end
      end
    end
  end
end
