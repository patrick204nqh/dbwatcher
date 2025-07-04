# frozen_string_literal: true

module Dbwatcher
  module Services
    module Api
      # Service for handling summary statistics data
      #
      # Provides enhanced summary data for the sessions summary view and API endpoints
      # with caching and comprehensive statistics.
      class SummaryDataService < BaseApiService
        def call
          start_time = Time.now
          log_service_start("Getting summary data for session #{session.id}")

          validation_error = validate_session
          return validation_error if validation_error

          begin
            result = with_cache do
              build_summary_response
            end

            log_service_completion(start_time, session_id: session.id)
            result
          rescue StandardError => e
            handle_error(e)
          end
        end

        private

        def build_summary_response
          summary_data = base_summary

          return summary_data if summary_data[:error]

          enhance_summary_data(summary_data)
        end

        def base_summary
          result = Storage.sessions.summary(session.id)

          if result[:error]
            log_error "Base summary error: #{result[:error]}"
            return { error: result[:error] }
          end

          result
        end

        def enhance_summary_data(base_summary)
          tables_summary = Storage.sessions.build_tables_summary(session)

          base_summary.merge(
            session_id: session.id,
            enhanced_stats: build_enhanced_stats(tables_summary),
            tables_breakdown: build_tables_breakdown(tables_summary),
            metadata: build_metadata,
            timing: build_timing_info
          )
        end

        def build_enhanced_stats(tables_summary)
          {
            tables_count: tables_summary.keys.length,
            total_changes: calculate_total_changes(tables_summary),
            operations_breakdown: calculate_operations_breakdown(tables_summary),
            tables_with_changes: tables_summary.keys,
            most_active_table: find_most_active_table(tables_summary),
            change_distribution: calculate_change_distribution(tables_summary)
          }
        end

        def build_tables_breakdown(tables_summary)
          tables_data = tables_summary.map do |table_name, data|
            {
              table_name: table_name,
              change_count: data[:changes]&.length || 0,
              operations: data[:operations] || {},
              sample_columns: data[:sample_record]&.keys || []
            }
          end
          tables_data.sort_by { |table| -table[:change_count] }
        end

        def build_metadata
          {
            generated_at: Time.current,
            cache_key: cache_key,
            data_freshness: "cached"
          }
        end

        def calculate_total_changes(tables_summary)
          tables_summary.values.sum { |data| data[:changes]&.length || 0 }
        end

        def calculate_operations_breakdown(tables_summary)
          operations = { "INSERT" => 0, "UPDATE" => 0, "DELETE" => 0 }

          tables_summary.each_value do |data|
            data[:operations]&.each do |op, count|
              normalized_op = op.to_s.upcase
              operations[normalized_op] += count if operations.key?(normalized_op)
            end
          end

          operations
        end

        def find_most_active_table(tables_summary)
          return nil if tables_summary.empty?

          most_active = tables_summary.max_by do |_, data|
            data[:changes]&.length || 0
          end

          {
            table_name: most_active[0],
            change_count: most_active[1][:changes]&.length || 0
          }
        end

        def calculate_change_distribution(tables_summary)
          total_changes = calculate_total_changes(tables_summary)
          return {} if total_changes.zero?

          distribution = {}
          tables_summary.each do |table_name, data|
            change_count = data[:changes]&.length || 0
            percentage = (change_count.to_f / total_changes * 100).round(2)
            distribution[table_name] = {
              count: change_count,
              percentage: percentage
            }
          end

          distribution
        end

        def build_timing_info
          {
            started_at: session.started_at,
            ended_at: session.ended_at,
            duration: calculate_duration
          }
        end

        def calculate_duration
          return nil unless session.started_at

          end_time = session.ended_at || Time.current
          ((end_time.to_time - session.started_at.to_time) * 1000).round
        end
      end
    end
  end
end
