# frozen_string_literal: true

module Dbwatcher
  module Storage
    module DateHelper
      DEFAULT_CLEANUP_DAYS = 30

      def format_date(timestamp)
        timestamp.strftime("%Y-%m-%d")
      end

      def cleanup_cutoff_date(days_to_keep = DEFAULT_CLEANUP_DAYS)
        Time.now - (days_to_keep * 24 * 60 * 60)
      end

      def date_file_path(base_path, date)
        File.join(base_path, "#{date}.json")
      end
    end
  end
end
