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
          # Map cardinality to ERD diagram syntax
          #
          # @param cardinality [String, Symbol] internal cardinality representation
          # @param format [Symbol] cardinality format (:standard or :simple)
          # @return [String] ERD cardinality notation
          def to_erd(cardinality, format = :standard)
            # ERD format doesn't change based on format parameter
            # It always uses the standard Mermaid ERD notation
            case cardinality.to_s
            when "one_to_many"
              "||--o{"
            when "many_to_one"
              "}o--||"
            when "one_to_one"
              "||--||"
            when "many_to_many"
              "}o--o{"
            when "zero_or_one_to_many"
              "|o--o{"
            when "one_to_zero_or_many"
              "||--o{"
            when "zero_or_one_to_one"
              "|o--||"
            when "one_to_zero_or_one"
              "||--|o"
            else
              "||--o{" # Default to one-to-many
            end
          end

          # Map cardinality to class diagram syntax
          #
          # @param cardinality [String, Symbol] internal cardinality representation
          # @param format [Symbol] cardinality format (:standard or :simple)
          # @return [String] class diagram cardinality notation
          def to_class(cardinality, format = :standard)
            if format == :simple
              to_simple(cardinality)
            else
              case cardinality.to_s
              when "one_to_many"
                "1..*"
              when "many_to_one"
                "*..*"
              when "one_to_one"
                "1..1"
              when "many_to_many"
                "*..*"
              when "zero_or_one_to_many"
                "0..1..*"
              when "one_to_zero_or_many"
                "1..0..*"
              when "zero_or_one_to_one"
                "0..1..1"
              when "one_to_zero_or_one"
                "1..0..1"
              else
                "1..*" # Default to one-to-many
              end
            end
          end

          # Map cardinality to simple text format
          #
          # @param cardinality [String, Symbol] internal cardinality representation
          # @param format [Symbol] cardinality format (:standard or :simple)
          # @return [String] simple cardinality notation
          def to_simple(cardinality, format = :standard)
            case cardinality.to_s
            when "one_to_many"
              "1:N"
            when "many_to_one"
              "N:1"
            when "one_to_one"
              "1:1"
            when "many_to_many"
              "N:N"
            when "zero_or_one_to_many"
              "0,1:N"
            when "one_to_zero_or_many"
              "1:0,N"
            when "zero_or_one_to_one"
              "0,1:1"
            when "one_to_zero_or_one"
              "1:0,1"
            else
              "1:N" # Default to one-to-many
            end
          end
        end
      end
    end
  end
end
