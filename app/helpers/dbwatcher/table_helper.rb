# frozen_string_literal: true

module Dbwatcher
  module TableHelper
    # Format table name for display
    def format_table_name(table_name)
      return "Unknown" if table_name.blank?

      table_name.humanize.titleize
    end

    # Format change count with appropriate styling
    def format_change_count(count)
      css_class = case count
                  when 0
                    "text-muted"
                  when 1..10
                    "text-info"
                  when 11..50
                    "text-warning"
                  else
                    "text-danger"
                  end

      content_tag(:span, count, class: css_class)
    end

    # Format table last change timestamp
    def format_table_last_change(timestamp)
      return "Never" unless timestamp

      if timestamp.is_a?(String)
        timestamp = begin
          Time.parse(timestamp)
        rescue StandardError
          nil
        end
      end

      return "Invalid date" unless timestamp

      "#{time_ago_in_words(timestamp)} ago"
    end

    # Generate table status badge
    def table_status_badge(change_count)
      status, css_class = case change_count
                          when 0
                            ["Inactive", "badge badge-secondary"]
                          when 1..10
                            ["Low Activity", "badge badge-info"]
                          when 11..50
                            ["Active", "badge badge-warning"]
                          else
                            ["High Activity", "badge badge-danger"]
                          end

      content_tag(:span, status, class: css_class)
    end

    # Format record ID for display
    def format_record_id(record_id)
      return "N/A" if record_id.blank?

      if record_id.to_s.length > 10
        "#{record_id.to_s[0..7]}..."
      else
        record_id.to_s
      end
    end

    # Group changes by record for table view
    def group_changes_by_record(changes)
      changes.group_by { |c| c[:record_id] }
    end

    # Extract unique session IDs from changes
    def extract_session_ids(changes)
      changes.map { |c| c[:session_id] }.uniq
    end
  end
end
