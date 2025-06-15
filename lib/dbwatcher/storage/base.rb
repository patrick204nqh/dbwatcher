# frozen_string_literal: true

require_relative "file_manager"
require_relative "errors"

module Dbwatcher
  module Storage
    class Base
      include ErrorHandler

      attr_reader :storage_path, :file_manager

      def initialize
        @storage_path = Dbwatcher.configuration.storage_path
        @file_manager = FileManager.new(@storage_path)
      end

      protected

      def safe_write_json(file_path, data)
        safe_operation("write JSON to #{file_path}") do
          file_manager.write_json(file_path, data)
        end
      end

      def safe_read_json(file_path, default = [])
        safe_operation("read JSON from #{file_path}", default) do
          file_manager.read_json(file_path)
        end
      end
    end
  end
end
