# frozen_string_literal: true

require_relative "standard_diagram_strategy"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating class diagrams from model associations
      #
      # Handles class diagram generation by converting dataset entities and relationships
      # to Mermaid class diagram syntax.
      class ClassDiagramStrategy < StandardDiagramStrategy
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

        # Diagram generation configuration
        def empty_diagram_method
          :build_empty_class_diagram
        end

        def empty_diagram_message
          "No model associations or entities found"
        end

        def full_diagram_method
          :build_class_diagram_from_dataset
        end
      end
    end
  end
end
