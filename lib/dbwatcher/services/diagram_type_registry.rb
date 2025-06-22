# frozen_string_literal: true

module Dbwatcher
  module Services
    # Registry for managing diagram types and creating strategy instances
    #
    # Provides a central registry for all available diagram types with metadata,
    # factory methods for creating strategy instances, and runtime type registration.
    #
    # @example
    #   registry = DiagramTypeRegistry.new
    #   strategy = registry.create_strategy('database_tables')
    #   types = registry.available_types_with_metadata
    class DiagramTypeRegistry
      # Error classes for registry operations
      class RegistrationError < StandardError; end
      class UnknownTypeError < StandardError; end

      # Built-in diagram types with comprehensive metadata
      DIAGRAM_TYPES = {
        "database_tables" => {
          strategy_class: "Dbwatcher::Services::DiagramStrategies::ErdDiagramStrategy",
          display_name: "Database Schema (ERD)",
          description: "Entity relationship diagram showing database tables and relationships",
          category: "schema",
          mermaid_type: "erDiagram",
          enabled: true,
          features: %w[foreign_keys table_columns relationship_cardinality],
          configuration: {
            show_columns: { type: "boolean", default: true },
            show_data_types: { type: "boolean", default: false },
            max_tables: { type: "integer", default: 50 }
          }
        },
        "model_associations" => {
          strategy_class: "Dbwatcher::Services::DiagramStrategies::FlowchartDiagramStrategy",
          display_name: "Model Associations",
          description: "Flowchart showing ActiveRecord model relationships",
          category: "models",
          mermaid_type: "flowchart",
          enabled: true,
          features: %w[has_many belongs_to has_one has_and_belongs_to_many],
          configuration: {
            show_methods: { type: "boolean", default: false },
            max_models: { type: "integer", default: 30 },
            layout_direction: { type: "string", default: "LR", options: %w[LR TD RL BT] }
          }
        }
      }.freeze

      # Initialize registry with configuration
      #
      # @param config [Hash] registry configuration
      # @option config [Logger] :logger logger instance
      # @option config [Hash] :custom_types additional custom types
      def initialize(config = {})
        @config = config
        @custom_types = config[:custom_types] || {}
        @logger = config[:logger] || Rails.logger
      end

      # Get list of available diagram type keys
      #
      # @return [Array<String>] enabled diagram type keys
      def available_types
        enabled_types.keys
      end

      # Get available types with full metadata
      #
      # @return [Hash] diagram types with metadata (excluding strategy_class)
      def available_types_with_metadata
        enabled_types.transform_values do |type_config|
          metadata = type_config.except(:strategy_class)
          # Add backward compatibility mapping for tests
          metadata[:type] = metadata[:mermaid_type] if metadata[:mermaid_type]
          metadata
        end
      end

      # Create strategy instance for given type
      #
      # @param type [String] diagram type key
      # @param dependencies [Hash] optional dependencies to inject
      # @return [Object] strategy instance
      # @raise [UnknownTypeError] if type is unknown or disabled
      def create_strategy(type, dependencies = {})
        type_config = find_type_config(type)
        strategy_class = resolve_strategy_class(type_config[:strategy_class])

        @logger.debug("Creating strategy for type #{type}: #{strategy_class.name}")
        strategy_class.new(dependencies)
      rescue StandardError => e
        raise UnknownTypeError, "Cannot create strategy for type '#{type}': #{e.message}"
      end

      # Register a new custom diagram type
      #
      # @param name [String] unique type name
      # @param strategy_class [Class, String] strategy class or class name
      # @param metadata [Hash] type metadata
      # @option metadata [String] :display_name human-readable name
      # @option metadata [String] :description type description
      # @option metadata [String] :category type category
      # @option metadata [String] :mermaid_type Mermaid diagram type
      # @option metadata [Boolean] :enabled whether type is enabled
      # @option metadata [Array<String>] :features supported features
      # @option metadata [Hash] :configuration configurable options
      # @raise [RegistrationError] if registration fails
      def register_type(name, strategy_class, metadata = {})
        validate_strategy_class!(strategy_class)
        validate_type_name!(name)

        @custom_types[name] = {
          strategy_class: strategy_class.is_a?(String) ? strategy_class : strategy_class.name,
          display_name: metadata[:display_name] || name.humanize,
          description: metadata[:description] || "Custom diagram type: #{name}",
          category: metadata[:category] || "custom",
          mermaid_type: metadata[:mermaid_type] || "flowchart",
          enabled: metadata.fetch(:enabled, true),
          features: metadata[:features] || [],
          configuration: metadata[:configuration] || {}
        }

        @logger.info("Registered custom diagram type", name: name, class: strategy_class)
      end

      # Check if a diagram type exists and is enabled
      #
      # @param type [String] diagram type key
      # @return [Boolean] true if type exists and is enabled
      def type_exists?(type)
        enabled_types.key?(type)
      end

      # Get metadata for a specific diagram type
      #
      # @param type [String] diagram type key
      # @return [Hash] type metadata
      # @raise [UnknownTypeError] if type is unknown
      def type_metadata(type)
        type_config = find_type_config(type)
        type_config.except(:strategy_class)
      end

      # Get all types grouped by category
      #
      # @return [Hash] types grouped by category
      def types_by_category
        enabled_types.group_by { |_, config| config[:category] }
                     .transform_values do |types|
          types.to_h.transform_values do |config|
            config.except(:strategy_class)
          end
        end
      end

      # Disable a diagram type
      #
      # @param type [String] diagram type key
      def disable_type(type)
        if DIAGRAM_TYPES.key?(type)
          @logger.warn("Cannot disable built-in type", type: type)
          return false
        end

        if @custom_types.key?(type)
          @custom_types[type][:enabled] = false
          @logger.info("Disabled custom type", type: type)
          true
        else
          false
        end
      end

      # Enable a diagram type
      #
      # @param type [String] diagram type key
      def enable_type(type)
        if @custom_types.key?(type)
          @custom_types[type][:enabled] = true
          @logger.info("Enabled custom type", type: type)
          true
        else
          @logger.warn("Cannot enable unknown type", type: type)
          false
        end
      end

      private

      # Get all enabled types (built-in + custom)
      #
      # @return [Hash] enabled diagram types
      def enabled_types
        all_types.select { |_, config| config[:enabled] }
      end

      # Get all types (built-in + custom)
      #
      # @return [Hash] all diagram types
      def all_types
        DIAGRAM_TYPES.merge(@custom_types)
      end

      # Find configuration for a specific type
      #
      # @param type [String] diagram type key
      # @return [Hash] type configuration
      # @raise [UnknownTypeError] if type is unknown or disabled
      def find_type_config(type)
        type_config = enabled_types[type]
        raise UnknownTypeError, "Unknown or disabled diagram type: #{type}" unless type_config

        type_config
      end

      # Resolve strategy class from string or class
      #
      # @param strategy_class [String, Class] strategy class or name
      # @return [Class] resolved strategy class
      def resolve_strategy_class(strategy_class)
        if strategy_class.is_a?(String)
          strategy_class.constantize
        else
          strategy_class
        end
      rescue NameError => e
        raise UnknownTypeError, "Strategy class not found: #{strategy_class} (#{e.message})"
      end

      # Validate strategy class inheritance
      #
      # @param strategy_class [Class, String] strategy class to validate
      # @raise [RegistrationError] if validation fails
      def validate_strategy_class!(strategy_class)
        # If it's a string, try to constantize it
        klass = strategy_class.is_a?(String) ? strategy_class.constantize : strategy_class

        base_strategy_name = "Dbwatcher::Services::DiagramStrategies::BaseDiagramStrategy"
        unless klass.ancestors.map(&:name).include?(base_strategy_name)
          raise RegistrationError, "Strategy class must inherit from #{base_strategy_name}"
        end
      rescue NameError
        # If we can't constantize it, assume it's valid for now (will fail at runtime if not)
        @logger.warn("Could not validate strategy class at registration time", class: strategy_class)
      end

      # Validate type name for registration
      #
      # @param name [String] type name to validate
      # @raise [RegistrationError] if validation fails
      def validate_type_name!(name)
        raise RegistrationError, "Type name must be a non-empty string" if name.blank? || !name.is_a?(String)

        if name.match?(/[^a-z0-9_]/)
          raise RegistrationError, "Type name must contain only lowercase letters, numbers, and underscores"
        end

        return unless all_types.key?(name)

        raise RegistrationError, "Type '#{name}' is already registered"
      end
    end
  end
end
