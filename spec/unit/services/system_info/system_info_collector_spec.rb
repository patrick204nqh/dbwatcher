# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Services::SystemInfo::SystemInfoCollector do
  let(:collector) { described_class.new }
  let(:mock_machine_info) { { hostname: "test-host", os: { name: "Linux" } } }
  let(:mock_database_info) { { adapter: "sqlite3", version: "3.36.0" } }
  let(:mock_runtime_info) { { ruby_version: "3.1.0", rails_version: "7.0.0" } }

  before do
    allow(Dbwatcher.configuration).to receive(:collect_system_info).and_return(true)
    allow(Dbwatcher::Services::SystemInfo::MachineInfoCollector).to receive(:call).and_return(mock_machine_info)
    allow(Dbwatcher::Services::SystemInfo::DatabaseInfoCollector).to receive(:call).and_return(mock_database_info)
    allow(Dbwatcher::Services::SystemInfo::RuntimeInfoCollector).to receive(:call).and_return(mock_runtime_info)
  end

  describe ".call" do
    it "creates an instance and calls it" do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.call
    end
  end

  describe "#call" do
    it "collects information from all collectors" do
      expect(Dbwatcher::Services::SystemInfo::MachineInfoCollector).to receive(:call)
      expect(Dbwatcher::Services::SystemInfo::DatabaseInfoCollector).to receive(:call)
      expect(Dbwatcher::Services::SystemInfo::RuntimeInfoCollector).to receive(:call)
      collector.call
    end

    it "returns a hash with collected information" do
      result = collector.call
      expect(result).to include(:machine, :database, :runtime, :collected_at, :collection_duration)
      expect(result[:machine]).to eq(mock_machine_info)
      expect(result[:database]).to eq(mock_database_info)
      expect(result[:runtime]).to eq(mock_runtime_info)
      expect(result[:collected_at]).to be_a(String)
      expect(result[:collection_duration]).to be_a(Float)
    end

    context "when system info collection is disabled" do
      before do
        allow(Dbwatcher.configuration).to receive(:collect_system_info).and_return(false)
      end

      it "returns empty hashes for all collectors" do
        result = collector.call
        expect(result[:machine]).to eq({})
        expect(result[:database]).to eq({})
        expect(result[:runtime]).to eq({})
      end
    end

    context "when a collector raises an error" do
      before do
        allow(Dbwatcher::Services::SystemInfo::MachineInfoCollector).to receive(:call).and_raise(StandardError.new("Machine info error"))
      end

      it "handles the error and returns an error hash for that collector" do
        result = collector.call
        expect(result[:machine]).to eq({ error: "Machine info error" })
        expect(result[:database]).to eq(mock_database_info)
        expect(result[:runtime]).to eq(mock_runtime_info)
      end
    end

    context "when all collectors raise errors" do
      before do
        allow(Dbwatcher::Services::SystemInfo::MachineInfoCollector).to receive(:call).and_raise(StandardError.new("Machine info error"))
        allow(Dbwatcher::Services::SystemInfo::DatabaseInfoCollector).to receive(:call).and_raise(StandardError.new("Database info error"))
        allow(Dbwatcher::Services::SystemInfo::RuntimeInfoCollector).to receive(:call).and_raise(StandardError.new("Runtime info error"))
      end

      it "handles all errors and returns error hashes for all collectors" do
        result = collector.call
        expect(result[:machine]).to eq({ error: "Machine info error" })
        expect(result[:database]).to eq({ error: "Database info error" })
        expect(result[:runtime]).to eq({ error: "Runtime info error" })
      end
    end
  end
end
