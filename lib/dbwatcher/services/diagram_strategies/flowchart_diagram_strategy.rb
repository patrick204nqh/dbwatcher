# frozen_string_literal: true

require_relative "base_diagram_strategy"
require_relative "diagram_strategy_helpers"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating flowchart diagrams from model associations
      #
      # Handles flowchart diagram generation by converting dataset entities and relationships
      # to Mermaid flowchart syntax.
      class FlowchartDiagramStrategy < BaseDiagramStrategy
        include DiagramStrategyHelpers

        protected

        # Generate flowchart diagram content from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [String] diagram content
        def generate_diagram_content(dataset)
          generate_standard_diagram_content(dataset, {
                                              empty_method: :build_empty_flowchart,
                                              empty_message: "No model associations or entities found",
                                              empty_entities_method: :build_flowchart_with_nodes,
                                              full_diagram_method: :build_flowchart_diagram_from_dataset
                                            })
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
