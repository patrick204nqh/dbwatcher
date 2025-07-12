# frozen_string_literal: true

require_relative "standard_diagram_strategy"

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating Entity Relationship Diagrams (ERD)
      #
      # Handles ERD diagram generation by converting dataset entities and relationships
      # to Mermaid ERD syntax.
      class ErdDiagramStrategy < StandardDiagramStrategy
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

        # Diagram generation configuration
        def empty_diagram_method
          :build_empty_erd
        end

        def empty_diagram_message
          "No database relationships or tables found"
        end

        def empty_entities_method
          :build_erd_diagram_with_tables
        end

        def full_diagram_method
          :build_erd_diagram_from_dataset
        end
      end
    end
  end
end
