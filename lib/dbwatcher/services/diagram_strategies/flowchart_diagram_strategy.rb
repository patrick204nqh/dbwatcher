# frozen_string_literal: true

require_relative "standard_diagram_strategy"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating flowchart diagrams from model associations
      #
      # Handles flowchart diagram generation by converting dataset entities and relationships
      # to Mermaid flowchart syntax.
      class FlowchartDiagramStrategy < StandardDiagramStrategy
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

        # Diagram generation configuration
        def empty_diagram_method
          :build_empty_flowchart
        end

        def empty_diagram_message
          "No model associations or entities found"
        end

        def empty_entities_method
          :build_flowchart_with_nodes
        end

        def full_diagram_method
          :build_flowchart_diagram_from_dataset
        end
      end
    end
  end
end
