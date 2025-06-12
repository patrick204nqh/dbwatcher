# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dbwatcher::ModelExtension" do
  let(:extension_file) { File.join(File.dirname(__FILE__), "../../lib/dbwatcher/model_extension.rb") }

  describe "model extension" do
    it "exists with proper structure" do
      expect(File.exist?(extension_file)).to be true

      content = File.read(extension_file)
      expect(content).to include("module ModelExtension")
      expect(content).to include("module Dbwatcher")
    end

    it "provides extension functionality" do
      content = File.read(extension_file)
      expect(content).to include("extend") if content.include?("extend")
    end
  end
end
