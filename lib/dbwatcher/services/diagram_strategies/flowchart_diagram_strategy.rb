# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating flowchart diagrams from model associations
      #
      # Handles flowchart diagram generation by converting dataset entities and relationships
      # to Mermaid flowchart syntax.
      class FlowchartDiagramStrategy < BaseDiagramStrategy
        protected

        # Render flowchart diagram from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [Hash] diagram generation result
        def render_diagram(dataset)
          @logger.debug "Rendering flowchart diagram from dataset with #{dataset.entities.size} entities and " \
                        "#{dataset.relationships.size} relationships"

          # Generate diagram content directly from dataset
          content = if dataset.relationships.empty? && dataset.entities.empty?
                      @syntax_builder.build_empty_flowchart("No model associations or entities found")
                    elsif dataset.relationships.empty?
                      # Show isolated nodes if no relationships but entities exist
                      @syntax_builder.build_flowchart_with_nodes(dataset.entities.values)
                    else
                      @syntax_builder.build_flowchart_diagram_from_dataset(dataset)
                    end

          success_response(content, "flowchart")
        end

        private

        # Strategy metadata methods

        def strategy_name
          "Model Associations"
        end

        def strategy_description
          "Flowchart diagram showing ActiveRecord model relationships and associations"
        end

        def mermaid_diagram_type
          "flowchart"
        end
      end
    end
  end
end
