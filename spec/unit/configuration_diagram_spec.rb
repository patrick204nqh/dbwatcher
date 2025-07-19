# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Configuration, "Diagram Options" do
  describe "diagram configuration options" do
    it "has default values for diagram options" do
      configuration = Dbwatcher::Configuration.new

      expect(configuration.diagram_show_attributes).to be true
      expect(configuration.diagram_show_methods).to be false
      expect(configuration.diagram_show_cardinality).to be true
      expect(configuration.diagram_attribute_types).to be true
      expect(configuration.diagram_max_attributes).to be_a(Integer)
      expect(configuration.diagram_relationship_labels).to be true
    end

    it "allows setting diagram_show_attributes" do
      configuration = Dbwatcher::Configuration.new
      configuration.diagram_show_attributes = false
      expect(configuration.diagram_show_attributes).to be false
    end

    it "allows setting diagram_show_methods" do
      configuration = Dbwatcher::Configuration.new
      configuration.diagram_show_methods = true
      expect(configuration.diagram_show_methods).to be true
    end

    it "allows setting diagram_show_cardinality" do
      configuration = Dbwatcher::Configuration.new
      configuration.diagram_show_cardinality = false
      expect(configuration.diagram_show_cardinality).to be false
    end

    it "allows setting diagram_attribute_types" do
      configuration = Dbwatcher::Configuration.new
      configuration.diagram_attribute_types = false
      expect(configuration.diagram_attribute_types).to be false
    end

    it "allows setting diagram_max_attributes" do
      configuration = Dbwatcher::Configuration.new
      configuration.diagram_max_attributes = 5
      expect(configuration.diagram_max_attributes).to eq(5)
    end

    it "allows setting diagram_relationship_labels" do
      configuration = Dbwatcher::Configuration.new
      configuration.diagram_relationship_labels = false
      expect(configuration.diagram_relationship_labels).to be false
    end
  end

  describe "configuring via block" do
    it "allows setting diagram options via configure block" do
      Dbwatcher.configure do |config|
        config.diagram_show_attributes = false
        config.diagram_show_methods = true
        config.diagram_show_cardinality = false
        config.diagram_attribute_types = false
        config.diagram_max_attributes = 5
        config.diagram_relationship_labels = false
      end

      config = Dbwatcher.configuration
      expect(config.diagram_show_attributes).to be false
      expect(config.diagram_show_methods).to be true
      expect(config.diagram_show_cardinality).to be false
      expect(config.diagram_attribute_types).to be false
      expect(config.diagram_max_attributes).to eq(5)
      expect(config.diagram_relationship_labels).to be false

      # Reset configuration for other tests
      Dbwatcher.configure do |config|
        config.diagram_show_attributes = true
        config.diagram_show_methods = false
        config.diagram_show_cardinality = true
        config.diagram_attribute_types = true
        config.diagram_max_attributes = 10
        config.diagram_relationship_labels = true
      end
    end
  end
end
