# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::DiagramData do
  describe ".entity" do
    it "creates a new Entity instance" do
      entity = described_class.entity(id: "users", name: "User", type: "table")

      expect(entity).to be_a(Dbwatcher::Services::DiagramData::Entity)
      expect(entity.id).to eq("users")
      expect(entity.name).to eq("User")
      expect(entity.type).to eq("table")
    end
  end

  describe ".relationship" do
    it "creates a new Relationship instance" do
      relationship = described_class.relationship(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship).to be_a(Dbwatcher::Services::DiagramData::Relationship)
      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
    end
  end

  describe ".dataset" do
    it "creates a new Dataset instance" do
      dataset = described_class.dataset(metadata: { created_by: "test" })

      expect(dataset).to be_a(Dbwatcher::Services::DiagramData::Dataset)
      expect(dataset.metadata).to eq({ created_by: "test" })
    end

    it "creates empty dataset when no arguments provided" do
      dataset = described_class.dataset

      expect(dataset).to be_a(Dbwatcher::Services::DiagramData::Dataset)
      expect(dataset.entities).to be_empty
      expect(dataset.relationships).to be_empty
      expect(dataset.metadata).to eq({})
    end
  end
end
