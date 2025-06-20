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
          type: "graph",
          description: "Graph showing ActiveRecord model associations"
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
          result = case @diagram_type
                   when "database_tables"
                     generate_schema_erd(@session_id)
                   when "model_associations"
                     generate_model_graph(@session_id)
                   else
                     error_response("Unsupported diagram type")
                   end

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

      # Generate schema-based Entity Relationship Diagram
      #
      # @return [Hash] diagram result
      def generate_schema_erd(session_id = nil)
        session_id ||= @session_id
        session = Storage.sessions.find(session_id)
        analyzer = Analyzers::SchemaRelationshipAnalyzer.new(session)
        relationships = analyzer.call

        content = build_erd_content(relationships)
        success_response(content, "erDiagram")
      end

      # Generate model associations graph
      #
      # @return [Hash] diagram result
      def generate_model_graph(session_id = nil)
        session_id ||= @session_id

        begin
          session = Storage.sessions.find(session_id)

          # Log before calling analyzer
          Rails.logger.info "DiagramGenerator: Starting model association analysis for session #{session_id}"

          analyzer = Analyzers::ModelAssociationAnalyzer.new(session)
          associations = analyzer.call

          # Log what we got from analyzer
          Rails.logger.info "DiagramGenerator: Found #{associations&.size || 0} model associations"

          if associations.nil? || associations.empty?
            Rails.logger.info "DiagramGenerator: No model associations found for session #{session_id}"
            content = "flowchart LR\n    EmptyNode[\"No model associations found\"]\n    style EmptyNode fill:#f9f9f9,stroke:#999"
          else
            content = build_graph_content(associations)
          end

          # Log the content length
          Rails.logger.info "DiagramGenerator: Generated model graph content with #{content.lines.count} lines"

          # Use 'flowchart' type for compatibility with newer Mermaid versions
          success_response(content, "flowchart")
        rescue StandardError => e
          Rails.logger.error "DiagramGenerator: Error generating model graph: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
          error_response("Error generating model associations diagram: #{e.message}")
        end
      end

      # Build ERD Mermaid content from schema relationships
      #
      # @param relationships [Array<Hash>] schema relationships
      # @return [String] Mermaid ERD syntax
      def build_erd_content(relationships)
        lines = ["erDiagram"]

        if relationships.empty?
          lines << "    %% No relationships found in this session"
          lines << "    NOTE \"No table relationships were detected in this session\" as NoRelationships"
          return lines.join("\n")
        end

        # First, ensure we have all tables defined (even isolated ones)
        tables = Set.new
        relationships.each do |rel|
          tables << rel[:from_table].to_s if rel[:from_table]
          tables << rel[:to_table].to_s if rel[:to_table]
        end

        # Define each table to ensure they exist even without relationships
        tables.each do |table|
          lines << "    #{safe_table_name(table)} {"
          lines << "    }"
        end

        # Add relationships
        relationships.each do |rel|
          next unless rel[:from_table] && rel[:to_table] # Skip incomplete relationships

          cardinality = infer_erd_cardinality(rel)
          constraint_label = rel[:constraint_name] || rel[:from_column] || "fk"

          from_table = safe_table_name(rel[:from_table])
          to_table = safe_table_name(rel[:to_table])

          # Ensure we have valid table names for the ERD
          lines << "    #{to_table} #{cardinality} #{from_table} : \"#{constraint_label}\""
        end

        lines.join("\n")
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
        # Use flowchart instead of graph for better compatibility with newer Mermaid versions
        lines = ["flowchart LR"]

        if associations.empty?
          lines << "    %% No model associations found in this session"
          lines << "    NoAssoc[\"No model associations were detected in this session\"]"
          lines << "    style NoAssoc fill:#f9f9f9,stroke:#999,stroke-width:1px,color:#666,font-style:italic"
          return lines.join("\n")
        end

        # Log for debugging
        Rails.logger.debug "Building model association diagram with #{associations.size} associations"

        # First define all nodes to ensure they exist before edges
        added_nodes = Set.new
        associations.each do |assoc|
          next unless assoc && assoc.is_a?(Hash)

          source_model = assoc[:source_model].to_s
          target_model = assoc[:target_model].to_s

          next if source_model.empty? || target_model.empty?

          source_id = "node_#{Digest::MD5.hexdigest(source_model)[0, 8]}"
          target_id = "node_#{Digest::MD5.hexdigest(target_model)[0, 8]}"

          unless added_nodes.include?(source_id)
            lines << "    #{source_id}[\"#{source_model}\"]"
            added_nodes << source_id
          end

          unless added_nodes.include?(target_id)
            lines << "    #{target_id}[\"#{target_model}\"]"
            added_nodes << target_id
          end
        end

        # Track added edges to avoid duplicates
        added_edges = Set.new

        # Then add all edges
        associations.each do |assoc|
          next unless assoc && assoc.is_a?(Hash)
          next unless assoc[:source_model] && assoc[:target_model]

          source_model = assoc[:source_model].to_s
          target_model = assoc[:target_model].to_s

          source_id = "node_#{Digest::MD5.hexdigest(source_model)[0, 8]}"
          target_id = "node_#{Digest::MD5.hexdigest(target_model)[0, 8]}"

          # Use a simple text for association type to avoid syntax issues
          assoc_type = assoc[:type].to_s.gsub(/[^\w\s]/, "")

          # Create unique edge identifier
          edge_key = "#{source_id}->#{target_id}->#{assoc_type}"
          next if added_edges.include?(edge_key)

          added_edges << edge_key

          # Build edge with simple text label to avoid syntax issues
          lines << "    #{source_id} -->|#{assoc_type}| #{target_id}"
        end

        # If no edges were created, add a note
        if added_edges.empty? && added_nodes.any?
          lines << "    %% No valid edges could be created between models"
          first_node = "node_#{Digest::MD5.hexdigest(associations.first[:source_model].to_s)[0, 8]}"
          lines << "    Note[\"No relationships could be visualized\"]"
          lines << "    #{first_node} -.-> Note"
          lines << "    style Note fill:#fff7e0,stroke:#e0d0a0,stroke-width:1px,color:#806000,font-style:italic"
        end

        result = lines.join("\n")
        Rails.logger.debug "Generated model association diagram content:\n#{result}"
        result
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

      # Sanitize model name for use as Mermaid node identifier
      #
      # @param model_name [String] model class name
      # @return [String] sanitized node name
      def sanitize_node_name(model_name)
        return "unknown_model" unless model_name.is_a?(String) && !model_name.empty?

        # Create a valid node ID by:
        # 1. Replacing :: namespace separators with _
        # 2. Replacing any non-alphanumeric chars with _
        # 3. Ensuring it starts with a letter (mermaid requirement)
        # 4. Adding a prefix if it starts with a number
        node_id = model_name.gsub("::", "_").gsub(/[^a-zA-Z0-9_]/, "_")

        # Ensure node ID starts with a letter (mermaid requirement)
        node_id = "model_#{node_id}" unless node_id.match?(/^[a-zA-Z]/)

        # Ensure node ID is unique by adding a suffix based on the input string
        "#{node_id}_#{model_name.hash.abs.to_s(16).first(4)}"
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
