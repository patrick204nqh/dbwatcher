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
      # No server-side data processing - API-first architecture
    end

    def summary
      Rails.logger.info "SessionsController#summary: Loading summary for session #{@session.id}"
      # No server-side data processing - API-first architecture
    end

    def diagrams
      Rails.logger.info "SessionsController#diagrams: Loading diagrams for session #{@session.id}"
      # No server-side data processing - API-first architecture
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

    # No longer needed with API-first architecture
    # All data processing happens in API services and is loaded via JavaScript
  end
end
