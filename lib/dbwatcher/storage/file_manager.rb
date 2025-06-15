# frozen_string_literal: true

module Dbwatcher
  module Storage
    # Manages file system operations for storage classes
    #
    # This class provides a centralized interface for file operations
    # including JSON serialization, directory management, and file
    # system utilities used throughout the storage module.
    #
    # @example
    #   manager = FileManager.new("/path/to/storage")
    #   manager.write_json("data.json", { key: "value" })
    #   data = manager.read_json("data.json")
    class FileManager
      # @return [String] the base storage path
      attr_reader :storage_path

      # Initializes file manager with storage path
      #
      # Creates the base storage directory if it doesn't exist.
      #
      # @param storage_path [String] base path for file operations
      def initialize(storage_path)
        @storage_path = storage_path
        ensure_directories
      end

      # Writes data to a JSON file
      #
      # Serializes the provided data as pretty-printed JSON and writes
      # it to the specified file path.
      #
      # @param file_path [String] path to write the JSON file
      # @param data [Object] data to serialize as JSON
      # @return [Integer] number of bytes written
      # @raise [JSON::GeneratorError] if data cannot be serialized
      def write_json(file_path, data)
        # Ensure parent directory exists
        ensure_directory(File.dirname(file_path))
        File.write(file_path, JSON.pretty_generate(data))
      end

      # Reads and parses a JSON file
      #
      # Reads the specified file and parses it as JSON with symbolized keys.
      # Returns empty array if file doesn't exist.
      #
      # @param file_path [String] path to the JSON file
      # @return [Object] parsed JSON data with symbolized keys
      # @raise [JSON::ParserError] if file contains invalid JSON
      def read_json(file_path)
        return default_empty_result unless File.exist?(file_path)

        JSON.parse(File.read(file_path), symbolize_names: true)
      end

      # Checks if a file exists
      #
      # @param file_path [String] path to check
      # @return [Boolean] true if file exists
      def file_exists?(file_path)
        File.exist?(file_path)
      end

      # Deletes a file
      #
      # @param file_path [String] path to file to delete
      # @return [Integer] number of files deleted (1 or 0)
      def delete_file(file_path)
        File.delete(file_path)
      end

      # Deletes a directory and its contents
      #
      # @param dir_path [String] path to directory to delete
      # @return [Boolean] true if directory was deleted, false if it didn't exist
      def delete_directory(dir_path)
        return false unless Dir.exist?(dir_path)

        FileUtils.rm_rf(dir_path)
        true
      rescue Errno::ENOENT
        false
      end

      # Returns files matching a glob pattern
      #
      # @param pattern [String] glob pattern to match
      # @return [Array<String>] array of matching file paths
      def glob_files(pattern)
        Dir.glob(pattern)
      end

      # Ensures a directory exists
      #
      # Creates the directory and any necessary parent directories.
      #
      # @param path [String] directory path to create
      # @return [Array, nil] array of created directories or nil if already exists
      def ensure_directory(path)
        FileUtils.mkdir_p(path)
      end

      private

      # Creates the base storage directory
      #
      # @return [Array, nil] array of created directories or nil if already exists
      def ensure_directories
        FileUtils.mkdir_p(@storage_path)
      end

      # Default return value for empty JSON files
      #
      # @return [Array] empty array as default
      def default_empty_result
        []
      end
    end
  end
end
