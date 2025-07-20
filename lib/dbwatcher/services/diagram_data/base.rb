# frozen_string_literal: true

require "json"

module Dbwatcher
  module Services
    module DiagramData
      # Base class for diagram data objects
      #
      # Provides common functionality for serialization, validation, and comparison
      # that is shared across Attribute, Entity, and Relationship classes.
      #
      # Subclasses must implement:
      # - comparable_attributes: Array of values used for equality comparison
      # - serializable_attributes: Hash of attributes for serialization
      # - validation_errors: Array of validation error strings (optional)
      #
      # @example
      #   class MyClass < Base
      #     def comparable_attributes
      #       [name, type, value]
      #     end
      #
      #     def serializable_attributes
      #       { name: name, type: type, value: value }
      #     end
      #   end
      class Base
        # Check if object is valid
        #
        # @return [Boolean] true if object has no validation errors
        def valid?
          validation_errors.empty?
        end

        # Check equality with another object of the same class
        #
        # @param other [Object] object to compare with
        # @return [Boolean] true if objects are equal
        def ==(other)
          return false unless other.is_a?(self.class)

          comparable_attributes == other.comparable_attributes
        end

        # Generate hash code for object
        #
        # @return [Integer] hash code
        def hash
          comparable_attributes.hash
        end

        # Serialize object to hash
        #
        # @return [Hash] serialized object data
        def to_h
          serializable_attributes
        end

        # Serialize object to JSON
        #
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Create object from hash
        #
        # @param hash [Hash] object data
        # @return [Object] new object instance
        def self.from_h(hash)
          # Convert string keys to symbols for consistent access
          hash = hash.transform_keys(&:to_sym) if hash.respond_to?(:transform_keys) && hash.keys.first.is_a?(String)

          new(**extract_constructor_args(hash))
        end

        # Create object from JSON
        #
        # @param json [String] JSON string
        # @return [Object] new object instance
        def self.from_json(json)
          from_h(JSON.parse(json))
        end

        # String representation of object
        #
        # @return [String] string representation
        def to_s
          attrs = serializable_attributes.map { |k, v| "#{k}: #{v}" }.join(", ")
          "#{self.class.name}(#{attrs})"
        end

        # Detailed string representation
        #
        # @return [String] detailed string representation
        def inspect
          attrs = serializable_attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
          "#{self.class.name}(#{attrs})"
        end

        # Default implementation - subclasses should override
        def comparable_attributes
          raise NotImplementedError, "#{self.class} must implement #comparable_attributes"
        end

        # Default implementation - subclasses should override
        def serializable_attributes
          raise NotImplementedError, "#{self.class} must implement #serializable_attributes"
        end

        # Default implementation - subclasses should override if validation needed
        def validation_errors
          []
        end

        # Extract constructor arguments from hash
        # Subclasses can override this for custom initialization logic
        #
        # @param hash [Hash] object data
        # @return [Hash] constructor arguments
        def self.extract_constructor_args(hash)
          hash
        end
        private_class_method :extract_constructor_args
      end
    end
  end
end
