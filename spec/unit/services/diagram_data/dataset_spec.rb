# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::DiagramData::Dataset do
  let(:user_entity) do
    Dbwatcher::Services::DiagramData::Entity.new(
      id: "users",
      name: "User",
      type: "table"
    )
  end

  let(:order_entity) do
    Dbwatcher::Services::DiagramData::Entity.new(
      id: "orders",
      name: "Order",
      type: "table"
    )
  end

  let(:valid_relationship) do
    Dbwatcher::Services::DiagramData::Relationship.new(
      source_id: "users",
      target_id: "orders",
      type: "has_many"
    )
  end

  describe "#initialize" do
    it "creates empty dataset with default metadata" do
      dataset = described_class.new

      expect(dataset.entities).to be_empty
      expect(dataset.relationships).to be_empty
      expect(dataset.metadata).to eq({})
    end

    it "creates dataset with custom metadata" do
      metadata = { created_by: "test" }
      dataset = described_class.new(metadata: metadata)

      expect(dataset.metadata).to eq(metadata)
    end

    it "handles non-hash metadata gracefully" do
      dataset = described_class.new(metadata: "invalid")

      expect(dataset.metadata).to eq({})
    end
  end

  describe "#add_entity" do
    let(:dataset) { described_class.new }

    it "adds valid entity to dataset" do
      result = dataset.add_entity(user_entity)

      expect(result).to eq(user_entity)
      expect(dataset.entities["users"]).to eq(user_entity)
    end

    it "raises error for non-entity object" do
      expect do
        dataset.add_entity("not an entity")
      end.to raise_error(ArgumentError, "Entity must be an Entity instance")
    end

    it "raises error for invalid entity" do
      invalid_entity = Dbwatcher::Services::DiagramData::Entity.new(
        id: "",
        name: "Invalid"
      )

      expect do
        dataset.add_entity(invalid_entity)
      end.to raise_error(ArgumentError, /Entity is invalid/)
    end

    it "overwrites entity with same ID" do
      dataset.add_entity(user_entity)

      updated_entity = Dbwatcher::Services::DiagramData::Entity.new(
        id: "users",
        name: "Updated User",
        type: "table"
      )

      dataset.add_entity(updated_entity)
      expect(dataset.entities["users"].name).to eq("Updated User")
    end
  end

  describe "#add_relationship" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
    end

    it "adds valid relationship to dataset" do
      result = dataset.add_relationship(valid_relationship)

      expect(result).to eq(valid_relationship)
      expect(dataset.relationships).to include(valid_relationship)
    end

    it "raises error for non-relationship object" do
      expect do
        dataset.add_relationship("not a relationship")
      end.to raise_error(ArgumentError, "Relationship must be a Relationship instance")
    end

    it "raises error for invalid relationship" do
      invalid_relationship = Dbwatcher::Services::DiagramData::Relationship.new(
        source_id: "",
        target_id: "orders",
        type: "has_many"
      )

      expect do
        dataset.add_relationship(invalid_relationship)
      end.to raise_error(ArgumentError, /Relationship is invalid/)
    end
  end

  describe "#get_entity" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
    end

    it "returns entity by ID" do
      result = dataset.get_entity("users")

      expect(result).to eq(user_entity)
    end

    it "returns nil for non-existent entity" do
      result = dataset.get_entity("non_existent")

      expect(result).to be_nil
    end

    it "converts ID to string" do
      result = dataset.get_entity(:users)

      expect(result).to eq(user_entity)
    end
  end

  describe "#entity?" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
    end

    it "returns true for existing entity" do
      expect(dataset.entity?("users")).to be true
    end

    it "returns false for non-existent entity" do
      expect(dataset.entity?("non_existent")).to be false
    end
  end

  describe "#remove_entity" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "removes entity and returns it" do
      result = dataset.remove_entity("users")

      expect(result).to eq(user_entity)
      expect(dataset.entity?("users")).to be false
    end

    it "removes relationships involving removed entity" do
      dataset.remove_entity("users")

      expect(dataset.relationships).to be_empty
    end

    it "returns nil for non-existent entity" do
      result = dataset.remove_entity("non_existent")

      expect(result).to be_nil
    end
  end

  describe "#remove_relationship" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "removes relationship and returns true" do
      result = dataset.remove_relationship(valid_relationship)

      expect(result).to be true
      expect(dataset.relationships).not_to include(valid_relationship)
    end

    it "returns false for non-existent relationship" do
      other_relationship = Dbwatcher::Services::DiagramData::Relationship.new(
        source_id: "orders",
        target_id: "users",
        type: "belongs_to"
      )

      result = dataset.remove_relationship(other_relationship)

      expect(result).to be false
    end
  end

  describe "#relationships_for" do
    let(:dataset) { described_class.new }
    let(:product_entity) do
      Dbwatcher::Services::DiagramData::Entity.new(
        id: "products",
        name: "Product",
        type: "table"
      )
    end
    let(:order_product_relationship) do
      Dbwatcher::Services::DiagramData::Relationship.new(
        source_id: "orders",
        target_id: "products",
        type: "has_many"
      )
    end

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_entity(product_entity)
      dataset.add_relationship(valid_relationship)
      dataset.add_relationship(order_product_relationship)
    end

    it "returns all relationships for entity by default" do
      relationships = dataset.relationships_for("orders")

      expect(relationships).to include(valid_relationship)
      expect(relationships).to include(order_product_relationship)
    end

    it "returns outgoing relationships only" do
      relationships = dataset.relationships_for("orders", direction: :outgoing)

      expect(relationships).to include(order_product_relationship)
      expect(relationships).not_to include(valid_relationship)
    end

    it "returns incoming relationships only" do
      relationships = dataset.relationships_for("orders", direction: :incoming)

      expect(relationships).to include(valid_relationship)
      expect(relationships).not_to include(order_product_relationship)
    end

    it "raises error for invalid direction" do
      expect do
        dataset.relationships_for("orders", direction: :invalid)
      end.to raise_error(ArgumentError, "Direction must be :outgoing, :incoming, or :all")
    end
  end

  describe "#valid?" do
    let(:dataset) { described_class.new }

    it "returns true for valid dataset" do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)

      expect(dataset).to be_valid
    end

    it "returns false when entity is invalid" do
      invalid_entity = Dbwatcher::Services::DiagramData::Entity.new(
        id: "",
        name: "Invalid"
      )
      dataset.instance_variable_get(:@entities)["invalid"] = invalid_entity

      expect(dataset).not_to be_valid
    end

    it "returns false when relationship references non-existent entity" do
      dataset.add_entity(user_entity)
      dataset.instance_variable_get(:@relationships) << valid_relationship

      expect(dataset).not_to be_valid
    end
  end

  describe "#validation_errors" do
    let(:dataset) { described_class.new }

    it "returns empty array for valid dataset" do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)

      expect(dataset.validation_errors).to be_empty
    end

    it "returns errors for invalid entities" do
      invalid_entity = Dbwatcher::Services::DiagramData::Entity.new(
        id: "",
        name: "Invalid"
      )
      dataset.instance_variable_get(:@entities)["invalid"] = invalid_entity

      errors = dataset.validation_errors
      expect(errors).to include(/Entity invalid is invalid/)
    end

    it "returns errors for relationships with non-existent entities" do
      dataset.add_entity(user_entity)
      dataset.instance_variable_get(:@relationships) << valid_relationship

      errors = dataset.validation_errors
      expect(errors).to include(/references non-existent target entity/)
    end
  end

  describe "#stats" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "returns dataset statistics" do
      stats = dataset.stats

      expect(stats[:entity_count]).to eq(2)
      expect(stats[:relationship_count]).to eq(1)
      expect(stats[:entity_types]).to eq(["table"])
      expect(stats[:relationship_types]).to eq(["has_many"])
      expect(stats[:isolated_entities]).to be_empty
      expect(stats[:connected_entities]).to eq(%w[users orders])
    end
  end

  describe "#isolated_entities" do
    let(:dataset) { described_class.new }
    let(:isolated_entity) do
      Dbwatcher::Services::DiagramData::Entity.new(
        id: "isolated",
        name: "Isolated",
        type: "table"
      )
    end

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_entity(isolated_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "returns entities with no relationships" do
      isolated = dataset.isolated_entities

      expect(isolated).to include(isolated_entity)
      expect(isolated).not_to include(user_entity)
      expect(isolated).not_to include(order_entity)
    end
  end

  describe "#connected_entities" do
    let(:dataset) { described_class.new }
    let(:isolated_entity) do
      Dbwatcher::Services::DiagramData::Entity.new(
        id: "isolated",
        name: "Isolated",
        type: "table"
      )
    end

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_entity(isolated_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "returns entities with at least one relationship" do
      connected = dataset.connected_entities

      expect(connected).to include(user_entity)
      expect(connected).to include(order_entity)
      expect(connected).not_to include(isolated_entity)
    end
  end

  describe "#empty?" do
    it "returns true for empty dataset" do
      dataset = described_class.new

      expect(dataset).to be_empty
    end

    it "returns false for dataset with entities" do
      dataset = described_class.new
      dataset.add_entity(user_entity)

      expect(dataset).not_to be_empty
    end

    it "returns false for dataset with relationships" do
      dataset = described_class.new
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)
      dataset.remove_entity("users")
      dataset.remove_entity("orders")

      # Should be empty after removing entities (which removes relationships)
      expect(dataset).to be_empty
    end
  end

  describe "#clear" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "clears all data and returns self" do
      result = dataset.clear

      expect(result).to eq(dataset)
      expect(dataset.entities).to be_empty
      expect(dataset.relationships).to be_empty
      expect(dataset.metadata).to be_empty
    end
  end

  describe "#to_h" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_entity(order_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "serializes dataset to hash" do
      hash = dataset.to_h

      expect(hash[:entities]).to have_key("users")
      expect(hash[:entities]).to have_key("orders")
      expect(hash[:relationships].size).to eq(1)
      expect(hash[:metadata]).to eq({})
      expect(hash[:stats]).to be_a(Hash)
    end
  end

  describe "#to_json" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
    end

    it "serializes dataset to JSON" do
      json = dataset.to_json
      parsed = JSON.parse(json)

      expect(parsed["entities"]).to have_key("users")
      expect(parsed["relationships"]).to be_an(Array)
      expect(parsed["metadata"]).to be_a(Hash)
      expect(parsed["stats"]).to be_a(Hash)
    end
  end

  describe ".from_h" do
    let(:hash) do
      {
        entities: {
          "users" => {
            id: "users",
            name: "User",
            type: "table",
            metadata: {}
          }
        },
        relationships: [
          {
            source_id: "users",
            target_id: "orders",
            type: "has_many",
            label: nil,
            metadata: {}
          }
        ],
        metadata: { created_by: "test" }
      }
    end

    it "creates dataset from hash" do
      dataset = described_class.from_h(hash)

      expect(dataset.entities).to have_key("users")
      expect(dataset.relationships.size).to eq(1)
      expect(dataset.metadata).to eq({ created_by: "test" })
    end

    it "handles missing sections gracefully" do
      minimal_hash = { metadata: { test: true } }
      dataset = described_class.from_h(minimal_hash)

      expect(dataset.entities).to be_empty
      expect(dataset.relationships).to be_empty
      expect(dataset.metadata).to eq({ test: true })
    end
  end

  describe ".from_json" do
    it "creates dataset from JSON string" do
      hash = {
        entities: {
          "users" => {
            id: "users",
            name: "User",
            type: "table",
            metadata: {}
          }
        },
        relationships: [],
        metadata: {}
      }

      dataset = described_class.from_json(hash.to_json)

      expect(dataset.entities).to have_key("users")
    end
  end

  describe "#to_s" do
    let(:dataset) { described_class.new }

    before do
      dataset.add_entity(user_entity)
      dataset.add_relationship(valid_relationship)
    end

    it "returns readable string representation" do
      result = dataset.to_s

      expected = "#{described_class.name}(entities: 1, relationships: 1)"
      expect(result).to eq(expected)
    end
  end

  describe "#inspect" do
    let(:dataset) { described_class.new }

    it "returns detailed string representation" do
      result = dataset.inspect

      expect(result).to include(described_class.name)
      expect(result).to include("entities: 0")
      expect(result).to include("relationships: 0")
      expect(result).to include("metadata: {}")
    end
  end
end
