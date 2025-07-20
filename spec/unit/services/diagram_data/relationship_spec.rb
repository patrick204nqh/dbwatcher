# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Services::DiagramData::Relationship do
  let(:relationship) do
    described_class.new(
      source_id: "users",
      target_id: "orders",
      type: "has_many",
      label: "orders",
      metadata: { cardinality: "1:n" }
    )
  end

  describe "#initialize" do
    it "creates relationship with required parameters" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to be_nil
      expect(relationship.cardinality).to be_nil
      expect(relationship.metadata).to eq({})
    end

    it "creates relationship with all parameters" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        cardinality: "one_to_many",
        metadata: { association_type: "has_many" }
      )

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.cardinality).to eq("one_to_many")
      expect(relationship.metadata).to eq({ association_type: "has_many" })
    end

    it "converts parameters to strings" do
      relationship = described_class.new(
        source_id: :users,
        target_id: :orders,
        type: :has_many,
        label: :orders,
        cardinality: :one_to_many
      )

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.cardinality).to eq("one_to_many")
    end

    it "handles non-hash metadata gracefully" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        metadata: "invalid"
      )

      expect(relationship.metadata).to eq({})
    end
  end

  describe "#valid?" do
    it "returns true for valid relationship" do
      expect(relationship).to be_valid
    end

    it "returns false when source_id is blank" do
      relationship = described_class.new(
        source_id: "",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship).not_to be_valid
    end

    it "returns false when target_id is blank" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "",
        type: "has_many"
      )

      expect(relationship).not_to be_valid
    end

    it "returns false when type is blank" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: ""
      )

      expect(relationship).not_to be_valid
    end

    it "returns false when source and target are the same" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "users",
        type: "has_many"
      )

      expect(relationship).not_to be_valid
    end
  end

  describe "#validation_errors" do
    it "returns empty array for valid relationship" do
      expect(relationship.validation_errors).to be_empty
    end

    it "returns error when source equals target" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "users",
        type: "has_many"
      )

      expect(relationship.validation_errors).to include("Source and target cannot be the same")
    end
  end

  describe "#to_h" do
    it "serializes relationship to hash" do
      expected = {
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        cardinality: nil,
        metadata: { cardinality: "1:n" }
      }

      expect(relationship.to_h).to eq(expected)
    end
  end

  describe "#to_json" do
    it "serializes relationship to JSON" do
      json = relationship.to_json
      parsed = JSON.parse(json)

      expect(parsed["source_id"]).to eq("users")
      expect(parsed["target_id"]).to eq("orders")
      expect(parsed["type"]).to eq("has_many")
      expect(parsed["label"]).to eq("orders")
      expect(parsed["metadata"]["cardinality"]).to eq("1:n")
    end
  end

  describe ".from_h" do
    it "creates relationship from hash with symbol keys" do
      hash = {
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        cardinality: "one_to_many",
        metadata: { association_type: "has_many" }
      }

      relationship = described_class.from_h(hash)
      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.cardinality).to eq("one_to_many")
      expect(relationship.metadata).to eq({ association_type: "has_many" })
    end

    it "creates relationship from hash with string keys" do
      hash = {
        "source_id" => "users",
        "target_id" => "orders",
        "type" => "has_many",
        "label" => "orders",
        "cardinality" => "one_to_many",
        "metadata" => { "association_type" => "has_many" }
      }

      relationship = described_class.from_h(hash)
      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.cardinality).to eq("one_to_many")
      expect(relationship.metadata).to eq({ "association_type" => "has_many" })
    end

    it "handles missing optional fields" do
      hash = {
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      }

      relationship = described_class.from_h(hash)
      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to be_nil
      expect(relationship.cardinality).to be_nil
      expect(relationship.metadata).to eq({})
    end
  end

  describe ".from_json" do
    it "creates relationship from JSON string" do
      json = {
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        cardinality: "one_to_many",
        metadata: { association_type: "has_many" }
      }.to_json

      relationship = described_class.from_json(json)
      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.cardinality).to eq("one_to_many")
      expect(relationship.metadata).to eq({ "association_type" => "has_many" })
    end
  end

  describe "#==" do
    it "returns true for identical relationships" do
      relationship1 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders"
      )
      relationship2 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders"
      )

      expect(relationship1).to eq(relationship2)
    end

    it "returns false for different relationships" do
      relationship1 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )
      relationship2 = described_class.new(
        source_id: "orders",
        target_id: "products",
        type: "belongs_to"
      )

      expect(relationship1).not_to eq(relationship2)
    end

    it "returns false for non-relationship objects" do
      expect(relationship).not_to eq("not a relationship")
    end
  end

  describe "#hash" do
    it "generates consistent hash for same relationship" do
      relationship1 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders"
      )
      relationship2 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders"
      )

      expect(relationship1.hash).to eq(relationship2.hash)
    end

    it "generates different hash for different relationships" do
      relationship1 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )
      relationship2 = described_class.new(
        source_id: "orders",
        target_id: "products",
        type: "belongs_to"
      )

      expect(relationship1.hash).not_to eq(relationship2.hash)
    end
  end

  describe "#inspect" do
    it "returns detailed string representation" do
      result = relationship.inspect

      expect(result).to include("source_id: \"users\"")
      expect(result).to include("target_id: \"orders\"")
      expect(result).to include("type: \"has_many\"")
      expect(result).to include("label: \"orders\"")
      expect(result).to start_with("#{described_class.name}(")
      expect(result).to end_with(")")
    end
  end
end
