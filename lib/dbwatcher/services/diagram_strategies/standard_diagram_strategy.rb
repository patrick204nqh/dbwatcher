# frozen_string_literal: true

require_relative "base_diagram_strategy"
require_relative "diagram_strategy_helpers"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Standard diagram strategy implementation
      #
      # Provides a common implementation for diagram strategies that follow
      # the standard pattern of generating diagrams from datasets.
      # Specific strategies can inherit from this class and provide only
      # the necessary configuration.
      class StandardDiagramStrategy < BaseDiagramStrategy
        include DiagramStrategyHelpers

        # Initialize with configuration options
        #
        # @param dependencies [Hash] injected dependencies
        # @option dependencies [Object] :syntax_builder Mermaid syntax builder
        # @option dependencies [Logger] :logger logger instance
        def initialize(dependencies = {})
          super
          @diagram_options = diagram_options
        end

        protected

        # Generate diagram content from dataset using standard pattern
        #
        # @param dataset [Dataset] standardized dataset
        # @return [String] diagram content
        def generate_diagram_content(dataset)
          generate_standard_diagram_content(dataset, @diagram_options)
        end

        # Get diagram generation options
        #
        # @return [Hash] diagram options
        def diagram_options
          {
            empty_method: empty_diagram_method,
            empty_message: empty_diagram_message,
            empty_entities_method: empty_entities_method,
            full_diagram_method: full_diagram_method
          }
        end

        # Get method name for generating empty diagram
        #
        # @return [Symbol] method name
        def empty_diagram_method
          raise NotImplementedError, "Subclasses must implement empty_diagram_method"
        end

        # Get message for empty diagram
        #
        # @return [String] empty diagram message
        def empty_diagram_message
          "No data available for diagram"
        end

        # Get method name for generating diagram with only entities
        #
        # @return [Symbol] method name
        def empty_entities_method
          nil
        end

        # Get method name for generating full diagram
        #
        # @return [Symbol] method name
        def full_diagram_method
          raise NotImplementedError, "Subclasses must implement full_diagram_method"
        end
      end
    end
  end
end
