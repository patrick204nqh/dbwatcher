# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::DiagramData::BaseEntity do
  describe "#initialize" do
    it "creates entity with required parameters" do
      entity = described_class.new(id: "users", name: "User")

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("default")
      expect(entity.metadata).to eq({})
    end

    it "creates entity with all parameters" do
      metadata = { columns: %w[id name] }
      entity = described_class.new(
        id: "users",
        name: "User",
        type: "table",
        metadata: metadata
      )

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
      expect(entity.metadata).to eq(metadata)
    end

    it "converts parameters to strings" do
      entity = described_class.new(id: 123, name: :user, type: :table)

      expect(entity.id).to eq("123")
      expect(entity.name).to eq("user")
      expect(entity.type).to eq("table")
    end

    it "handles non-hash metadata gracefully" do
      entity = described_class.new(id: "users", name: "User", metadata: "invalid")

      expect(entity.metadata).to eq({})
    end
  end

  describe "#valid?" do
    it "returns true for valid entity" do
      entity = described_class.new(id: "users", name: "User", type: "table")

      expect(entity).to be_valid
    end

    it "returns false when id is blank" do
      entity = described_class.new(id: "", name: "User", type: "table")

      expect(entity).not_to be_valid
    end

    it "returns false when name is blank" do
      entity = described_class.new(id: "users", name: "", type: "table")

      expect(entity).not_to be_valid
    end

    it "returns false when type is blank" do
      entity = described_class.new(id: "users", name: "User", type: "")

      expect(entity).not_to be_valid
    end
  end

  describe "#validation_errors" do
    it "returns empty array for valid entity" do
      entity = described_class.new(id: "users", name: "User", type: "table")

      expect(entity.validation_errors).to be_empty
    end

    it "returns errors for invalid entity" do
      entity = described_class.new(id: "", name: "", type: "")
      # Manually set invalid metadata to test validation
      entity.metadata = "invalid"

      errors = entity.validation_errors
      expect(errors).to include("ID cannot be blank")
      expect(errors).to include("Name cannot be blank")
      expect(errors).to include("Type cannot be blank")
      expect(errors).to include("Metadata must be a Hash")
    end
  end

  describe "#to_h" do
    it "serializes entity to hash" do
      metadata = { columns: %w[id name] }
      entity = described_class.new(
        id: "users",
        name: "User",
        type: "table",
        metadata: metadata
      )

      expected = {
        id: "users",
        name: "User",
        type: "table",
        metadata: metadata
      }

      expect(entity.to_h).to eq(expected)
    end
  end

  describe "#to_json" do
    it "serializes entity to JSON" do
      entity = described_class.new(id: "users", name: "User", type: "table")

      json = entity.to_json
      parsed = JSON.parse(json)

      expect(parsed["id"]).to eq("users")
      expect(parsed["name"]).to eq("User")
      expect(parsed["type"]).to eq("table")
      expect(parsed["metadata"]).to eq({})
    end
  end

  describe ".from_h" do
    it "creates entity from hash with symbol keys" do
      hash = {
        id: "users",
        name: "User",
        type: "table",
        metadata: { columns: %w[id name] }
      }

      entity = described_class.from_h(hash)

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
      expect(entity.metadata).to eq({ columns: %w[id name] })
    end

    it "creates entity from hash with string keys" do
      hash = {
        "id" => "users",
        "name" => "User",
        "type" => "table",
        "metadata" => { "columns" => %w[id name] }
      }

      entity = described_class.from_h(hash)

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
      expect(entity.metadata).to eq({ "columns" => %w[id name] })
    end

    it "handles missing optional fields" do
      hash = { id: "users", name: "User" }

      entity = described_class.from_h(hash)

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("default")
      expect(entity.metadata).to eq({})
    end
  end

  describe ".from_json" do
    it "creates entity from JSON string" do
      json = {
        id: "users",
        name: "User",
        type: "table",
        metadata: { columns: %w[id name] }
      }.to_json

      entity = described_class.from_json(json)

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
      expect(entity.metadata).to eq({ "columns" => %w[id name] })
    end
  end

  describe "#==" do
    it "returns true for identical entities" do
      entity1 = described_class.new(id: "users", name: "User", type: "table")
      entity2 = described_class.new(id: "users", name: "User", type: "table")

      expect(entity1).to eq(entity2)
    end

    it "returns false for different entities" do
      entity1 = described_class.new(id: "users", name: "User", type: "table")
      entity2 = described_class.new(id: "orders", name: "Order", type: "table")

      expect(entity1).not_to eq(entity2)
    end

    it "returns false for non-entity objects" do
      entity = described_class.new(id: "users", name: "User", type: "table")

      expect(entity).not_to eq("not an entity")
      expect(entity).not_to eq(nil)
    end
  end

  describe "#hash" do
    it "generates consistent hash for same entity" do
      entity1 = described_class.new(id: "users", name: "User", type: "table")
      entity2 = described_class.new(id: "users", name: "User", type: "table")

      expect(entity1.hash).to eq(entity2.hash)
    end

    it "generates different hash for different entities" do
      entity1 = described_class.new(id: "users", name: "User", type: "table")
      entity2 = described_class.new(id: "orders", name: "Order", type: "table")

      expect(entity1.hash).not_to eq(entity2.hash)
    end
  end

  describe "#to_s" do
    it "returns readable string representation" do
      entity = described_class.new(id: "users", name: "User", type: "table")

      expected = "#{described_class.name}(id: users, name: User, type: table)"
      expect(entity.to_s).to eq(expected)
    end
  end

  describe "#inspect" do
    it "returns detailed string representation" do
      entity = described_class.new(id: "users", name: "User", type: "table")

      result = entity.inspect
      expect(result).to include(described_class.name)
      expect(result).to include('id: "users"')
      expect(result).to include('name: "User"')
      expect(result).to include('type: "table"')
      expect(result).to include("metadata: {}")
    end
  end
end
