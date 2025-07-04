# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Relationship with Cardinality" do
  let(:relationship_class) { Dbwatcher::Services::DiagramData::Relationship }

  describe "#initialize with cardinality" do
    it "creates relationship with cardinality" do
      relationship = relationship_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        cardinality: "one_to_many"
      )

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.cardinality).to eq("one_to_many")
    end

    it "defaults to nil cardinality" do
      relationship = relationship_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship.cardinality).to be_nil
    end

    it "converts cardinality to string" do
      relationship = relationship_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        cardinality: :one_to_many
      )

      expect(relationship.cardinality).to eq("one_to_many")
    end
  end

  describe "#to_h with cardinality" do
    it "includes cardinality in serialized hash" do
      relationship = relationship_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        cardinality: "one_to_many"
      )

      hash = relationship.to_h

      expect(hash[:cardinality]).to eq("one_to_many")
    end
  end

  describe ".from_h with cardinality" do
    it "deserializes relationship with cardinality" do
      hash = {
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        cardinality: "one_to_many"
      }

      relationship = relationship_class.from_h(hash)

      expect(relationship.cardinality).to eq("one_to_many")
    end
  end
end
