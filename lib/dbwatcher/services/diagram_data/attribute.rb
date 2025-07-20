# frozen_string_literal: true

require_relative "base"

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
      class Attribute < Base
        attr_accessor :name, :type, :nullable, :default, :metadata

        # Initialize attribute
        #
        # @param name [String] attribute name
        # @param type [String] attribute data type
        # @param nullable [Boolean] whether attribute can be null
        # @param default [Object] default value
        # @param metadata [Hash] additional type-specific information
        def initialize(name:, type: nil, nullable: true, default: nil, metadata: {})
          super() # Initialize parent class
          @name = name.to_s
          @type = type.to_s
          @nullable = nullable == true
          @default = default
          @metadata = metadata.is_a?(Hash) ? metadata : {}
        end

        # Implementation for Base class
        def comparable_attributes
          [name, type, nullable, default, metadata]
        end

        # Implementation for Base class
        def serializable_attributes
          {
            name: name,
            type: type,
            nullable: nullable,
            default: default,
            metadata: metadata
          }
        end

        # Implementation for Base class
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

        # Override base class method to handle nullable default
        def self.extract_constructor_args(hash)
          {
            name: hash[:name],
            type: hash[:type],
            nullable: hash.key?(:nullable) ? hash[:nullable] : true,
            default: hash[:default],
            metadata: hash[:metadata] || {}
          }
        end
      end
    end
  end
end
