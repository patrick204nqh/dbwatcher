# frozen_string_literal: true

module Dbwatcher
  module Services
    module DiagramStrategies
      # Strategy for generating Entity Relationship Diagrams (ERD)
      #
      # Handles ERD diagram generation by analyzing database schema relationships
      # and converting them to Mermaid ERD syntax.
      #
      # @example
      #   strategy = ErdDiagramStrategy.new
      #   result = strategy.generate(session_id)
      #   # => { success: true, content: "erDiagram\n    USERS ||--o{ ORDERS...", type: "erDiagram" }
      class ErdDiagramStrategy < BaseDiagramStrategy
        # Initialize ERD strategy with dependencies
        #
        # @param dependencies [Hash] injected dependencies
        # @option dependencies [MermaidSyntaxBuilder] :syntax_builder Mermaid syntax builder
        # @option dependencies [Hash] :config strategy configuration
        # @option dependencies [Logger] :logger logger instance
        def initialize(dependencies = {})
          super
          @analyzer_class = dependencies[:analyzer_class] ||
                            Dbwatcher::Services::Analyzers::SchemaRelationshipAnalyzer
        end

        # Generate ERD diagram for session
        #
        # @param session_id [String] session identifier
        # @return [Hash] diagram generation result
        def generate(session_id)
          operation = "ERD diagram generation"
          log_operation_start(operation, session_id: session_id)

          result, duration = measure_duration do
            generate_erd_diagram(session_id)
          end

          log_operation_completion(operation, duration, {
                                     session_id: session_id,
                                     success: result[:success],
                                     relationship_count: count_relationships_in_content(result[:content])
                                   })

          result
        end

        protected

        # Check if session has required data for ERD generation
        #
        # @param session [Object] session object
        # @return [Boolean] true if session has database relationship data
        def has_required_data?(session)
          return false unless session

          # Check if session has table data that could contain relationships
          (session.respond_to?(:tables) && session.tables&.any?) ||
            (session.respond_to?(:queries) && session.queries&.any?)
        end

        private

        # Generate ERD diagram content
        #
        # @param session_id [String] session identifier
        # @return [Hash] generation result
        def generate_erd_diagram(session_id)
          session = load_session_with_validation(session_id)

          # Analyze database relationships
          analyzer = @analyzer_class.new(session)
          relationships = analyzer.call

          @logger.debug "Analyzed relationships for session #{session_id}: #{relationships.size} relationships"

          # Generate diagram content
          content = if relationships.empty?
                      @syntax_builder.build_empty_erd("No database relationships found in this session")
                    else
                      @syntax_builder.build_erd_diagram(relationships, erd_generation_options)
                    end

          success_response(content, "erDiagram")
        end

        # Get ERD-specific generation options
        #
        # @return [Hash] generation options for ERD
        def erd_generation_options
          {
            show_columns: @config[:show_columns] || false,
            show_data_types: @config[:show_data_types] || false,
            max_tables: @config[:max_tables] || 50,
            apply_styling: @config[:apply_styling] != false
          }
        end

        # Count relationships in generated content for metrics
        #
        # @param content [String] generated diagram content
        # @return [Integer] number of relationships found
        def count_relationships_in_content(content)
          return 0 unless content.is_a?(String)

          # Count ERD relationship lines (lines with cardinality notation)
          content.scan(/\|\w*\|--\w*\{\s*\w+/).size
        end

        # Strategy metadata methods

        def strategy_name
          "Database Schema (ERD)"
        end

        def strategy_description
          "Entity relationship diagram showing database tables and foreign key relationships"
        end

        def supported_features
          %w[
            foreign_keys
            table_relationships
            constraint_names
            cardinality_inference
            table_definitions
          ]
        end

        def configurable_options
          {
            show_columns: {
              type: "boolean",
              default: false,
              description: "Include column definitions in table entities"
            },
            show_data_types: {
              type: "boolean",
              default: false,
              description: "Show data types for columns"
            },
            max_tables: {
              type: "integer",
              default: 50,
              description: "Maximum number of tables to include"
            },
            apply_styling: {
              type: "boolean",
              default: true,
              description: "Apply default styling to diagram elements"
            }
          }
        end

        def mermaid_diagram_type
          "erDiagram"
        end
      end
    end
  end
end
