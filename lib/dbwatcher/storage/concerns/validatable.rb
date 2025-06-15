# frozen_string_literal: true

module Dbwatcher
  module Storage
    module Concerns
      # Provides validation capabilities for storage classes
      #
      # This concern adds common validation methods and patterns used
      # across different storage implementations.
      #
      # @example
      #   class MyStorage < BaseStorage
      #     include Concerns::Validatable
      #
      #     def save(data)
      #       validate_presence!(data, :id, :name)
      #       # save logic
      #     end
      #   end
      module Validatable
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Defines required attributes for validation
          #
          # @param attributes [Array<Symbol>] list of required attributes
          # @return [void]
          def validates_presence_of(*attributes)
            @required_attributes = attributes
          end

          # Returns list of required attributes
          #
          # @return [Array<Symbol>] required attributes
          def required_attributes
            @required_attributes || []
          end
        end

        # Validates presence of required attributes
        #
        # @param data [Hash] data to validate
        # @param attributes [Array<Symbol>] specific attributes to check
        # @raise [ValidationError] if any required attribute is missing
        # @return [void]
        def validate_presence!(data, *attributes)
          attrs_to_check = attributes.any? ? attributes : self.class.required_attributes

          attrs_to_check.each do |attr|
            next if data.key?(attr) && !blank_value?(data[attr])

            raise ValidationError, "#{attr} is required but was #{data[attr].inspect}"
          end
        end

        # Validates that an ID is present and valid
        #
        # @param id [String, Integer, nil] ID to validate
        # @raise [ValidationError] if ID is invalid
        # @return [void]
        def validate_id!(id)
          return unless id.nil? || id.to_s.strip.empty?

          raise ValidationError, "ID cannot be nil or empty"
        end

        # Validates that a name is present and valid
        #
        # @param name [String, nil] name to validate
        # @raise [ValidationError] if name is invalid
        # @return [void]
        def validate_name!(name)
          return unless name.nil? || name.to_s.strip.empty?

          raise ValidationError, "Name cannot be nil or empty"
        end

        # Checks if an ID is valid
        #
        # @param id [String, Integer, nil] ID to check
        # @return [Boolean] true if ID is valid
        def valid_id?(id)
          !id.nil? && !id.to_s.strip.empty?
        end

        # Checks if a name is valid
        #
        # @param name [String, nil] name to check
        # @return [Boolean] true if name is valid
        def valid_name?(name)
          !name.nil? && !name.to_s.strip.empty?
        end

        private

        # Checks if a value should be considered blank
        #
        # @param value [Object] value to check
        # @return [Boolean] true if value is blank
        def blank_value?(value)
          case value
          when String
            value.strip.empty?
          when Array, Hash
            value.empty?
          when NilClass
            true
          else
            false
          end
        end
      end
    end
  end
end
