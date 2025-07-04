# frozen_string_literal: true

module Dbwatcher
  module Services
    module MermaidSyntax
      # Builder for Entity Relationship Diagrams in Mermaid syntax
      #
      # Generates Mermaid ERD syntax from a standardized dataset with
      # support for attributes and relationships with cardinality.
      #
      # @example
      #   builder = ErdBuilder.new(show_attributes: true)
      #   content = builder.build_from_dataset(dataset)
      #   # => "erDiagram\n    USER {\n        int id PK\n    }\n    USER ||--o{ ORDER : \"has_many\""
      class ErdBuilder < BaseBuilder
        # Build ERD content from dataset
        #
        # @param dataset [DiagramData::Dataset] dataset to render
        # @return [String] Mermaid ERD content
        def build_from_dataset(dataset)
          lines = ["erDiagram"]

          # Add entity definitions with attributes
          dataset.entities.each_value do |entity|
            lines += build_erd_entity(entity)
          end

          # Add relationships
          unless dataset.relationships.empty?
            lines << ""
            dataset.relationships.each do |relationship|
              lines << build_erd_relationship(relationship, dataset)
            end
          end

          lines.join("\n")
        end

        # Build empty ERD with message
        #
        # @param message [String] message to display
        # @return [String] Mermaid ERD content
        def build_empty(message)
          sanitized_message = sanitize_text(message)
          [
            "erDiagram",
            "    EMPTY_STATE {",
            "        string message \"#{sanitized_message}\"",
            "    }"
          ].join("\n")
        end

        private

        # Build entity definition
        #
        # @param entity [DiagramData::Entity] entity to render
        # @return [Array<String>] entity definition lines
        def build_erd_entity(entity)
          table_name = Sanitizer.table_name(entity.name, preserve_table_case?)
          lines = ["    #{table_name} {"]

          # Add attributes if enabled and available
          if show_attributes? && entity.attributes.any?
            entity.attributes.first(max_attributes).each do |attr|
              type = attr.type.to_s.empty? ? "any" : attr.type
              key_suffix = ""
              key_suffix += " PK" if attr.primary_key?
              key_suffix += " FK" if attr.foreign_key? && !attr.primary_key?

              lines << "        #{type} #{attr.name}#{key_suffix}"
            end
          end

          lines << "    }"
          lines << ""
          lines
        end

        # Build relationship definition
        #
        # @param relationship [DiagramData::Relationship] relationship to render
        # @param dataset [DiagramData::Dataset] full dataset for context
        # @return [String] relationship definition line
        def build_erd_relationship(relationship, dataset)
          source = Sanitizer.table_name(
            dataset.get_entity(relationship.source_id)&.name || relationship.source_id,
            preserve_table_case?
          )

          target = Sanitizer.table_name(
            dataset.get_entity(relationship.target_id)&.name || relationship.target_id,
            preserve_table_case?
          )

          label = Sanitizer.label(relationship.label)
          cardinality = CardinalityMapper.to_erd(relationship.cardinality, cardinality_format)

          # In Mermaid ERD syntax, relationship labels must be quoted
          "    #{source} #{cardinality} #{target} : \"#{label}\""
        end
      end
    end
  end
end
