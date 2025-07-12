# frozen_string_literal: true

require_relative "base_diagram_strategy"
require_relative "diagram_strategy_helpers"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating class diagrams from model associations
      #
      # Handles class diagram generation by converting dataset entities and relationships
      # to Mermaid class diagram syntax.
      class ClassDiagramStrategy < BaseDiagramStrategy
        include DiagramStrategyHelpers

        protected

        # Generate class diagram content from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [String] diagram content
        def generate_diagram_content(dataset)
          generate_standard_diagram_content(dataset, {
                                              empty_method: :build_empty_class_diagram,
                                              empty_message: "No model associations or entities found",
                                              full_diagram_method: :build_class_diagram_from_dataset
                                            })
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
