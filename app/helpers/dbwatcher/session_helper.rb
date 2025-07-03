# frozen_string_literal: true

module Dbwatcher
  module SessionHelper
    # Get session change count with fallback
    def session_change_count(session)
      safe_value(session, :change_count, 0).to_i
    end

    # Determine if session is active
    def session_active?(session)
      safe_value(session, :ended_at).blank?
    end

    # Format session name for display
    def display_session_name(name)
      name.to_s.gsub(/^HTTP \w+ /, "")
    end

    # Generate session ID display (truncated)
    def display_session_id(id)
      return "N/A" unless id

      "#{id[0..7]}..."
    end

    # Format timestamp for display
    def format_timestamp(timestamp)
      return "N/A" unless timestamp.present?

      time = timestamp.is_a?(String) ? Time.parse(timestamp) : timestamp
      time.strftime("%Y-%m-%d %H:%M:%S")
    end

    # Format large numbers for display
    def format_large_count(count)
      return "0" unless count.present?

      count = count.to_i
      if count > 999
        "#{count / 1000}k+"
      elsif count > 99
        "99+"
      else
        count.to_s
      end
    end
  end
end
