# frozen_string_literal: true

module Dbwatcher
  module Services
    # Service object for filtering and sorting queries based on criteria
    # Implements the strategy pattern for different filter types
    class QueryFilterProcessor
      include Dbwatcher::Logging

      attr_reader :queries, :filter_params

      # @param queries [Array<Hash>] the queries to filter
      # @param filter_params [Hash] filtering parameters
      def initialize(queries, filter_params)
        @queries = queries
        @filter_params = filter_params
      end

      # @param queries [Array<Hash>] queries to filter
      # @param filter_params [Hash] filtering parameters
      # @return [Array<Hash>] filtered and sorted queries
      def self.call(queries, filter_params)
        new(queries, filter_params).call
      end

      def call
        log_filtering_start
        start_time = Time.current

        result = apply_all_filters
        log_filtering_completion(start_time, result)

        result
      end

      private

      def log_filtering_start
        log_info "Starting query filtering", {
          initial_count: queries.length,
          filters: active_filters.join(", ")
        }
      end

      def apply_all_filters
        queries
          .then { |q| apply_operation_filter(q) }
          .then { |q| apply_table_filter(q) }
          .then { |q| apply_duration_filter(q) }
          .then { |q| sort_by_timestamp_descending(q) }
      end

      def log_filtering_completion(start_time, result)
        duration = Time.current - start_time
        log_info "Completed query filtering in #{duration.round(3)}s", {
          final_count: result.length,
          filtered_out: queries.length - result.length
        }
      end

      def apply_operation_filter(queries)
        return queries unless filter_params[:operation].present?

        queries.select { |query| matches_operation?(query) }
      end

      def matches_operation?(query)
        query[:operation] == filter_params[:operation]
      end

      def apply_table_filter(queries)
        return queries unless filter_params[:table].present?

        queries.select { |query| includes_table?(query) }
      end

      def includes_table?(query)
        query[:tables]&.include?(filter_params[:table])
      end

      def apply_duration_filter(queries)
        return queries unless filter_params[:min_duration].present?

        min_duration_threshold = filter_params[:min_duration].to_f
        queries.select { |query| exceeds_duration_threshold?(query, min_duration_threshold) }
      end

      def exceeds_duration_threshold?(query, threshold)
        duration = query[:duration]
        duration && duration >= threshold
      end

      def sort_by_timestamp_descending(queries)
        queries.sort_by { |query| timestamp_for_sorting(query) }.reverse
      end

      def timestamp_for_sorting(query)
        return 0 unless query[:timestamp]

        Time.parse(query[:timestamp]).to_i
      rescue ArgumentError
        0
      end

      def active_filters
        filters = []
        filters << "operation=#{filter_params[:operation]}" if filter_params[:operation].present?
        filters << "table=#{filter_params[:table]}" if filter_params[:table].present?
        filters << "min_duration=#{filter_params[:min_duration]}" if filter_params[:min_duration].present?
        filters.empty? ? ["none"] : filters
      end
    end
  end
end
