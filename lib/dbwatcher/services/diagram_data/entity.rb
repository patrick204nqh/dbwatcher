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
      #     attributes: [
      #       Attribute.new(name: "id", type: "integer", nullable: false, metadata: { primary_key: true })
      #     ],
      #     metadata: { columns: ["id", "name", "email"] }
      #   )
      #   entity.valid? # => true
      #   entity.to_h   # => { id: "users", name: "User", ... }
      class Entity
        attr_accessor :id, :name, :type, :attributes, :metadata

        # Initialize entity
        #
        # @param id [String] unique identifier for the entity
        # @param name [String] display name for the entity
        # @param type [String] entity type (table, model, etc.)
        # @param attributes [Array<Attribute>] entity attributes/properties
        # @param metadata [Hash] additional type-specific information
        def initialize(id:, name:, type: "default", attributes: [], metadata: {})
          @id = id.to_s
          @name = name.to_s
          @type = type.to_s
          @attributes = attributes.is_a?(Array) ? attributes : []
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
          errors << "Attributes must be an Array" unless attributes.is_a?(Array)
          errors << "Metadata must be a Hash" unless metadata.is_a?(Hash)

          # Validate all attributes
          attributes.each_with_index do |attribute, index|
            errors << "Attribute at index #{index} is invalid" unless attribute.is_a?(Attribute) && attribute.valid?
          end

          errors
        end

        # Add an attribute to the entity
        #
        # @param attribute [Attribute] attribute to add
        # @return [Attribute] the added attribute
        # @raise [ArgumentError] if attribute is invalid
        def add_attribute(attribute)
          raise ArgumentError, "Attribute must be an Attribute instance" unless attribute.is_a?(Attribute)
          raise ArgumentError, "Attribute is invalid: #{attribute.validation_errors.join(", ")}" unless attribute.valid?

          @attributes << attribute
          attribute
        end

        # Get primary key attributes
        #
        # @return [Array<Attribute>] primary key attributes
        def primary_key_attributes
          attributes.select(&:primary_key?)
        end

        # Get foreign key attributes
        #
        # @return [Array<Attribute>] foreign key attributes
        def foreign_key_attributes
          attributes.select(&:foreign_key?)
        end

        # Serialize entity to hash
        #
        # @return [Hash] serialized entity data
        def to_h
          {
            id: id,
            name: name,
            type: type,
            attributes: attributes.map(&:to_h),
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
          attrs = []
          if hash[:attributes] || hash["attributes"]
            attr_data = hash[:attributes] || hash["attributes"]
            attrs = attr_data.map { |attr| Attribute.from_h(attr) }
          end

          new(
            id: hash[:id] || hash["id"],
            name: hash[:name] || hash["name"],
            type: hash[:type] || hash["type"] || "default",
            attributes: attrs,
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
            attributes == other.attributes &&
            metadata == other.metadata
        end

        # Generate hash code for entity
        #
        # @return [Integer] hash code
        def hash
          [id, name, type, attributes, metadata].hash
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
            "type: #{type.inspect}, attributes: #{attributes.length}, metadata: #{metadata.inspect})"
        end
      end
    end
  end
end
