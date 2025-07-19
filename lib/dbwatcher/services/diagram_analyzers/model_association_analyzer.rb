# frozen_string_literal: true

require_relative "model_analysis/model_discovery"
require_relative "model_analysis/association_extractor"
require_relative "model_analysis/dataset_builder"
require_relative "concerns/activerecord_introspection"
require_relative "concerns/association_scope_filtering"

module Dbwatcher
  module Services
    module DiagramAnalyzers
      # Analyzes relationships based on ActiveRecord model associations
      #
      # This service examines ActiveRecord models to detect associations between
      # models that were involved in a session. It uses direct model enumeration
      # from ActiveRecord::Base.descendants to ensure reliable model discovery.
      #
      # Supported model scenarios:
      # - Regular models with standard table names
      # - Namespaced models (e.g., Admin::User)
      # - Models with custom table names (using self.table_name)
      # - Models from external gems and complex inheritance hierarchies
      #
      # @example
      #   analyzer = ModelAssociationAnalyzer.new(session)
      #   dataset = analyzer.call
      class ModelAssociationAnalyzer < BaseAnalyzer
        include Concerns::ActiverecordIntrospection
        include Concerns::AssociationScopeFiltering

        # Initialize with session
        #
        # @param session [Session] session to analyze (optional for global analysis)
        def initialize(session = nil)
          @session = session
          @session_tables = session ? extract_session_tables(session) : []
          @model_discovery = ModelAnalysis::ModelDiscovery.new(@session_tables)
          @association_extractor = ModelAnalysis::AssociationExtractor.new(@session_tables)
          @dataset_builder = ModelAnalysis::DatasetBuilder.new
          @models = []
          super()
        end

        # Analyze model associations
        #
        # @param context [Hash] analysis context
        # @return [Array<Hash>] array of association data
        def analyze(_context)
          return [] unless models_available?

          @models = @model_discovery.discover
          return [] if @models.empty?

          Rails.logger.debug "ModelAssociationAnalyzer: Starting analysis with #{@models.length} models"
          associations = @association_extractor.extract_all(@models)
          if associations.empty? && @models.any?
            associations = @association_extractor.generate_placeholder_associations(@models)
          end

          log_analysis_results(associations)
          associations
        end

        # Transform raw association data to Dataset
        #
        # @param raw_data [Array<Hash>] raw association data
        # @return [DiagramData::Dataset] standardized dataset
        def transform_to_dataset(raw_data)
          @dataset_builder.build_from_associations(raw_data, @models)
        end

        # Get analyzer type
        #
        # @return [String] analyzer type identifier
        def analyzer_type
          "model_association"
        end

        protected

        # Build analysis context for this analyzer
        #
        # @return [Hash] analysis context
        def analysis_context
          {
            session: @session,
            session_tables: @session_tables,
            models: @models
          }
        end

        private

        attr_reader :session, :session_tables, :models
        attr_reader :model_discovery, :association_extractor, :dataset_builder

        # Log analysis results for debugging
        #
        # @param associations [Array<Hash>] found associations
        # @return [void]
        def log_analysis_results(associations)
          Rails.logger.debug "ModelAssociationAnalyzer: Found #{associations.length} associations"

          if associations.any?
            sample_association = associations.first
            Rails.logger.debug "ModelAssociationAnalyzer: Sample association - " \
                               "source_model: #{sample_association[:source_model]}, " \
                               "target_model: #{sample_association[:target_model]}, " \
                               "type: #{sample_association[:type]}"
          else
            Rails.logger.info "ModelAssociationAnalyzer: No associations found"
          end
        end
      end
    end
  end
end