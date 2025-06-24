# frozen_string_literal: true

module Dbwatcher
  class SessionsController < BaseController
    def index
      @sessions = Storage.sessions.all
    end

    def show
      Rails.logger.info "SessionsController#show: Loading session with ID: #{params[:id]}"
      @session = Storage.sessions.find(params[:id])
      Rails.logger.info "SessionsController#show: Loaded session: #{@session.inspect}"

      return handle_not_found("Session", sessions_path) unless @session

      @tables_summary = Storage.sessions.build_tables_summary(@session)
      @active_tab = validate_tab_parameter(params[:tab])
      Rails.logger.info "SessionsController#show: Tables summary: #{@tables_summary.inspect}"

      respond_to do |format|
        format.html
        format.json { render json: @session.to_h }
      end
    end

    # GET /sessions/:id/diagram
    def diagram
      Rails.logger.info "SessionsController#diagram: Generating diagram for session #{params[:id]} type: #{params[:diagram_type]}"

      begin
        diagram_type = params[:diagram_type] || "database_tables"

        # Generate cache key based on session ID and diagram type
        cache_key = "diagram_#{params[:id]}_#{diagram_type}"

        # Clear cache for this diagram if requested
        Rails.cache.delete(cache_key) if params[:refresh] == "true"

        # Try to get from cache first
        diagram_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          Rails.logger.info "SessionsController#diagram: Cache miss, generating fresh diagram for type: #{diagram_type}"

          # Generate diagram using the diagram system
          result = Storage.sessions.diagram_data(params[:id], diagram_type)

          # Log the result for debugging
          if result[:error]
            Rails.logger.error "SessionsController#diagram: Error in diagram generation: #{result[:error]}"
          else
            Rails.logger.info "SessionsController#diagram: Successfully generated #{diagram_type} diagram"
          end

          result
        end

        if diagram_data[:error]
          Rails.logger.error "SessionsController#diagram: Error generating diagram: #{diagram_data[:error]}"
          render json: { error: diagram_data[:error] }, status: :unprocessable_entity
        else
          Rails.logger.info "SessionsController#diagram: Successfully generated diagram"
          render json: diagram_data
        end
      rescue StandardError => e
        Rails.logger.error "SessionsController#diagram: Exception when generating diagram: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: "Server error: #{e.message}", details: e.backtrace.first(5) },
               status: :internal_server_error
      end
    end

    # GET /sessions/:id/summary
    def summary
      Rails.logger.info "SessionsController#summary: Getting summary for session #{params[:id]}"

      result = Storage.sessions.summary(params[:id])

      if result[:error]
        Rails.logger.error "SessionsController#summary: Error getting summary: #{result[:error]}"
        render json: { error: result[:error] }, status: :not_found
      else
        Rails.logger.info "SessionsController#summary: Successfully retrieved summary"
        render json: result
      end
    end

    def clear
      clear_storage_with_message(
        -> { Storage.session_storage.clear_all },
        "All sessions",
        sessions_path
      )
    end

    private

    def validate_tab_parameter(tab)
      valid_tabs = %w[changes summary diagrams]
      valid_tabs.include?(tab) ? tab : "changes"
    end
  end
end
