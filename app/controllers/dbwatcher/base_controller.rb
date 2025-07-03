# frozen_string_literal: true

module Dbwatcher
  # Base controller for all Dbwatcher controllers
  # Provides common functionality and configuration for the entire engine
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    before_action :set_current_time
    before_action :log_request_info

    # Common error handling
    rescue_from StandardError, with: :handle_error

    # Include helpers
    helper Dbwatcher::ApplicationHelper
    helper Dbwatcher::FormattingHelper
    helper Dbwatcher::DiagramHelper if defined?(Dbwatcher::DiagramHelper)

    protected

    # Set current time for consistent timestamp usage across views
    def set_current_time
      @current_time = Time.current
    end

    # Log request information for debugging
    def log_request_info
      return unless Rails.logger

      Rails.logger.info "DBWatcher Request: #{request.method} #{request.path} - Controller: #{self.class.name}"
    end

    # Common error handling for all controllers
    def handle_error(exception)
      Rails.logger.error "DBWatcher Error in #{self.class.name}##{action_name}: #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?

      respond_to do |format|
        format.html do
          flash[:error] = "An error occurred while processing your request."
          # Avoid infinite redirect by using main app root or request referer
          redirect_to(request.referer || main_app.root_path)
        end
        format.json do
          render json: { error: "Internal server error" }, status: :internal_server_error
        end
      end
    end

    # Helper method for safely extracting data from hashes with symbol/string keys
    def safe_extract(data, key)
      return nil unless data.is_a?(Hash)

      data[key] || data[key.to_s]
    end

    # Helper method for formatting timestamps consistently
    def format_timestamp(timestamp_str)
      return "N/A" unless timestamp_str

      Time.parse(timestamp_str).strftime("%Y-%m-%d %H:%M:%S")
    rescue ArgumentError
      "N/A"
    end

    # Make helper methods available to views
    helper_method :format_timestamp, :safe_extract

    # Helper method for rendering JSON responses with consistent structure
    def render_json_response(data, status: :ok)
      render json: {
        status: status,
        data: data,
        timestamp: @current_time.iso8601
      }, status: status
    end

    # Helper method for handling not found resources
    def handle_not_found(resource_name, redirect_path)
      Rails.logger.warn "#{self.class.name}##{action_name}: #{resource_name} not found for ID: #{params[:id]}"

      respond_to do |format|
        format.html do
          redirect_to redirect_path, alert: "#{resource_name} not found"
        end
        format.json do
          render json: { error: "#{resource_name} not found" }, status: :not_found
        end
      end
    end

    # Helper method for clearing storage with consistent messaging
    def clear_storage_with_message(storage_method, resource_name, redirect_path)
      cleared_count = storage_method.call
      redirect_to redirect_path,
                  notice: "#{resource_name} cleared (#{cleared_count} files removed)"
    end
  end
end
