# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating Entity Relationship Diagrams (ERD)
      #
      # Handles ERD diagram generation by converting dataset entities and relationships
      # to Mermaid ERD syntax.
      class ErdDiagramStrategy < BaseDiagramStrategy
        protected

        # Render ERD diagram from standardized dataset
        #
        # @param dataset [Dataset] standardized dataset
        # @return [Hash] diagram generation result
        def render_diagram(dataset)
          @logger.debug "Rendering ERD diagram from dataset with #{dataset.entities.size} entities and #{dataset.relationships.size} relationships"

          # Generate diagram content directly from dataset
          content = if dataset.relationships.empty? && dataset.entities.empty?
                      @syntax_builder.build_empty_erd("No database relationships or tables found")
                    elsif dataset.relationships.empty?
                      # Show isolated tables if no relationships but entities exist
                      @syntax_builder.build_erd_diagram_with_tables(dataset.entities.values)
                    else
                      @syntax_builder.build_erd_diagram_from_dataset(dataset)
                    end

          success_response(content, "erDiagram")
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
