# frozen_string_literal: true

require_relative "../../logging"

module Dbwatcher
  module Services
    module SystemInfo
      # Database information collector service
      #
      # Collects database-specific information including adapter, version,
      # connection pool stats, table counts, and schema information.
      #
      # @example
      #   info = SystemInfo::DatabaseInfoCollector.call
      #   puts info[:adapter]
      #   puts info[:version]
      #   puts info[:tables].count
      #
      # This class is necessarily complex due to the comprehensive database information
      # it needs to collect across different database systems.
      # rubocop:disable Metrics/ClassLength
      class DatabaseInfoCollector
        include Dbwatcher::Logging

        # Class method to create instance and call
        #
        # @return [Hash] database information
        def self.call
          new.call
        end

        def call
          log_info "#{self.class.name}: Collecting database information"

          {
            adapter: collect_adapter_info,
            version: collect_database_version,
            connection_pool: collect_connection_pool_info,
            tables: collect_table_info,
            schema: collect_schema_info,
            indexes: collect_index_info,
            query_stats: collect_query_stats
          }
        rescue StandardError => e
          log_error "Database info collection failed: #{e.message}"
          { error: e.message }
        end

        private

        # Collect database adapter information
        #
        # @return [Hash] adapter information
        def collect_adapter_info
          return {} unless active_record_available?

          connection = ActiveRecord::Base.connection
          adapter_name = connection.adapter_name.downcase

          {
            name: adapter_name,
            pool_size: ActiveRecord::Base.connection_pool.size,
            checkout_timeout: ActiveRecord::Base.connection_pool.checkout_timeout
          }
        rescue StandardError => e
          log_error "Failed to get adapter info: #{e.message}"
          {}
        end

        # Collect database version information
        #
        # @return [String] database version
        # rubocop:disable Metrics/MethodLength
        def collect_database_version
          return nil unless active_record_available?

          connection = ActiveRecord::Base.connection
          adapter_name = connection.adapter_name.downcase

          case adapter_name
          when /mysql/
            connection.select_value("SELECT VERSION()")
          when /postgresql/
            connection.select_value("SELECT version()")
          when /sqlite/
            connection.select_value("SELECT sqlite_version()")
          else
            "unknown"
          end
        rescue StandardError => e
          log_error "Failed to get database version: #{e.message}"
          nil
        end
        # rubocop:enable Metrics/MethodLength

        # Collect connection pool information
        #
        # @return [Hash] connection pool statistics
        def collect_connection_pool_info
          return {} unless active_record_available?

          pool = ActiveRecord::Base.connection_pool
          {
            size: pool.size,
            connections: pool.connections.size,
            active: pool.active_connection?,
            checkout_timeout: pool.checkout_timeout,
            reaper_frequency: pool.reaper&.frequency
          }
        rescue StandardError => e
          log_error "Failed to get connection pool info: #{e.message}"
          {}
        end

        # Collect table information
        #
        # @return [Hash] table statistics
        # rubocop:disable Metrics/MethodLength
        def collect_table_info
          return {} unless active_record_available?

          connection = ActiveRecord::Base.connection
          tables = connection.tables

          # Skip detailed table info if performance metrics are disabled
          return { count: tables.size } unless Dbwatcher.configuration.system_info_include_performance_metrics

          table_info = { count: tables.size, tables: [] }

          tables.each do |table|
            count = connection.select_value("SELECT COUNT(*) FROM #{connection.quote_table_name(table)}").to_i
            table_info[:tables] << {
              name: table,
              count: count,
              has_primary_key: connection.primary_key(table).present?
            }
          rescue StandardError => e
            log_error "Failed to get info for table #{table}: #{e.message}"
            table_info[:tables] << { name: table, error: e.message }
          end

          table_info
        rescue StandardError => e
          log_error "Failed to get table info: #{e.message}"
          {}
        end
        # rubocop:enable Metrics/MethodLength

        # Collect schema information
        #
        # @return [Hash] schema statistics
        # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def collect_schema_info
          return {} unless active_record_available?

          # Skip schema info if performance metrics are disabled
          return {} unless Dbwatcher.configuration.system_info_include_performance_metrics

          connection = ActiveRecord::Base.connection
          schema_info = {}

          # Get schema migrations if available
          if connection.table_exists?("schema_migrations")
            begin
              versions = connection.select_values("SELECT version FROM schema_migrations ORDER BY version DESC")
              schema_info[:migrations] = {
                count: versions.size,
                latest: versions.first
              }
            rescue StandardError => e
              log_error "Failed to get schema migrations: #{e.message}"
            end
          end

          # Get schema information if available
          if defined?(ActiveRecord::InternalMetadata) && connection.table_exists?(ActiveRecord::InternalMetadata.table_name)
            begin
              # Split the long line to avoid line length issues
              query = "SELECT value FROM #{ActiveRecord::InternalMetadata.table_name} " \
                      "WHERE key = 'environment'"
              environment = connection.select_value(query)
              schema_info[:environment] = environment
            rescue StandardError => e
              log_error "Failed to get schema environment: #{e.message}"
            end
          end

          schema_info
        rescue StandardError => e
          log_error "Failed to get schema info: #{e.message}"
          {}
        end
        # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        # Collect index information
        #
        # @return [Hash] index statistics
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def collect_index_info
          return {} unless active_record_available?

          # Skip index info if performance metrics are disabled
          return {} unless Dbwatcher.configuration.system_info_include_performance_metrics

          connection = ActiveRecord::Base.connection
          tables = connection.tables
          index_info = { count: 0, tables: [] }

          tables.each do |table|
            indexes = connection.indexes(table)
            table_indexes = indexes.map do |index|
              {
                name: index.name,
                columns: index.columns,
                unique: index.unique
              }
            end

            index_info[:tables] << {
              name: table,
              indexes: table_indexes
            }
            index_info[:count] += indexes.size
          rescue StandardError => e
            log_error "Failed to get indexes for table #{table}: #{e.message}"
            index_info[:tables] << { name: table, error: e.message }
          end

          index_info
        rescue StandardError => e
          log_error "Failed to get index info: #{e.message}"
          {}
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        # Collect query statistics if available
        #
        # @return [Hash] query statistics
        def collect_query_stats
          return {} unless active_record_available?

          # This would be implementation-specific and could be expanded
          # based on the database adapter and monitoring tools available
          {}
        rescue StandardError => e
          log_error "Failed to get query stats: #{e.message}"
          {}
        end

        # Check if ActiveRecord is available and connected
        #
        # @return [Boolean] true if ActiveRecord is available and connected
        def active_record_available?
          defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?
        rescue StandardError => e
          log_error "Failed to check ActiveRecord availability: #{e.message}"
          false
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
