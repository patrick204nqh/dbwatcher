# frozen_string_literal: true

module Dbwatcher
  module Services
    # Registry for managing diagram types and creating strategy instances
    #
    # Provides a central registry for all available diagram types with metadata,
    # and factory methods for creating strategy instances.
    class DiagramTypeRegistry
      # Error classes for registry operations
      class UnknownTypeError < StandardError; end

      # Built-in diagram types with essential metadata
      DIAGRAM_TYPES = {
        "database_tables" => {
          strategy_class: "Dbwatcher::Services::DiagramStrategies::ErdDiagramStrategy",
          analyzer_class: "Dbwatcher::Services::DiagramAnalyzers::ForeignKeyAnalyzer",
          display_name: "Database Schema",
          description: "Entity relationship diagram showing database tables and foreign key relationships",
          mermaid_type: "erDiagram"
        },
        "database_tables_inferred" => {
          strategy_class: "Dbwatcher::Services::DiagramStrategies::ErdDiagramStrategy",
          analyzer_class: "Dbwatcher::Services::DiagramAnalyzers::InferredRelationshipAnalyzer",
          display_name: "Database Schema (Inferred)",
          description: "Entity relationship diagram with inferred relationships from naming patterns",
          mermaid_type: "erDiagram"
        },
        "model_associations" => {
          strategy_class: "Dbwatcher::Services::DiagramStrategies::ClassDiagramStrategy",
          analyzer_class: "Dbwatcher::Services::DiagramAnalyzers::ModelAssociationAnalyzer",
          display_name: "Model Associations",
          description: "Class diagram showing ActiveRecord models with attributes and methods",
          mermaid_type: "classDiagram"
        },
        "model_associations_flowchart" => {
          strategy_class: "Dbwatcher::Services::DiagramStrategies::FlowchartDiagramStrategy",
          analyzer_class: "Dbwatcher::Services::DiagramAnalyzers::ModelAssociationAnalyzer",
          display_name: "Model Associations (Flowchart)",
          description: "Flowchart diagram showing model relationships",
          mermaid_type: "flowchart"
        }
      }.freeze

      # Initialize registry
      def initialize
        @logger = if defined?(Rails) && Rails.respond_to?(:logger)
                    Rails.logger
                  else
                    require "logger"
                    Logger.new($stdout)
                  end
      end

      # Get list of available diagram type keys
      #
      # @return [Array<String>] diagram type keys
      def available_types
        DIAGRAM_TYPES.keys
      end

      # Get available types with metadata
      #
      # @return [Hash] diagram types with metadata
      def available_types_with_metadata
        DIAGRAM_TYPES.transform_values do |type_config|
          type_config.except(:strategy_class, :analyzer_class)
        end
      end

      # Create strategy instance for given type
      #
      # @param type [String] diagram type key
      # @param dependencies [Hash] optional dependencies to inject
      # @return [Object] strategy instance
      # @raise [UnknownTypeError] if type is unknown
      def create_strategy(type, dependencies = {})
        type_config = find_type_config(type)
        strategy_class = resolve_strategy_class(type_config[:strategy_class])

        @logger.debug("Creating strategy for type #{type}: #{strategy_class.name}")
        strategy_class.new(dependencies)
      rescue StandardError => e
        raise UnknownTypeError, "Cannot create strategy for type '#{type}': #{e.message}"
      end

      # Create analyzer instance for given type
      #
      # @param type [String] diagram type key
      # @param session [Object] session object
      # @return [Object] analyzer instance
      # @raise [UnknownTypeError] if type is unknown
      def create_analyzer(type, session)
        type_config = find_type_config(type)
        analyzer_class = resolve_analyzer_class(type_config[:analyzer_class])

        @logger.debug("Creating analyzer for type #{type}: #{analyzer_class.name}")
        analyzer_class.new(session)
      rescue StandardError => e
        raise UnknownTypeError, "Cannot create analyzer for type '#{type}': #{e.message}"
      end

      # Check if a diagram type exists
      #
      # @param type [String] diagram type key
      # @return [Boolean] true if type exists
      def type_exists?(type)
        DIAGRAM_TYPES.key?(type)
      end

      # Get metadata for a specific diagram type
      #
      # @param type [String] diagram type key
      # @return [Hash] type metadata
      # @raise [UnknownTypeError] if type is unknown
      def type_metadata(type)
        type_config = find_type_config(type)
        type_config.except(:strategy_class, :analyzer_class)
      end

      private

      # Find type configuration by key
      #
      # @param type [String] diagram type key
      # @return [Hash] type configuration
      # @raise [UnknownTypeError] if type not found
      def find_type_config(type)
        type_config = DIAGRAM_TYPES[type]
        raise UnknownTypeError, "Unknown diagram type: #{type}" unless type_config

        type_config
      end

      # Resolve strategy class from string or class
      #
      # @param strategy_class [String, Class] strategy class reference
      # @return [Class] resolved strategy class
      def resolve_strategy_class(strategy_class)
        if strategy_class.is_a?(String)
          strategy_class.constantize
        else
          strategy_class
        end
      rescue NameError => e
        raise UnknownTypeError, "Cannot resolve strategy class: #{e.message}"
      end

      # Resolve analyzer class from string or class
      #
      # @param analyzer_class [String, Class] analyzer class reference
      # @return [Class] resolved analyzer class
      def resolve_analyzer_class(analyzer_class)
        if analyzer_class.is_a?(String)
          analyzer_class.constantize
        else
          analyzer_class
        end
      rescue NameError => e
        raise UnknownTypeError, "Cannot resolve analyzer class: #{e.message}"
      end
    end
  end
end
