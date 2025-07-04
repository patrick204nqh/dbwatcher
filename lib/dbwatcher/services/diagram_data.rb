# frozen_string_literal: true

require_relative "diagram_data/entity"
require_relative "diagram_data/relationship"
require_relative "diagram_data/dataset"

module Dbwatcher
  module Services
    # DiagramData module provides standardized data models for diagram generation
    #
    # This module contains the core data structures used to represent diagram
    # entities and relationships in a consistent, validated format that can be
    # consumed by any diagram strategy.
    #
    # @example
    #   # Create entities
    #   user_entity = Dbwatcher::Services::DiagramData::Entity.new(
    #     id: "users", name: "User", type: "table"
    #   )
    #   order_entity = Dbwatcher::Services::DiagramData::Entity.new(
    #     id: "orders", name: "Order", type: "table"
    #   )
    #
    #   # Create relationship
    #   relationship = Dbwatcher::Services::DiagramData::Relationship.new(
    #     source_id: "users", target_id: "orders", type: "has_many"
    #   )
    #
    #   # Create dataset
    #   dataset = Dbwatcher::Services::DiagramData::Dataset.new
    #   dataset.add_entity(user_entity)
    #   dataset.add_entity(order_entity)
    #   dataset.add_relationship(relationship)
    #
    #   # Validate and use
    #   if dataset.valid?
    #     puts dataset.stats
    #   end
    module DiagramData
      # Convenience method to create a new Entity
      #
      # @param args [Hash] entity arguments
      # @return [Entity] new entity instance
      def self.entity(**args)
        Entity.new(**args)
      end

      # Convenience method to create a new Relationship
      #
      # @param args [Hash] relationship arguments
      # @return [Relationship] new relationship instance
      def self.relationship(**args)
        Relationship.new(**args)
      end

      # Convenience method to create a new Dataset
      #
      # @param args [Hash] dataset arguments
      # @return [Dataset] new dataset instance
      def self.dataset(**args)
        Dataset.new(**args)
      end
    end
  end
end
