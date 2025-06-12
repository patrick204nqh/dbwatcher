# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dbwatcher::Engine" do
  let(:engine_file) { File.join(File.dirname(__FILE__), "../../lib/dbwatcher/engine.rb") }

  describe "engine definition" do
    it "exists and has basic structure" do
      expect(File.exist?(engine_file)).to be true

      content = File.read(engine_file)
      expect(content).to include("class Engine")
      expect(content).to include("Rails::Engine")
      expect(content).to include("module Dbwatcher")
    end

    it "has proper namespace isolation" do
      content = File.read(engine_file)
      expect(content).to include("isolate_namespace Dbwatcher")
    end

    it "includes initializers" do
      content = File.read(engine_file)
      expect(content).to include("initializer")
    end
  end
end
