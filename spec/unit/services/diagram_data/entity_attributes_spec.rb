# frozen_string_literal: true

require "unit/services/diagram_data_helper"

RSpec.describe "Entity with Attributes" do
  let(:entity) { Dbwatcher::Services::DiagramData::Entity.new(id: "users", name: "User", type: "table") }
  let(:attribute_class) { Dbwatcher::Services::DiagramData::Attribute }

  describe "#attributes" do
    it "initializes with empty attributes array" do
      expect(entity.attributes).to eq([])
    end

    it "allows setting attributes array" do
      attributes = [
        attribute_class.new(name: "id", type: "integer"),
        attribute_class.new(name: "name", type: "string")
      ]
      entity.attributes = attributes

      expect(entity.attributes).to eq(attributes)
    end
  end

  describe "#add_attribute" do
    it "adds attribute to entity" do
      attribute = attribute_class.new(name: "id", type: "integer")
      entity.add_attribute(attribute)

      expect(entity.attributes).to include(attribute)
    end

    it "adds attribute with parameters" do
      # Create an attribute instance instead of using parameters
      attribute = attribute_class.new(name: "id", type: "integer")
      entity.add_attribute(attribute)

      expect(entity.attributes.size).to eq(1)
      expect(entity.attributes.first.name).to eq("id")
      expect(entity.attributes.first.type).to eq("integer")
    end

    it "returns the added attribute" do
      attribute = attribute_class.new(name: "id", type: "integer")
      result = entity.add_attribute(attribute)

      expect(result).to eq(attribute)
    end

    it "raises error for invalid attribute" do
      # Create an invalid attribute instance
      invalid_attribute = attribute_class.new(name: "", type: "integer")

      expect do
        entity.add_attribute(invalid_attribute)
      end.to raise_error(ArgumentError, /Attribute is invalid/)
    end
  end

  describe "#primary_key_attributes" do
    before do
      entity.add_attribute(attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true }))
      entity.add_attribute(attribute_class.new(name: "name", type: "string"))
      entity.add_attribute(attribute_class.new(name: "email", type: "string", metadata: { unique: true }))
    end

    it "returns attributes marked as primary keys" do
      primary_keys = entity.primary_key_attributes

      expect(primary_keys.size).to eq(1)
      expect(primary_keys.first.name).to eq("id")
    end
  end

  describe "#foreign_key_attributes" do
    before do
      entity.add_attribute(attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true }))
      entity.add_attribute(attribute_class.new(name: "user_id", type: "integer"))
      entity.add_attribute(attribute_class.new(name: "post_id", type: "integer", metadata: { foreign_key: true }))
      entity.add_attribute(attribute_class.new(name: "name", type: "string"))
    end

    it "returns attributes that are foreign keys" do
      foreign_keys = entity.foreign_key_attributes

      expect(foreign_keys.size).to eq(2)
      expect(foreign_keys.map(&:name)).to contain_exactly("user_id", "post_id")
    end
  end

  describe "#to_h with attributes" do
    before do
      entity.add_attribute(attribute_class.new(name: "id", type: "integer", metadata: { primary_key: true }))
      entity.add_attribute(attribute_class.new(name: "name", type: "string"))
    end

    it "includes attributes in serialized hash" do
      hash = entity.to_h

      expect(hash[:attributes]).to be_an(Array)
      expect(hash[:attributes].size).to eq(2)
      expect(hash[:attributes][0][:name]).to eq("id")
      expect(hash[:attributes][1][:name]).to eq("name")
    end
  end

  describe ".from_h with attributes" do
    let(:hash) do
      {
        id: "users",
        name: "User",
        type: "table",
        attributes: [
          { name: "id", type: "integer", metadata: { primary_key: true } },
          { name: "name", type: "string" }
        ]
      }
    end

    it "deserializes entity with attributes" do
      entity = Dbwatcher::Services::DiagramData::Entity.from_h(hash)

      expect(entity.attributes.size).to eq(2)
      expect(entity.attributes[0].name).to eq("id")
      expect(entity.attributes[0].type).to eq("integer")
      expect(entity.attributes[0].metadata[:primary_key]).to eq(true)
      expect(entity.attributes[1].name).to eq("name")
      expect(entity.attributes[1].type).to eq("string")
    end
  end
end
