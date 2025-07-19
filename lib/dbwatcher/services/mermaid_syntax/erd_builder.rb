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

        # Format attribute definition for ERD
        #
        # @param attr [DiagramData::Attribute] attribute to format
        # @return [String] formatted attribute line
        def format_attribute_line(attr)
          type = attr.type.to_s.empty? ? "any" : attr.type
          key_suffix = ""
          key_suffix += " PK" if attr.primary_key?
          key_suffix += " FK" if attr.foreign_key? && !attr.primary_key?

          "        #{type} #{attr.name}#{key_suffix}"
        end

        # Build entity definition
        #
        # @param entity [DiagramData::Entity] entity to render
        # @return [Array<String>] entity definition lines
        def build_erd_entity(entity)
          table_name = Sanitizer.table_name(entity.name)
          lines = ["    #{table_name} {"]

          # Add attributes if enabled and available
          if show_attributes? && entity.attributes.any?
            entity.attributes.first(max_attributes).each do |attr|
              lines << format_attribute_line(attr)
            end
          end

          lines << "    }"
          lines << ""
          lines
        end

        # Format entity name for ERD
        #
        # @param entity_id [String] entity ID
        # @param dataset [DiagramData::Dataset] dataset for entity lookup
        # @return [String] formatted entity name
        def format_entity_name(entity_id, dataset)
          entity_name = dataset.get_entity(entity_id)&.name || entity_id
          Sanitizer.table_name(entity_name)
        end

        # Build relationship definition
        #
        # @param relationship [DiagramData::Relationship] relationship to render
        # @param dataset [DiagramData::Dataset] full dataset for context
        # @return [String] relationship definition line
        def build_erd_relationship(relationship, dataset)
          source = format_entity_name(relationship.source_id, dataset)
          target = format_entity_name(relationship.target_id, dataset)

          label = Sanitizer.label(relationship.label)
          cardinality = CardinalityMapper.to_erd(relationship.cardinality, cardinality_format)

          # In Mermaid ERD syntax, relationship labels must be quoted
          "    #{source} #{cardinality} #{target} : \"#{label}\""
        end
      end
    end
  end
end
