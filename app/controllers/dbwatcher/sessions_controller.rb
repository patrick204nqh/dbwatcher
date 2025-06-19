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
        diagram_data = Storage.sessions.diagram_data(
          params[:id],
          params[:diagram_type] || "database_tables"
        )

        if diagram_data[:error]
          Rails.logger.error "SessionsController#diagram: Error generating diagram: #{diagram_data[:error]}"
          render json: { error: diagram_data[:error] }, status: :unprocessable_entity
        else
          Rails.logger.info "SessionsController#diagram: Successfully generated diagram with #{diagram_data[:content]&.lines&.count || 0} lines"
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
  end
end
