# frozen_string_literal: true

require_relative "base_api"

module Dbwatcher
  module Storage
    module Api
      class QueryAPI < BaseAPI
        # Filter queries by date
        #
        # @param date [Date, String] date to filter by
        # @return [QueryAPI] self for method chaining
        def for_date(date)
          @date = date.is_a?(String) ? date : date.strftime("%Y-%m-%d")
          self
        end

        # Filter to slow queries only
        #
        # @param threshold [Integer] duration threshold in milliseconds
        # @return [QueryAPI] self for method chaining
        def slow_only(threshold: 100)
          filters[:slow_threshold] = threshold
          self
        end

        # Filter queries by table name
        #
        # @param table_name [String] table name to filter by
        # @return [QueryAPI] self for method chaining
        def by_table(table_name)
          filters[:table_name] = table_name
          self
        end

        # Filter queries between dates
        #
        # @param start_date [Date, String] start date
        # @param end_date [Date, String] end date
        # @return [QueryAPI] self for method chaining
        def between(start_date, end_date)
          start_str = start_date.is_a?(String) ? start_date : start_date.strftime("%Y-%m-%d")
          end_str = end_date.is_a?(String) ? end_date : end_date.strftime("%Y-%m-%d")
          @date_range = Date.parse(start_str)..Date.parse(end_str)
          self
        end

        # Get all filtered queries
        #
        # @return [Array<Hash>] filtered queries
        def all
          queries = fetch_queries
          apply_filters(queries)
        end

        private

        def fetch_queries
          if @date_range
            @date_range.map { |date| storage.load_for_date(date.strftime("%Y-%m-%d")) }.flatten
          elsif @date
            storage.load_for_date(@date)
          else
            recent_queries
          end
        end

        def apply_filters(queries)
          result = queries

          # Apply slow threshold filter using symbols only
          if filters[:slow_threshold]
            result = result.select do |q|
              duration = safe_extract(q, :duration)
              duration && duration > filters[:slow_threshold]
            end
          end

          # Apply table name filter using symbols only
          result = result.select { |q| safe_extract(q, :table_name) == filters[:table_name] } if filters[:table_name]

          # Apply common filters
          apply_common_filters(result)
        end

        def recent_queries
          (0..6).map do |days_ago|
            date = (Date.today - days_ago).strftime("%Y-%m-%d")
            storage.load_for_date(date)
          end.flatten
        end
      end
    end
  end
end
