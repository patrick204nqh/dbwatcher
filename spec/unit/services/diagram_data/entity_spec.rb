# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Services::DiagramData::Entity do
  let(:entity) do
    described_class.new(
      id: "users",
      name: "User",
      type: "table",
      metadata: { columns: %w[id name] }
    )
  end

  describe "#initialize" do
    it "creates entity with required parameters" do
      entity = described_class.new(id: "users", name: "User")
      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("default")
      expect(entity.attributes).to eq([])
      expect(entity.metadata).to eq({})
    end

    it "creates entity with all parameters" do
      attribute = Dbwatcher::Services::DiagramData::Attribute.new(name: "id", type: "integer")
      entity = described_class.new(
        id: "users",
        name: "User",
        type: "table",
        attributes: [attribute],
        metadata: { columns: %w[id name] }
      )

      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
      expect(entity.attributes).to eq([attribute])
      expect(entity.metadata).to eq({ columns: %w[id name] })
    end

    it "converts parameters to strings" do
      entity = described_class.new(id: :users, name: :User, type: :table)
      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
    end

    it "handles non-hash metadata gracefully" do
      entity = described_class.new(id: "users", name: "User", metadata: "invalid")
      expect(entity.metadata).to eq({})
    end
  end

  describe "#valid?" do
    it "returns true for valid entity" do
      expect(entity).to be_valid
    end

    it "returns false when id is blank" do
      entity = described_class.new(id: "", name: "User")
      expect(entity).not_to be_valid
    end

    it "returns false when name is blank" do
      entity = described_class.new(id: "users", name: "")
      expect(entity).not_to be_valid
    end

    it "returns false when type is blank" do
      entity = described_class.new(id: "users", name: "User", type: "")
      expect(entity).not_to be_valid
    end
  end

  describe "#validation_errors" do
    it "returns empty array for valid entity" do
      expect(entity.validation_errors).to be_empty
    end

    it "returns errors for invalid entity" do
      entity = described_class.new(id: "", name: "", type: "")
      expect(entity.validation_errors).to include("ID cannot be blank")
      expect(entity.validation_errors).to include("Name cannot be blank")
      expect(entity.validation_errors).to include("Type cannot be blank")
    end
  end

  describe "#to_h" do
    it "serializes entity to hash" do
      expected = {
        id: "users",
        name: "User",
        type: "table",
        attributes: [],
        metadata: { columns: %w[id name] }
      }

      expect(entity.to_h).to eq(expected)
    end
  end

  describe "#to_json" do
    it "serializes entity to JSON" do
      json = entity.to_json
      expect(json).to be_a(String)
      parsed = JSON.parse(json)
      expect(parsed["id"]).to eq("users")
      expect(parsed["name"]).to eq("User")
      expect(parsed["type"]).to eq("table")
      expect(parsed["metadata"]["columns"]).to eq(%w[id name])
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
      hash = {
        "id" => "users",
        "name" => "User"
      }

      entity = described_class.from_h(hash)
      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("default")
      expect(entity.metadata).to eq({})
    end
  end

  describe ".from_json" do
    it "creates entity from JSON string" do
      json = '{"id":"users","name":"User","type":"table","metadata":{"columns":["id","name"]}}'
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
      entity2 = described_class.new(id: "posts", name: "Post", type: "table")
      expect(entity1).not_to eq(entity2)
    end

    it "returns false for non-entity objects" do
      expect(entity).not_to eq("not an entity")
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
      entity2 = described_class.new(id: "posts", name: "Post", type: "table")
      expect(entity1.hash).not_to eq(entity2.hash)
    end
  end

  describe "#to_s" do
    it "returns readable string representation" do
      expect(entity.to_s).to eq("#{described_class.name}(id: users, name: User, type: table)")
    end
  end

  describe "#inspect" do
    it "returns detailed string representation" do
      expect(entity.inspect).to include('id: "users"')
      expect(entity.inspect).to include('name: "User"')
      expect(entity.inspect).to include('type: "table"')
    end
  end
end
