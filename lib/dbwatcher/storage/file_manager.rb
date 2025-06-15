# frozen_string_literal: true

module Dbwatcher
  module Storage
    class FileManager
      def initialize(storage_path)
        @storage_path = storage_path
        ensure_directories
      end

      def write_json(file_path, data)
        File.write(file_path, JSON.pretty_generate(data))
      end

      def read_json(file_path)
        return default_empty_result unless File.exist?(file_path)

        JSON.parse(File.read(file_path), symbolize_names: true)
      end

      def file_exists?(file_path)
        File.exist?(file_path)
      end

      def delete_file(file_path)
        File.delete(file_path)
      end

      def glob_files(pattern)
        Dir.glob(pattern)
      end

      def ensure_directory(path)
        FileUtils.mkdir_p(path)
      end

      private

      def ensure_directories
        FileUtils.mkdir_p(@storage_path)
      end

      def default_empty_result
        []
      end
    end
  end
end
