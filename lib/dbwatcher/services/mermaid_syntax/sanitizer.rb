# frozen_string_literal: true

module Dbwatcher
  module Services
    module MermaidSyntax
      # Utility class for sanitizing names and labels for Mermaid syntax
      #
      # Provides methods to sanitize various types of identifiers for use
      # in Mermaid diagrams, ensuring valid syntax.
      class Sanitizer
        class << self
          # Sanitize class name for Mermaid class diagrams
          #
          # @param name [String] raw class name
          # @return [String] sanitized class name
          def class_name(name)
            return "UnknownClass" unless name.is_a?(String) && !name.empty?

            # For namespaced models, preserve the namespace structure
            # Convert :: to underscore for Mermaid syntax while maintaining readability
            sanitized = name.to_s.gsub("::", "__")

            # Only replace other special characters with underscores
            sanitized.gsub(/[^a-zA-Z0-9_]/, "_")
          end

          # Sanitize node name for Mermaid flowcharts
          #
          # @param name [String] raw node name
          # @return [String] sanitized node name
          def node_name(name)
            return "unknown_node" unless name.is_a?(String) && !name.empty?

            name.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
          end

          # Sanitize node ID for Mermaid flowcharts
          #
          # @param name [String] raw node name
          # @return [String] sanitized node ID
          def node_id(name)
            return "unknown_node" unless name.is_a?(String) && !name.empty?

            # Node IDs in flowcharts must be valid identifiers
            name.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
          end

          # Sanitize table name for Mermaid ERD
          #
          # @param name [String] raw table name
          # @param preserve_case [Boolean] whether to preserve original case
          # @return [String] sanitized table name
          def table_name(name, preserve_case = nil)
            return "UNKNOWN_TABLE" unless name.is_a?(String) && !name.empty?

            preserve = if preserve_case.nil?
                         Dbwatcher.configuration.diagram_preserve_table_case
                       else
                         preserve_case
                       end

            if preserve
              name.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
            else
              name.to_s.upcase.gsub(/[^A-Z0-9_]/, "_")
            end
          end

          # Sanitize method name for Mermaid class diagrams
          #
          # @param name [String] raw method name
          # @return [String] sanitized method name
          def method_name(name)
            return "unknown_method()" unless name.is_a?(String) && !name.empty?

            # Ensure method name ends with parentheses
            method = name.to_s.gsub(/[^a-zA-Z0-9_()]/, "_")
            method += "()" unless method.include?("(")
            method
          end

          # Sanitize relationship label for Mermaid diagrams
          #
          # @param label [String] raw label
          # @return [String] sanitized label
          def label(label)
            return "" unless label.is_a?(String) && !label.empty?

            # For Mermaid, we need to escape quotes but not remove them completely
            # We'll escape backslashes and double quotes, and replace newlines with spaces
            label.to_s.gsub("\\", "\\\\").gsub('"', '\\"').gsub(/[\n\r]/, " ").strip
          end

          # Get display name for class (preserves namespace format for labels)
          #
          # @param name [String] raw class name
          # @return [String] display name with proper namespace format
          def display_name(name)
            return "UnknownClass" unless name.is_a?(String) && !name.empty?

            # Return the original name for display purposes (preserves :: for namespaces)
            name.to_s
          end

          # Sanitize attribute type for Mermaid ERD
          #
          # @param type [String] raw attribute type
          # @return [String] sanitized attribute type
          def attribute_type(type)
            return "string" unless type.is_a?(String) && !type.empty?

            type.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
          end
        end
      end
    end
  end
end
