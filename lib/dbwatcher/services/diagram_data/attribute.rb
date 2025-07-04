# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramData
      # Attribute representing a property of an entity
      #
      # This class provides a standardized representation for entity attributes
      # (columns, fields, properties) with consistent validation and serialization.
      #
      # @example
      #   attribute = Attribute.new(
      #     name: "email",
      #     type: "string",
      #     nullable: false,
      #     default: nil,
      #     metadata: { unique: true }
      #   )
      #   attribute.valid? # => true
      #   attribute.to_h   # => { name: "email", type: "string", ... }
      class Attribute
        attr_accessor :name, :type, :nullable, :default, :metadata

        # Initialize attribute
        #
        # @param name [String] attribute name
        # @param type [String] attribute data type
        # @param nullable [Boolean] whether attribute can be null
        # @param default [Object] default value
        # @param metadata [Hash] additional type-specific information
        def initialize(name:, type: nil, nullable: true, default: nil, metadata: {})
          @name = name.to_s
          @type = type.to_s
          @nullable = nullable == true || nullable.nil?
          @default = default
          @metadata = metadata.is_a?(Hash) ? metadata : {}
        end

        # Check if attribute is valid
        #
        # @return [Boolean] true if attribute has required fields
        def valid?
          validation_errors.empty?
        end

        # Get validation errors
        #
        # @return [Array<String>] array of validation error messages
        def validation_errors
          errors = []
          errors << "Name cannot be blank" if name.nil? || name.to_s.strip.empty?
          errors << "Metadata must be a Hash" unless metadata.is_a?(Hash)
          errors
        end

        # Check if attribute is a primary key
        #
        # @return [Boolean] true if attribute is a primary key
        def primary_key?
          metadata[:primary_key] == true
        end

        # Check if attribute is a foreign key
        #
        # @return [Boolean] true if attribute is a foreign key
        def foreign_key?
          metadata[:foreign_key] == true || name.to_s.end_with?("_id")
        end

        # Serialize attribute to hash
        #
        # @return [Hash] serialized attribute data
        def to_h
          {
            name: name,
            type: type,
            nullable: nullable,
            default: default,
            metadata: metadata
          }
        end

        # Serialize attribute to JSON
        #
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Create attribute from hash
        #
        # @param hash [Hash] attribute data
        # @return [Attribute] new attribute instance
        def self.from_h(hash)
          # Convert string keys to symbols for consistent access
          hash = hash.transform_keys(&:to_sym) if hash.keys.first.is_a?(String)

          # Use fetch with default values to handle missing fields
          new(
            name: hash[:name],
            type: hash[:type],
            nullable: hash.key?(:nullable) ? hash[:nullable] : true,
            default: hash[:default],
            metadata: hash[:metadata] || {}
          )
        end

        # Create attribute from JSON
        #
        # @param json [String] JSON string
        # @return [Attribute] new attribute instance
        def self.from_json(json)
          from_h(JSON.parse(json))
        end

        # Check equality with another attribute
        #
        # @param other [Attribute] other attribute to compare
        # @return [Boolean] true if attributes are equal
        def ==(other)
          return false unless other.is_a?(Attribute)

          name == other.name &&
            type == other.type &&
            nullable == other.nullable &&
            default == other.default &&
            metadata == other.metadata
        end

        # Generate hash code for attribute
        #
        # @return [Integer] hash code
        def hash
          [name, type, nullable, default, metadata].hash
        end

        # String representation of attribute
        #
        # @return [String] string representation
        def to_s
          "#{self.class.name}(name: #{name}, type: #{type}, nullable: #{nullable})"
        end

        # Detailed string representation
        #
        # @return [String] detailed string representation
        def inspect
          "#{self.class.name}(name: #{name.inspect}, type: #{type.inspect}, " \
            "nullable: #{nullable.inspect}, default: #{default.inspect}, metadata: #{metadata.inspect})"
        end
      end
    end
  end
end
