# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Helper module for diagram strategies
      #
      # Provides common utility methods for diagram strategies to reduce code duplication.
      # These methods handle common patterns in diagram generation.
      module DiagramStrategyHelpers
        # Generate diagram content with empty state handling
        #
        # @param dataset [Dataset] standardized dataset
        # @param options [Hash] options for diagram generation
        # @option options [Symbol] :empty_method method to call for empty diagram
        # @option options [String] :empty_message message for empty diagram
        # @option options [Symbol] :empty_entities_method method to call for diagram with only entities
        # @option options [Symbol] :full_diagram_method method to call for complete diagram
        # @return [String] diagram content
        def generate_standard_diagram_content(dataset, options)
          if dataset.relationships.empty? && dataset.entities.empty?
            @syntax_builder.send(options[:empty_method], options[:empty_message])
          elsif dataset.relationships.empty? && options[:empty_entities_method]
            # Show isolated entities if no relationships but entities exist
            @syntax_builder.send(options[:empty_entities_method], dataset.entities.values)
          else
            @syntax_builder.send(options[:full_diagram_method], dataset)
          end
        end
      end
    end
  end
end
