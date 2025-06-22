# frozen_string_literal: true

module Dbwatcher
  module Services
    # Generates Mermaid diagrams from session relationship data
    #
    # This service creates Mermaid diagram syntax for visualizing database
    # relationships and model associations within tracked sessions.
    #
    # @example
    #   generator = DiagramGenerator.new(session_id, 'database_tables')
    #   result = generator.call
    #   # => { content: "erDiagram\n    USERS ||--o{ ORDERS : user_id", type: 'erDiagram' }
    class DiagramGenerator < BaseService
      # Available diagram types with metadata
      DIAGRAM_TYPES = {
        "database_tables" => {
          name: "Database Tables",
          type: "erDiagram",
          description: "Entity Relationship Diagram based on database schema"
        },
        "model_associations" => {
          name: "Model Associations",
          type: "flowchart",
          description: "Flowchart showing ActiveRecord model associations"
        }
      }.freeze

      # Initialize with session id and diagram type
      #
      # @param session_id [String] session identifier
      # @param diagram_type [String] type of diagram to generate
      def initialize(session_id, diagram_type = "database_tables")
        @session_id = session_id
        @diagram_type = diagram_type
        super()
      end

      # Generate diagram for session
      #
      # @return [Hash] diagram data with content and type
      def call
        log_service_start "Generating #{@diagram_type} diagram", { session_id: @session_id }
        start_time = Time.current

        # Validate inputs
        begin
          unless session_exists?(@session_id)
            Rails.logger.error "DiagramGenerator: Session not found: #{@session_id}"
            return error_response("Session not found")
          end

          unless valid_diagram_type?(@diagram_type)
            Rails.logger.error "DiagramGenerator: Invalid diagram type: #{@diagram_type}"
            return error_response("Invalid diagram type")
          end

          # Generate appropriate diagram
          result = generate_diagram_content

          log_service_completion(start_time, {
                                   session_id: @session_id,
                                   diagram_type: @diagram_type,
                                   success: !result[:error],
                                   content_lines: result[:content]&.count("\n") || 0
                                 })

          result
        rescue StandardError => e
          Rails.logger.error "DiagramGenerator error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
          error_response("Error generating diagram: #{e.message}")
        end
      end

      # Get available diagram types
      #
      # @return [Hash] diagram types with metadata
      def self.available_types
        DIAGRAM_TYPES
      end

      private

      # Check if session exists
      #
      # @param session_id [String] session identifier
      # @return [Boolean] true if session exists
      def session_exists?(session_id)
        Storage.sessions.find(session_id)
        true
      rescue StandardError
        false
      end

      # Validate diagram type
      #
      # @param diagram_type [String] diagram type
      # @return [Boolean] true if valid
      def valid_diagram_type?(diagram_type)
        DIAGRAM_TYPES.key?(diagram_type)
      end

      # Generate diagram content based on type
      #
      # @return [Hash] Success response with diagram content
      def generate_diagram_content
        case @diagram_type
        when "database_tables"
          generate_erd_diagram
        when "model_associations"
          generate_model_associations_diagram
        else
          error_response("Unsupported diagram type: #{@diagram_type}")
        end
      end

      # Generate ERD diagram
      #
      # @return [Hash] Success response with ERD content
      def generate_erd_diagram
        session = Storage.sessions.find(@session_id)
        relationships = Dbwatcher::Services::Analyzers::SchemaRelationshipAnalyzer.new(session).call
        content = build_erd_content(relationships)
        success_response(content, "erDiagram")
      end

      # Generate model associations diagram
      #
      # @return [Hash] Success response with flowchart content
      def generate_model_associations_diagram
        session = Storage.sessions.find(@session_id)
        associations = Dbwatcher::Services::Analyzers::ModelAssociationAnalyzer.new(session).call
        content = build_graph_content(associations)
        success_response(content, "flowchart")
      end

      # Build ERD Mermaid content from schema relationships
      #
      # @param relationships [Array<Hash>] schema relationships
      # @return [String] Mermaid ERD syntax
      def build_erd_content(relationships)
        lines = ["erDiagram"]

        return empty_erd_content(lines) if relationships.empty?

        add_table_definitions(lines, relationships)
        add_relationship_definitions(lines, relationships)

        lines.join("\n")
      end

      # Generate empty ERD content when no relationships found
      #
      # @param lines [Array<String>] existing lines array
      # @return [String] Mermaid ERD syntax for empty state
      def empty_erd_content(lines)
        lines << "    %% No database relationships found in this session"
        lines << "    EmptyTable {"
        lines << "        string message \"No relationships detected\""
        lines << "    }"
        lines.join("\n")
      end

      # Add table definitions to ERD
      #
      # @param lines [Array<String>] lines array to modify
      # @param relationships [Array<Hash>] schema relationships
      def add_table_definitions(lines, relationships)
        tables = extract_unique_tables(relationships)

        tables.each do |table|
          lines << "    #{safe_table_name(table)} {"
          lines << "    }"
        end
      end

      # Add relationship definitions to ERD
      #
      # @param lines [Array<String>] lines array to modify
      # @param relationships [Array<Hash>] schema relationships
      def add_relationship_definitions(lines, relationships)
        relationships.each do |rel|
          next unless valid_relationship?(rel)

          cardinality = infer_erd_cardinality(rel)
          constraint_label = rel[:constraint_name] || rel[:from_column] || "fk"

          from_table = safe_table_name(rel[:from_table])
          to_table = safe_table_name(rel[:to_table])

          lines << "    #{to_table} #{cardinality} #{from_table} : \"#{constraint_label}\""
        end
      end

      # Extract unique tables from relationships
      #
      # @param relationships [Array<Hash>] schema relationships
      # @return [Set<String>] unique table names
      def extract_unique_tables(relationships)
        tables = Set.new
        relationships.each do |rel|
          tables << rel[:from_table].to_s if rel[:from_table]
          tables << rel[:to_table].to_s if rel[:to_table]
        end
        tables
      end

      # Check if relationship is valid for ERD
      #
      # @param rel [Hash] relationship data
      # @return [Boolean] true if relationship is complete
      def valid_relationship?(rel)
        rel[:from_table] && rel[:to_table]
      end

      # Ensure table name is safe for ERD diagram
      #
      # @param table_name [String] raw table name
      # @return [String] sanitized table name for ERD
      def safe_table_name(table_name)
        return "UNKNOWN_TABLE" unless table_name.is_a?(String) && !table_name.empty?

        table_name.strip.upcase.gsub(/[^A-Z0-9_]/, "_")
      end

      # Build Graph Mermaid content from model associations
      #
      # @param associations [Array<Hash>] model associations
      # @return [String] Mermaid graph syntax
      def build_graph_content(associations)
        lines = ["flowchart LR"]

        return empty_associations_content(lines) if associations.empty?

        added_nodes = add_association_nodes(lines, associations)
        add_association_edges(lines, associations, added_nodes)
        handle_isolated_nodes(lines, associations, added_nodes)
        add_node_styling(lines, added_nodes)

        lines.join("\n")
      end

      # Generate content for empty associations
      #
      # @param lines [Array<String>] existing lines array
      # @return [String] Mermaid flowchart syntax for empty state
      def empty_associations_content(lines)
        lines << "    %% No model associations found in this session"
        lines << "    NoAssoc[\"No model associations were detected in this session\"]"
        lines << "    style NoAssoc fill:lightgray,stroke:gray,stroke-width:1px,color:gray"
        lines.join("\n")
      end

      # Add nodes for all models in associations
      #
      # @param lines [Array<String>] lines array to modify
      # @param associations [Array<Hash>] model associations
      # @return [Set<String>] set of added node IDs
      def add_association_nodes(lines, associations)
        added_nodes = Set.new

        associations.each do |assoc|
          next unless valid_association?(assoc)

          add_source_node(lines, assoc, added_nodes)
          add_target_node(lines, assoc, added_nodes) if target_model?(assoc)
        end

        added_nodes
      end

      # Add edges between associated models
      #
      # @param lines [Array<String>] lines array to modify
      # @param associations [Array<Hash>] model associations
      # @param added_nodes [Set<String>] set of node IDs
      def add_association_edges(lines, associations, added_nodes)
        associations.each do |assoc|
          next unless should_add_edge?(assoc)

          source_id = generate_node_id(assoc[:source_model])
          target_id = generate_node_id(assoc[:target_model])

          next unless added_nodes.include?(source_id) && added_nodes.include?(target_id)

          add_edge_line(lines, source_id, target_id, assoc[:association_name])
        end
      end

      # Handle isolated nodes (models with no associations)
      #
      # @param lines [Array<String>] lines array to modify
      # @param associations [Array<Hash>] model associations
      # @param added_nodes [Set<String>] set of node IDs
      def handle_isolated_nodes(lines, associations, added_nodes)
        return unless all_nodes_isolated?(associations)

        lines << "    %% Models exist but no associations were found between them"
        lines << "    note[\"Models exist but no associations were found between them\"]"
        lines << "    style note fill:lightyellow,stroke:orange,stroke-width:1px,color:black"

        connect_note_to_first_node(lines, added_nodes)
      end

      # Add styling to all nodes
      #
      # @param lines [Array<String>] lines array to modify
      # @param added_nodes [Set<String>] set of node IDs
      def add_node_styling(lines, added_nodes)
        added_nodes.each do |node_id|
          lines << "    style #{node_id} fill:lightblue,stroke:blue,stroke-width:1px"
        end
      end

      # Validate association object
      #
      # @param assoc [Hash] association data
      # @return [Boolean] true if association is valid
      def valid_association?(assoc)
        assoc.is_a?(Hash) && !assoc[:source_model].to_s.empty?
      end

      # Check if association has target model
      #
      # @param assoc [Hash] association data
      # @return [Boolean] true if has target model and not node_only
      def target_model?(assoc)
        assoc[:type] != "node_only" && assoc[:target_model]
      end

      # Check if edge should be added
      #
      # @param assoc [Hash] association data
      # @return [Boolean] true if edge should be added
      def should_add_edge?(assoc)
        target_model?(assoc) && !assoc[:target_model].to_s.empty?
      end

      # Add source node to lines
      #
      # @param lines [Array<String>] lines array to modify
      # @param assoc [Hash] association data
      # @param added_nodes [Set<String>] set to track added nodes
      def add_source_node(lines, assoc, added_nodes)
        source_model = assoc[:source_model].to_s
        source_id = generate_node_id(source_model)

        return if added_nodes.include?(source_id)

        lines << "    #{source_id}[\"#{source_model}\"]"
        added_nodes << source_id
      end

      # Add target node to lines
      #
      # @param lines [Array<String>] lines array to modify
      # @param assoc [Hash] association data
      # @param added_nodes [Set<String>] set to track added nodes
      def add_target_node(lines, assoc, added_nodes)
        target_model = assoc[:target_model].to_s
        return if target_model.empty?

        target_id = generate_node_id(target_model)
        return if added_nodes.include?(target_id)

        lines << "    #{target_id}[\"#{target_model}\"]"
        added_nodes << target_id
      end

      # Add edge line between nodes
      #
      # @param lines [Array<String>] lines array to modify
      # @param source_id [String] source node ID
      # @param target_id [String] target node ID
      # @param association_name [String] name of the association
      def add_edge_line(lines, source_id, target_id, association_name)
        lines << if association_name
                   "    #{source_id} -->|#{association_name}| #{target_id}"
                 else
                   "    #{source_id} --> #{target_id}"
                 end
      end

      # Generate consistent node ID from model name
      #
      # @param model_name [String] model class name
      # @return [String] node ID
      def generate_node_id(model_name)
        "node_#{Digest::MD5.hexdigest(model_name.to_s)[0, 8]}"
      end

      # Check if all associations are node_only (isolated)
      #
      # @param associations [Array<Hash>] model associations
      # @return [Boolean] true if all are isolated
      def all_nodes_isolated?(associations)
        associations.all? { |a| a[:type] == "node_only" }
      end

      # Connect note to first node for visibility
      #
      # @param lines [Array<String>] lines array to modify
      # @param added_nodes [Set<String>] set of node IDs
      def connect_note_to_first_node(lines, added_nodes)
        return unless added_nodes.any?

        first_node = added_nodes.first
        lines << "    note --- #{first_node}"
      end

      # Infer ERD cardinality from relationship data
      #
      # @param _relationship [Hash] relationship data (unused for now)
      # @return [String] Mermaid ERD cardinality notation
      def infer_erd_cardinality(_relationship)
        # Default to one-to-many for foreign keys
        # Could be enhanced with more sophisticated detection
        "||--o{"
      end

      # Build success response
      #
      # @param content [String] diagram content
      # @param type [String] diagram type
      # @return [Hash] success response
      def success_response(content, type)
        {
          content: content,
          type: type,
          generated_at: Time.current.iso8601
        }
      end

      # Build error response
      #
      # @param message [String] error message
      # @return [Hash] error response
      def error_response(message)
        {
          error: message,
          generated_at: Time.current.iso8601
        }
      end
    end
  end
end
