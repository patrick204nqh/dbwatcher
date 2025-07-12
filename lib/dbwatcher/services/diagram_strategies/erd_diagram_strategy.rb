# frozen_string_literal: true

require_relative "base_diagram_strategy"
require_relative "diagram_strategy_helpers"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating Entity Relationship Diagrams (ERD)
      #
      # Handles ERD diagram generation by converting dataset entities and relationships
      # to Mermaid ERD syntax.
      class ErdDiagramStrategy < BaseDiagramStrategy
        include DiagramStrategyHelpers

        protected

        # Generate ERD diagram content from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [String] diagram content
        def generate_diagram_content(dataset)
          generate_standard_diagram_content(dataset, {
                                              empty_method: :build_empty_erd,
                                              empty_message: "No database relationships or tables found",
                                              empty_entities_method: :build_erd_diagram_with_tables,
                                              full_diagram_method: :build_erd_diagram_from_dataset
                                            })
        end

        private

        # Strategy metadata methods

        def strategy_name
          "Database Schema (ERD)"
        end

        def strategy_description
          "Entity relationship diagram showing database tables and foreign key relationships"
        end

        def mermaid_diagram_type
          "erDiagram"
        end
      end
    end
  end
end
