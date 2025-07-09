# frozen_string_literal: true

require_relative "../logging"

module Dbwatcher
  module Services
    # Base class for all service objects
    #
    # Provides common functionality and patterns for service objects
    # including logging and consistent call interface.
    #
    # @example
    #   class MyService < BaseService
    #     def call
    #       log_info "Starting service"
    #       # service logic
    #     end
    #   end
    #
    #   result = MyService.call
    class BaseService
      include Dbwatcher::Logging

      # Class method to create instance and call
      #
      # @param args [Array] arguments to pass to initialize
      # @return [Object] result of call method
      def self.call(*args)
        new(*args).call
      end

      # Initialize service
      #
      # @param args [Array] service arguments
      def initialize(*args)
        # Override in subclasses
      end

      # Perform service operation
      #
      # @return [Object] service result
      def call
        raise NotImplementedError, "#{self.class} must implement #call"
      end

      private

      # Log service start with context
      #
      # @param message [String] log message
      # @param context [Hash] additional context
      def log_service_start(message, context = {})
        log_info "#{self.class.name}: #{message}", context
      end

      # Log service completion with duration
      #
      # @param start_time [Time] service start time
      # @param context [Hash] additional context
      def log_service_completion(start_time, context = {})
        duration = Time.now - start_time
        log_info "#{self.class.name}: Completed in #{duration.round(3)}s", context.merge(duration: duration)
      end
    end
  end
end
