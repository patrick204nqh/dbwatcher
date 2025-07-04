# frozen_string_literal: true

require_relative "file_manager"
require_relative "errors"
require_relative "concerns/error_handler"
require_relative "concerns/timestampable"
require_relative "concerns/validatable"

module Dbwatcher
  module Storage
    # Base class for all storage implementations
    #
    # Provides common functionality for storage classes including
    # file management, error handling, validation, and timestamping.
    # Follows the Ruby style guide patterns for class organization.
    #
    # @abstract Subclass and implement specific storage logic
    # @example
    #   class MyStorage < BaseStorage
    #     include Concerns::Validatable
    #
    #     validates_presence_of :id, :name
    #
    #     def save(data)
    #       validate_presence!(data)
    #       safe_write_json(file_path, data)
    #     end
    #   end
    class BaseStorage
      # Include shared concerns
      include Concerns::ErrorHandler
      include Concerns::Timestampable

      # Configuration constants
      DEFAULT_PERMISSIONS = 0o755
      JSON_FILE_EXTENSION = ".json"

      # @return [String] the configured storage path
      attr_reader :storage_path

      # @return [FileManager] the file manager instance
      attr_reader :file_manager

      # Initializes the base storage with configured path and file manager
      #
      # Sets up the storage path from configuration, creates a file manager
      # instance, and initializes timestamps.
      #
      # @param storage_path [String, nil] custom storage path (optional)
      # @raise [StorageError] if storage_path is nil or empty
      def initialize(storage_path = nil)
        @storage_path = storage_path || Dbwatcher.configuration.storage_path

        # Ensure storage path is valid
        if @storage_path.nil? || @storage_path.to_s.strip.empty?
          raise StorageError, "Storage path cannot be nil or empty. Please configure a valid storage path."
        end

        @file_manager = FileManager.new(@storage_path)
        initialize_timestamps
        ensure_storage_directory
      end

      protected

      # Safely writes JSON data to a file
      #
      # @param file_path [String] the path to write to
      # @param data [Object] the data to serialize as JSON
      # @return [Boolean] true if successful, false otherwise
      def safe_write_json(file_path, data)
        safe_operation("write JSON to #{file_path}") do
          file_manager.write_json(file_path, data)
          touch_updated_at
          true
        end
      end

      # Safely reads JSON data from a file
      #
      # @param file_path [String] the path to read from
      # @param default [Object] default value if file doesn't exist or is invalid
      # @return [Object] the parsed JSON data or default value
      def safe_read_json(file_path, default = [])
        safe_operation("read JSON from #{file_path}", default) do
          file_manager.read_json(file_path)
        end
      end

      # Removes a file safely
      #
      # @param file_path [String] the path to the file to remove
      # @return [Boolean] true if file was removed, false if it didn't exist
      def safe_delete_file(file_path)
        safe_operation("delete file #{file_path}") do
          file_manager.delete_file(file_path)
        end
      end

      # Removes a directory safely
      #
      # @params directory_path [String] the path to the directory to remove
      # @return [Boolean] true if directory was removed, false if it didn't exist
      def safe_delete_directory(directory_path)
        safe_operation("delete directory #{directory_path}") do
          file_manager.delete_directory(directory_path)
        end
      end

      private

      # Ensures the storage directory exists with proper permissions
      #
      # @return [void]
      def ensure_storage_directory
        file_manager.ensure_directory(storage_path)
      end
    end
  end
end
