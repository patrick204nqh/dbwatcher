# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Services::DiagramData::Attribute do
  let(:attribute) do
    described_class.new(
      name: "id",
      type: "integer",
      nullable: false,
      default: nil,
      metadata: { primary_key: true }
    )
  end

  describe "#initialize" do
    it "creates attribute with required parameters" do
      attribute = described_class.new(name: "id")
      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("")
      expect(attribute.nullable).to be true
      expect(attribute.default).to be_nil
      expect(attribute.metadata).to eq({})
    end

    it "creates attribute with all parameters" do
      attribute = described_class.new(
        name: "id",
        type: "integer",
        nullable: false,
        default: 0,
        metadata: { primary_key: true }
      )

      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("integer")
      expect(attribute.nullable).to be false
      expect(attribute.default).to eq(0)
      expect(attribute.metadata).to eq({ primary_key: true })
    end

    it "converts name and type to strings" do
      attribute = described_class.new(name: :id, type: :integer)
      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("integer")
    end

    it "handles non-hash metadata gracefully" do
      attribute = described_class.new(name: "id", metadata: "invalid")
      expect(attribute.metadata).to eq({})
    end
  end

  describe "#valid?" do
    it "returns true for valid attribute" do
      expect(attribute).to be_valid
    end

    it "returns false when name is blank" do
      attribute = described_class.new(name: "")
      expect(attribute).not_to be_valid
    end
  end

  describe "#validation_errors" do
    it "returns empty array for valid attribute" do
      expect(attribute.validation_errors).to be_empty
    end

    it "returns errors for invalid attribute" do
      attribute = described_class.new(name: "")
      attribute.metadata = "invalid"

      errors = attribute.validation_errors
      expect(errors).to include("Name cannot be blank")
      expect(errors).to include("Metadata must be a Hash")
    end
  end

  describe "#primary_key?" do
    it "returns true when marked as primary key in metadata" do
      expect(attribute).to be_primary_key
    end

    it "returns false when not marked as primary key" do
      attribute = described_class.new(name: "name", type: "string")
      expect(attribute).not_to be_primary_key
    end
  end

  describe "#foreign_key?" do
    it "returns true when marked as foreign key in metadata" do
      attribute = described_class.new(
        name: "user_id",
        type: "integer",
        metadata: { foreign_key: true }
      )
      expect(attribute).to be_foreign_key
    end

    it "returns true when name ends with _id" do
      attribute = described_class.new(name: "user_id", type: "integer")
      expect(attribute).to be_foreign_key
    end

    it "returns false for non-foreign key attributes" do
      attribute = described_class.new(name: "name", type: "string")
      expect(attribute).not_to be_foreign_key
    end
  end

  describe "#to_h" do
    it "serializes attribute to hash" do
      expected = {
        name: "id",
        type: "integer",
        nullable: false,
        default: nil,
        metadata: { primary_key: true }
      }

      expect(attribute.to_h).to eq(expected)
    end
  end

  describe "#to_json" do
    it "serializes attribute to JSON" do
      json = attribute.to_json
      parsed = JSON.parse(json)

      expect(parsed["name"]).to eq("id")
      expect(parsed["type"]).to eq("integer")
      expect(parsed["nullable"]).to eq(false)
      expect(parsed["metadata"]["primary_key"]).to eq(true)
    end
  end

  describe ".from_h" do
    it "creates attribute from hash with symbol keys" do
      hash = {
        name: "id",
        type: "integer",
        nullable: false,
        default: nil,
        metadata: { primary_key: true }
      }

      attribute = described_class.from_h(hash)
      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("integer")
      expect(attribute.nullable).to be false
      expect(attribute.default).to be_nil
      expect(attribute.metadata).to eq({ primary_key: true })
    end

    it "creates attribute from hash with string keys" do
      hash = {
        "name" => "id",
        "type" => "integer",
        "nullable" => false,
        "default" => nil,
        "metadata" => { "primary_key" => true }
      }

      attribute = described_class.from_h(hash)
      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("integer")
      expect(attribute.nullable).to be false
      expect(attribute.default).to be_nil
      expect(attribute.metadata).to eq({ "primary_key" => true })
    end

    it "handles missing optional fields" do
      hash = { name: "id" }

      attribute = described_class.from_h(hash)
      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("")
      expect(attribute.nullable).to be true
      expect(attribute.default).to be_nil
      expect(attribute.metadata).to eq({})
    end
  end

  describe ".from_json" do
    it "creates attribute from JSON string" do
      json = {
        name: "id",
        type: "integer",
        nullable: false,
        default: nil,
        metadata: { primary_key: true }
      }.to_json

      attribute = described_class.from_json(json)
      expect(attribute.name).to eq("id")
      expect(attribute.type).to eq("integer")
      expect(attribute.nullable).to be false
      expect(attribute.default).to be_nil
      expect(attribute.metadata).to eq({ "primary_key" => true })
    end
  end

  describe "#==" do
    it "returns true for identical attributes" do
      attribute1 = described_class.new(
        name: "id",
        type: "integer",
        nullable: false,
        metadata: { primary_key: true }
      )
      attribute2 = described_class.new(
        name: "id",
        type: "integer",
        nullable: false,
        metadata: { primary_key: true }
      )

      expect(attribute1).to eq(attribute2)
    end

    it "returns false for different attributes" do
      attribute1 = described_class.new(name: "id", type: "integer")
      attribute2 = described_class.new(name: "name", type: "string")

      expect(attribute1).not_to eq(attribute2)
    end

    it "returns false for non-attribute objects" do
      expect(attribute).not_to eq("not an attribute")
    end
  end

  describe "#to_s" do
    it "returns readable string representation" do
      result = attribute.to_s
      expect(result).to include("name: id")
      expect(result).to include("type: integer")
      expect(result).to include("nullable: false")
      expect(result).to start_with("#{described_class.name}(")
      expect(result).to end_with(")")
    end
  end
end
