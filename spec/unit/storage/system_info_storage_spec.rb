# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dbwatcher::Storage::SystemInfoStorage do
  let(:storage) { described_class.new }
  let(:mock_file_manager) { instance_double(Dbwatcher::Storage::FileManager) }
  let(:mock_info) do
    {
      machine: { hostname: "test-host" },
      database: { adapter: "sqlite3" },
      runtime: { ruby_version: "3.1.0" },
      collected_at: Time.current.iso8601,
      collection_duration: 0.5
    }
  end
  let(:info_file_path) { File.join(storage.send(:storage_path), "system_info.json") }

  before do
    allow(storage).to receive(:file_manager).and_return(mock_file_manager)
    allow(Dbwatcher.configuration).to receive(:system_info_cache_duration).and_return(300)
  end

  describe "#save_info" do
    it "converts keys to strings and saves to file" do
      expect(mock_file_manager).to receive(:write_json).with(info_file_path, anything)
      storage.save_info(mock_info)
    end
  end

  describe "#load_info" do
    context "when file exists" do
      it "loads and converts keys to symbols" do
        string_keyed_info = { "machine" => { "hostname" => "test-host" } }
        expect(mock_file_manager).to receive(:read_json).with(info_file_path).and_return(string_keyed_info)
        result = storage.load_info
        expect(result).to have_key(:machine)
        expect(result[:machine]).to have_key(:hostname)
      end
    end

    context "when file does not exist" do
      it "returns an empty hash" do
        expect(mock_file_manager).to receive(:read_json).with(info_file_path).and_raise(Errno::ENOENT)
        expect(storage.load_info).to eq({})
      end
    end
  end

  describe "#refresh_info" do
    it "collects new info and saves it" do
      expect(Dbwatcher::Services::SystemInfo::SystemInfoCollector).to receive(:call).and_return(mock_info)
      expect(storage).to receive(:save_info).with(mock_info)
      result = storage.refresh_info
      expect(result).to eq(mock_info)
    end

    context "when collection fails" do
      before do
        allow(Dbwatcher::Services::SystemInfo::SystemInfoCollector).to receive(:call).and_raise(StandardError.new("Test error"))
        allow(storage).to receive(:load_info).and_return(mock_info)
      end

      it "returns cached info if available" do
        expect(storage.refresh_info).to eq(mock_info)
      end
    end
  end

  describe "#cached_info" do
    context "when no cached info exists" do
      before do
        allow(storage).to receive(:load_info).and_return({})
      end

      it "refreshes info" do
        expect(storage).to receive(:refresh_info)
        storage.cached_info
      end
    end

    context "when cached info exists but is expired" do
      let(:old_info) do
        {
          collected_at: (Time.current - 600).iso8601 # 10 minutes old
        }
      end

      before do
        allow(storage).to receive(:load_info).and_return(old_info)
      end

      it "refreshes info" do
        expect(storage).to receive(:refresh_info)
        storage.cached_info
      end
    end

    context "when cached info exists and is not expired" do
      let(:recent_info) do
        {
          collected_at: (Time.current - 60).iso8601 # 1 minute old
        }
      end

      before do
        allow(storage).to receive(:load_info).and_return(recent_info)
      end

      it "returns cached info" do
        expect(storage).not_to receive(:refresh_info)
        expect(storage.cached_info).to eq(recent_info)
      end
    end
  end

  describe "#info_age" do
    context "when info exists" do
      let(:collected_time) { Time.current - 120 } # 2 minutes ago
      let(:recent_info) do
        {
          collected_at: collected_time.iso8601
        }
      end

      before do
        allow(storage).to receive(:load_info).and_return(recent_info)
        allow(storage).to receive(:current_time).and_return(Time.current)
      end

      it "returns age in seconds" do
        expect(storage.info_age).to be_within(1).of(120)
      end
    end

    context "when info does not exist" do
      before do
        allow(storage).to receive(:load_info).and_return({})
      end

      it "returns nil" do
        expect(storage.info_age).to be_nil
      end
    end
  end

  describe "#clear_cache" do
    it "deletes the info file" do
      expect(storage).to receive(:safe_delete_file).with(info_file_path)
      storage.clear_cache
    end
  end

  describe "#summary" do
    before do
      allow(storage).to receive(:cached_info).and_return(
        {
          machine: {
            hostname: "test-host",
            os: { name: "Linux" },
            memory: { usage_percent: 50 },
            cpu: { load_average: { "1min" => 0.5 } }
          },
          database: {
            adapter: { name: "PostgreSQL" },
            active_connections: 2
          },
          runtime: {
            ruby_version: "3.1.0",
            rails_version: "7.0.0"
          },
          collected_at: Time.current.iso8601,
          collection_duration: 0.5
        }
      )
    end

    it "returns summarized system information" do
      summary = storage.summary
      expect(summary[:hostname]).to eq("test-host")
      expect(summary[:os]).to eq("Linux")
      expect(summary[:ruby_version]).to eq("3.1.0")
      expect(summary[:rails_version]).to eq("7.0.0")
      expect(summary[:database_adapter]).to eq("PostgreSQL")
      expect(summary[:memory_usage]).to eq(50)
      expect(summary[:cpu_load]).to eq(0.5)
      expect(summary[:active_connections]).to eq(2)
    end
  end
end
