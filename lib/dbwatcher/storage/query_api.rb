# frozen_string_literal: true

module Dbwatcher
  module Storage
    class QueryAPI
      def initialize(storage)
        @storage = storage
        @filters = {}
      end

      def for_date(date)
        @date = date.is_a?(String) ? date : date.strftime("%Y-%m-%d")
        self
      end

      def slow_only(threshold: 100)
        @filters[:slow_threshold] = threshold
        self
      end

      def by_table(table_name)
        @filters[:table_name] = table_name
        self
      end

      def between(start_date, end_date)
        start_str = start_date.is_a?(String) ? start_date : start_date.strftime("%Y-%m-%d")
        end_str = end_date.is_a?(String) ? end_date : end_date.strftime("%Y-%m-%d")
        @date_range = Date.parse(start_str)..Date.parse(end_str)
        self
      end

      def all
        queries = fetch_queries
        apply_filters(queries)
      end

      def create(query)
        @storage.save(query)
      end

      private

      def fetch_queries
        if @date_range
          @date_range.map { |date| @storage.load_for_date(date.strftime("%Y-%m-%d")) }.flatten
        elsif @date
          @storage.load_for_date(@date)
        else
          recent_queries
        end
      end

      def apply_filters(queries)
        result = queries
        if @filters[:slow_threshold]
          result = result.select do |q|
            q[:duration] && q[:duration] > @filters[:slow_threshold]
          end
        end
        result = result.select { |q| q[:table_name] == @filters[:table_name] } if @filters[:table_name]
        result
      end

      def recent_queries
        (0..6).map do |days_ago|
          date = (Date.today - days_ago).strftime("%Y-%m-%d")
          @storage.load_for_date(date)
        end.flatten
      end
    end
  end
end
