# frozen_string_literal: true

module Dbwatcher
  module Services
    module MermaidSyntax
      # Maps relationship cardinality to Mermaid syntax
      #
      # Provides mapping from internal cardinality representation to
      # specific Mermaid diagram syntax for different diagram types.
      #
      # @example
      #   CardinalityMapper.to_erd("one_to_many") # => "||--o{"
      #   CardinalityMapper.to_class("one_to_many") # => "1..*"
      #   CardinalityMapper.to_simple("one_to_many") # => "1:N"
      class CardinalityMapper
        class << self
          # Default cardinality notation
          DEFAULT_ERD = "||--o{" # Default to one-to-many
          DEFAULT_CLASS = "1..*" # Default to one-to-many
          DEFAULT_SIMPLE = "1:N" # Default to one-to-many

          # Lookup tables for different cardinality notations
          ERD_NOTATIONS = {
            "one_to_many" => "||--o{",
            "one_to_zero_or_many" => "||--o{",
            "many_to_one" => "}o--||",
            "one_to_one" => "||--||",
            "many_to_many" => "}o--o{",
            "zero_or_one_to_many" => "|o--o{",
            "zero_or_one_to_one" => "|o--||",
            "one_to_zero_or_one" => "||--|o"
          }.freeze

          CLASS_NOTATIONS = {
            "one_to_many" => "1..*",
            "many_to_one" => "*..*",
            "many_to_many" => "*..*",
            "one_to_one" => "1..1",
            "zero_or_one_to_many" => "0..1..*",
            "one_to_zero_or_many" => "1..0..*",
            "zero_or_one_to_one" => "0..1..1",
            "one_to_zero_or_one" => "1..0..1"
          }.freeze

          SIMPLE_NOTATIONS = {
            "one_to_many" => "1:N",
            "many_to_one" => "N:1",
            "one_to_one" => "1:1",
            "many_to_many" => "N:N",
            "zero_or_one_to_many" => "0,1:N",
            "one_to_zero_or_many" => "1:0,N",
            "zero_or_one_to_one" => "0,1:1",
            "one_to_zero_or_one" => "1:0,1"
          }.freeze

          # Map cardinality to ERD diagram syntax
          #
          # @param cardinality [String, Symbol] internal cardinality representation
          # @param _format [Symbol] cardinality format (not used for ERD)
          # @return [String] ERD cardinality notation
          def to_erd(cardinality, _format = :standard)
            # ERD format doesn't change based on format parameter
            # It always uses the standard Mermaid ERD notation
            ERD_NOTATIONS[cardinality.to_s] || DEFAULT_ERD
          end

          # Map cardinality to class diagram syntax
          #
          # @param cardinality [String, Symbol] internal cardinality representation
          # @param format [Symbol] cardinality format (:standard or :simple)
          # @return [String] class diagram cardinality notation
          def to_class(cardinality, format = :standard)
            return to_simple(cardinality) if format == :simple

            CLASS_NOTATIONS[cardinality.to_s] || DEFAULT_CLASS
          end

          # Map cardinality to simple text format
          #
          # @param cardinality [String, Symbol] internal cardinality representation
          # @param _format [Symbol] cardinality format (not used for simple format)
          # @return [String] simple cardinality notation
          def to_simple(cardinality, _format = :standard)
            SIMPLE_NOTATIONS[cardinality.to_s] || DEFAULT_SIMPLE
          end
        end
      end
    end
  end
end
