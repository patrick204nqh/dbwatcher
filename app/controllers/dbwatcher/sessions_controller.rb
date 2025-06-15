# frozen_string_literal: true

module Dbwatcher
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception
    layout "dbwatcher/application"

    def index
      @sessions = Storage.sessions.all
    end

    def show
      log_session_loading
      @session = load_session

      return handle_session_not_found unless @session

      prepare_session_data
      render_response
    end

    def log_session_loading
      Rails.logger.info "SessionsController#show: Loading session with ID: #{params[:id]}"
    end

    def load_session
      session = Storage.sessions.find(params[:id])
      Rails.logger.info "SessionsController#show: Loaded session: #{session.inspect}"
      session
    end

    def handle_session_not_found
      Rails.logger.warn "SessionsController#show: Session not found for ID: #{params[:id]}"
      redirect_to sessions_path, alert: "Session not found"
    end

    def prepare_session_data
      @tables_summary = Storage.sessions.build_tables_summary(@session)
      Rails.logger.info "SessionsController#show: Tables summary: #{@tables_summary.inspect}"
    end

    def render_response
      respond_to do |format|
        format.html
        format.json { render json: @session.to_h }
      end
    end

    def destroy_all
      Dbwatcher.reset!
      redirect_to main_app.root_path, notice: "All sessions cleared"
    end

    private

    # Helper method to safely get the sessions path
    def sessions_index_path
      if respond_to?(:sessions_path)
        sessions_path
      else
        "/dbwatcher"
      end
    end
    helper_method :sessions_index_path
  end
end
