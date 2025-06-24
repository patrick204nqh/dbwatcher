# frozen_string_literal: true

module Dbwatcher
  class SessionsController < BaseController
    before_action :find_session, except: [:index]

    def index
      @sessions = Storage.sessions.all
    end

    def show
      redirect_to changes_session_path(@session.id)
    end

    def changes
      Rails.logger.info "SessionsController#changes: Loading changes for session #{@session.id}"
      @tables_summary = build_tables_summary
      @active_filters = parse_filters

      respond_to do |format|
        format.html
        format.json { render json: changes_json_data }
      end
    end

    def summary
      Rails.logger.info "SessionsController#summary: Loading summary for session #{@session.id}"
      @tables_summary = build_tables_summary
      @summary_data = build_summary_stats

      respond_to do |format|
        format.html
        format.json { render json: @summary_data }
      end
    end

    def diagrams
      Rails.logger.info "SessionsController#diagrams: Loading diagrams for session #{@session.id}"
      @tables_summary = build_tables_summary
      @diagram_types = available_diagram_types

      respond_to do |format|
        format.html
        format.json do
          diagram_result = generate_diagram(params[:diagram_type])
          render json: diagram_result
        end
      end
    end

    # Legacy endpoints - kept for backward compatibility
    def diagram
      Rails.logger.info "SessionsController#diagram: Generating diagram for session #{params[:id]} type: #{params[:diagram_type]}"

      begin
        diagram_type = params[:diagram_type] || "database_tables"
        cache_key = "diagram_#{params[:id]}_#{diagram_type}"
        Rails.cache.delete(cache_key) if params[:refresh] == "true"

        diagram_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          Rails.logger.info "SessionsController#diagram: Cache miss, generating fresh diagram for type: #{diagram_type}"
          result = Storage.sessions.diagram_data(params[:id], diagram_type)

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

    def clear
      clear_storage_with_message(
        -> { Storage.session_storage.clear_all },
        "All sessions",
        sessions_path
      )
    end

    private

    def find_session
      @session = Storage.sessions.find(params[:id])
      handle_not_found("Session", sessions_path) unless @session
    end

    def build_tables_summary
      Storage.sessions.build_tables_summary(@session)
    end

    def build_summary_stats
      # Use the new service for consistency
      service = Dbwatcher::Services::Api::SummaryDataService.new(@session)
      result = service.call
      result[:error] ? {} : result
    end

    def available_diagram_types
      Dbwatcher::Services::Api::DiagramDataService.available_types
    end

    def generate_diagram(type)
      service = Dbwatcher::Services::Api::DiagramDataService.new(@session, type, params)
      service.call
    end

    def parse_filters
      {
        table: params[:table],
        operation: params[:operation],
        page: params[:page]&.to_i || 1,
        per_page: params[:per_page]&.to_i || 50
      }.compact
    end

    def changes_json_data
      {
        tables_summary: @tables_summary,
        filters: @active_filters,
        session_id: @session.id
      }
    end

    def show_json_data
      {
        tables_summary: @tables_summary,
        active_tab: @active_tab,
        filters: @active_filters,
        session_id: @session.id,
        session: @session
      }
    end

    def validate_tab_parameter(tab)
      valid_tabs = %w[changes summary diagrams]
      valid_tabs.include?(tab) ? tab : "changes"
    end
  end
end
