# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating class diagrams from model associations
      #
      # Handles class diagram generation by converting dataset entities and relationships
      # to Mermaid class diagram syntax.
      class ClassDiagramStrategy < BaseDiagramStrategy
        protected

        # Render class diagram from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [Hash] diagram generation result
        def render_diagram(dataset)
          @logger.debug "Rendering class diagram from dataset with #{dataset.entities.size} entities and " \
                        "#{dataset.relationships.size} relationships"

          # Generate diagram content directly from dataset
          content = if dataset.relationships.empty? && dataset.entities.empty?
                      @syntax_builder.build_empty_class_diagram("No model associations or entities found")
                    else
                      @syntax_builder.build_class_diagram_from_dataset(dataset)
                    end

          success_response(content, "classDiagram")
        end

        private

        # Strategy metadata methods

        def strategy_name
          "Model Associations (Class Diagram)"
        end

        def strategy_description
          "Class diagram showing ActiveRecord model relationships and methods"
        end

        def mermaid_diagram_type
          "classDiagram"
        end
      end
    end
  end
end
