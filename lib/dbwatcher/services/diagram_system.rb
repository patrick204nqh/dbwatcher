# frozen_string_literal: true

# Diagram System Components
# This file centralizes all diagram-related requires for better organization

# Core diagram data structures
require_relative "diagram_data"

# Error handling
require_relative "diagram_error_handler"

# Registry and type management
require_relative "diagram_type_registry"

# Mermaid syntax generation
require_relative "mermaid_syntax_builder"
require_relative "mermaid_syntax/base_builder"
require_relative "mermaid_syntax/sanitizer"
require_relative "mermaid_syntax/cardinality_mapper"
require_relative "mermaid_syntax/erd_builder"
require_relative "mermaid_syntax/class_diagram_builder"
require_relative "mermaid_syntax/flowchart_builder"

# Diagram analyzers
require_relative "diagram_analyzers/base_analyzer"
require_relative "diagram_analyzers/foreign_key_analyzer"
require_relative "diagram_analyzers/inferred_relationship_analyzer"
require_relative "diagram_analyzers/model_association_analyzer"

# Diagram strategies
require_relative "diagram_strategies/base_diagram_strategy"
require_relative "diagram_strategies/diagram_strategy_helpers"
require_relative "diagram_strategies/standard_diagram_strategy"
require_relative "diagram_strategies/erd_diagram_strategy"
require_relative "diagram_strategies/class_diagram_strategy"
require_relative "diagram_strategies/flowchart_diagram_strategy"

# Diagram generator (must be loaded after all components)
require_relative "diagram_generator"

module Dbwatcher
  module Services
    # Diagram System Module
    # Provides centralized access to diagram generation capabilities
    module DiagramSystem
      extend Dbwatcher::Logging

      # Explicitly set the component name for logging
      def self.component_name
        "DiagramSystem"
      end

      # Get available diagram types
      #
      # @return [Array<String>] available diagram type names
      def self.available_types
        DiagramTypeRegistry.new.available_types
      end

      # Generate diagram for session
      #
      # @param session_id [String] session identifier
      # @param diagram_type [String] type of diagram to generate
      # @return [Hash] diagram generation result
      def self.generate(session_id, diagram_type = "database_tables")
        log_debug("Generating diagram of type #{diagram_type} for session #{session_id}")
        generator = DiagramGenerator.new(session_id: session_id, diagram_type: diagram_type)
        result = generator.call
        log_debug("Diagram generation completed with success=#{result[:success]}")
        result
      end

      # Check if diagram type is supported
      #
      # @param diagram_type [String] diagram type to check
      # @return [Boolean] true if supported
      def self.supports?(diagram_type)
        DiagramTypeRegistry.new.type_exists?(diagram_type)
      end
    end
  end
end
