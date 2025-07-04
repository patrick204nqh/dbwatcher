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

    # Generate session ID display (wider format)
    def display_session_id(id)
      return "N/A" unless id

      # Show more characters of the session ID for better readability
      "#{id[0..15]}..."
    end
  end
end
