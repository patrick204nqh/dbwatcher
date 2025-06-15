# frozen_string_literal: true

module Dbwatcher
  module SessionHelper
    # Helper method to safely get the sessions path
    def sessions_index_path
      if respond_to?(:sessions_path)
        sessions_path
      else
        "/dbwatcher"
      end
    end

    # Format session status with appropriate styling
    def session_status_badge(status)
      css_class = case status.to_s.downcase
                  when "active"
                    "badge badge-success"
                  when "completed"
                    "badge badge-primary"
                  when "error"
                    "badge badge-danger"
                  else
                    "badge badge-secondary"
                  end

      content_tag(:span, status.to_s.capitalize, class: css_class)
    end

    # Format session duration for display
    def format_session_duration(session)
      return "N/A" unless session&.started_at

      end_time = session.ended_at || Time.current
      duration_minutes = ((end_time - session.started_at) / 60.0).round(2)

      if duration_minutes < 1
        "#{(duration_minutes * 60).round} seconds"
      elsif duration_minutes < 60
        "#{duration_minutes} minutes"
      else
        hours = (duration_minutes / 60).round(1)
        "#{hours} hours"
      end
    end

    # Generate session summary info
    def session_summary_info(session)
      return {} unless session

      {
        id: session.id,
        status: session.status,
        changes_count: session.changes.length,
        tables_count: session.changes.map { |c| c[:table_name] }.uniq.length,
        duration: format_session_duration(session),
        started_at: session.started_at
      }
    end
  end
end
