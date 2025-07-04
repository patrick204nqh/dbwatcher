# frozen_string_literal: true

require "unit/services/diagram_helper"

RSpec.describe Dbwatcher::Services::MermaidSyntax::CardinalityMapper do
  describe ".to_erd" do
    it "maps cardinality types to ERD notation" do
      expect(described_class.to_erd("one_to_many")).to eq("||--o{")
      expect(described_class.to_erd("many_to_one")).to eq("}o--||")
      expect(described_class.to_erd("one_to_one")).to eq("||--||")
      expect(described_class.to_erd("many_to_many")).to eq("}o--o{")
    end

    it "handles edge cases" do
      # Default to one-to-many for unknown or nil values
      expect(described_class.to_erd("unknown")).to eq("||--o{")
      expect(described_class.to_erd(nil)).to eq("||--o{")
    end
  end

  describe ".to_class" do
    it "maps cardinality types to class diagram notation" do
      expect(described_class.to_class("one_to_many")).to eq("1..*")
      expect(described_class.to_class("many_to_one")).to eq("*..*")
      expect(described_class.to_class("one_to_one")).to eq("1..1")
      expect(described_class.to_class("many_to_many")).to eq("*..*")
    end

    it "handles edge cases" do
      # Default to one-to-many for unknown or nil values
      expect(described_class.to_class("unknown")).to eq("1..*")
      expect(described_class.to_class(nil)).to eq("1..*")
    end
  end

  describe ".to_simple" do
    it "maps cardinality types to simple notation" do
      expect(described_class.to_simple("one_to_many")).to eq("1:N")
      expect(described_class.to_simple("many_to_one")).to eq("N:1")
      expect(described_class.to_simple("one_to_one")).to eq("1:1")
      expect(described_class.to_simple("many_to_many")).to eq("N:N")
    end

    it "handles edge cases" do
      # Default to one-to-many for unknown or nil values
      expect(described_class.to_simple("unknown")).to eq("1:N")
      expect(described_class.to_simple(nil)).to eq("1:N")
    end
  end
end
