# frozen_string_literal: true

module Dbwatcher
  module Storage
    class Base
      attr_reader :storage_path

      def initialize
        @storage_path = Dbwatcher.configuration.storage_path
        ensure_directories
      end

      private

      def ensure_directories
        FileUtils.mkdir_p(storage_path)
      end

      def safe_write_json(file_path, data)
        File.write(file_path, JSON.pretty_generate(data))
      rescue StandardError => e
        warn "Failed to write #{file_path}: #{e.message}"
      end

      def safe_read_json(file_path)
        return [] unless File.exist?(file_path)

        JSON.parse(File.read(file_path), symbolize_names: true)
      rescue JSON::ParserError => e
        warn "Failed to parse #{file_path}: #{e.message}"
        []
      rescue StandardError => e
        warn "Failed to read #{file_path}: #{e.message}"
        []
      end
    end
  end
end
