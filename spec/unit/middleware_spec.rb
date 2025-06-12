# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dbwatcher::Middleware" do
  let(:middleware_file) { File.join(File.dirname(__FILE__), "../../lib/dbwatcher/middleware.rb") }

  describe "middleware definition" do
    it "exists with proper structure" do
      expect(File.exist?(middleware_file)).to be true

      content = File.read(middleware_file)
      expect(content).to include("class Middleware")
      expect(content).to include("module Dbwatcher")
    end

    it "implements rack interface" do
      content = File.read(middleware_file)
      expect(content).to include("def initialize")
      expect(content).to include("def call")
    end
  end
end
