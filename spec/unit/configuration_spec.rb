# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dbwatcher::Configuration do
  subject { described_class.new }

  describe "default configuration" do
    it "is enabled by default" do
      expect(subject.enabled).to be true
    end

    it "has a storage path" do
      expect(subject.storage_path).to be_a(String)
      expect(subject.storage_path).not_to be_empty
    end

    it "has reasonable defaults" do
      expect(subject.max_sessions).to be_a(Integer)
      expect(subject.auto_clean_after_days).to be_a(Integer)
    end
  end

  describe "configuration options" do
    it "can be disabled" do
      subject.enabled = false
      expect(subject.enabled).to be false
    end

    it "accepts custom storage path" do
      custom_path = "/tmp/custom"
      subject.storage_path = custom_path
      expect(subject.storage_path).to eq(custom_path)
    end
  end
end
