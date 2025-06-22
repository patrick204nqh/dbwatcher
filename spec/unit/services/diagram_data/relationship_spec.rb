# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::DiagramData::Relationship do
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
      expect(relationship.metadata).to eq({})
    end

    it "creates relationship with all parameters" do
      metadata = { cardinality: "1:n" }
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        metadata: metadata
      )

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.metadata).to eq(metadata)
    end

    it "converts parameters to strings" do
      relationship = described_class.new(
        source_id: 123,
        target_id: 456,
        type: :has_many,
        label: :orders
      )

      expect(relationship.source_id).to eq("123")
      expect(relationship.target_id).to eq("456")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
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
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

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
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship.validation_errors).to be_empty
    end

    it "returns errors for invalid relationship" do
      relationship = described_class.new(
        source_id: "",
        target_id: "",
        type: ""
      )
      # Manually set invalid metadata to test validation
      relationship.metadata = "invalid"

      errors = relationship.validation_errors
      expect(errors).to include("Source ID cannot be blank")
      expect(errors).to include("Target ID cannot be blank")
      expect(errors).to include("Type cannot be blank")
      expect(errors).to include("Metadata must be a Hash")
    end

    it "returns error when source equals target" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "users",
        type: "has_many"
      )

      errors = relationship.validation_errors
      expect(errors).to include("Source and target cannot be the same")
    end
  end

  describe "#to_h" do
    it "serializes relationship to hash" do
      metadata = { cardinality: "1:n" }
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        metadata: metadata
      )

      expected = {
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        metadata: metadata
      }

      expect(relationship.to_h).to eq(expected)
    end
  end

  describe "#to_json" do
    it "serializes relationship to JSON" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      json = relationship.to_json
      parsed = JSON.parse(json)

      expect(parsed["source_id"]).to eq("users")
      expect(parsed["target_id"]).to eq("orders")
      expect(parsed["type"]).to eq("has_many")
      expect(parsed["label"]).to be_nil
      expect(parsed["metadata"]).to eq({})
    end
  end

  describe ".from_h" do
    it "creates relationship from hash with symbol keys" do
      hash = {
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        metadata: { cardinality: "1:n" }
      }

      relationship = described_class.from_h(hash)

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.metadata).to eq({ cardinality: "1:n" })
    end

    it "creates relationship from hash with string keys" do
      hash = {
        "source_id" => "users",
        "target_id" => "orders",
        "type" => "has_many",
        "label" => "orders",
        "metadata" => { "cardinality" => "1:n" }
      }

      relationship = described_class.from_h(hash)

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.metadata).to eq({ "cardinality" => "1:n" })
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
        metadata: { cardinality: "1:n" }
      }.to_json

      relationship = described_class.from_json(json)

      expect(relationship.source_id).to eq("users")
      expect(relationship.target_id).to eq("orders")
      expect(relationship.type).to eq("has_many")
      expect(relationship.label).to eq("orders")
      expect(relationship.metadata).to eq({ "cardinality" => "1:n" })
    end
  end

  describe "#==" do
    it "returns true for identical relationships" do
      relationship1 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )
      relationship2 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
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
        target_id: "users",
        type: "belongs_to"
      )

      expect(relationship1).not_to eq(relationship2)
    end

    it "returns false for non-relationship objects" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship).not_to eq("not a relationship")
      expect(relationship).not_to eq(nil)
    end
  end

  describe "#hash" do
    it "generates consistent hash for same relationship" do
      relationship1 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )
      relationship2 = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
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
        target_id: "users",
        type: "belongs_to"
      )

      expect(relationship1.hash).not_to eq(relationship2.hash)
    end
  end

  describe "#bidirectional?" do
    it "returns true when metadata indicates bidirectional" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        metadata: { bidirectional: true }
      )

      expect(relationship).to be_bidirectional
    end

    it "returns false when metadata does not indicate bidirectional" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expect(relationship).not_to be_bidirectional
    end
  end

  describe "#reverse" do
    it "creates reverse relationship with swapped source and target" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders",
        metadata: { cardinality: "1:n" }
      )

      reverse = relationship.reverse

      expect(reverse.source_id).to eq("orders")
      expect(reverse.target_id).to eq("users")
      expect(reverse.type).to eq("belongs_to")
      expect(reverse.label).to be_nil
      expect(reverse.metadata[:reversed]).to be true
    end

    it "maps relationship types correctly" do
      mappings = {
        "has_many" => "belongs_to",
        "belongs_to" => "has_many",
        "has_one" => "belongs_to",
        "has_and_belongs_to_many" => "has_and_belongs_to_many"
      }

      mappings.each do |original_type, expected_reverse_type|
        relationship = described_class.new(
          source_id: "source",
          target_id: "target",
          type: original_type
        )

        reverse = relationship.reverse
        expect(reverse.type).to eq(expected_reverse_type)
      end
    end

    it "preserves unknown relationship types" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "custom_relationship"
      )

      reverse = relationship.reverse
      expect(reverse.type).to eq("custom_relationship")
    end
  end

  describe "#to_s" do
    it "returns readable string representation without label" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many"
      )

      expected = "#{described_class.name}(users --has_many--> orders)"
      expect(relationship.to_s).to eq(expected)
    end

    it "returns readable string representation with label" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders"
      )

      expected = "#{described_class.name}(users --has_many (orders)--> orders)"
      expect(relationship.to_s).to eq(expected)
    end
  end

  describe "#inspect" do
    it "returns detailed string representation" do
      relationship = described_class.new(
        source_id: "users",
        target_id: "orders",
        type: "has_many",
        label: "orders"
      )

      result = relationship.inspect
      expect(result).to include(described_class.name)
      expect(result).to include('source_id: "users"')
      expect(result).to include('target_id: "orders"')
      expect(result).to include('type: "has_many"')
      expect(result).to include('label: "orders"')
      expect(result).to include("metadata: {}")
    end
  end
end
