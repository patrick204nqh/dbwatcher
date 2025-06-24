# frozen_string_literal: true

module Dbwatcher
  class Engine < ::Rails::Engine
    isolate_namespace Dbwatcher

    initializer "dbwatcher.setup" do |app|
      if Dbwatcher.configuration.enabled && !Rails.env.production?
        # Auto-include in all models
        ActiveSupport.on_load(:active_record) do
          include Dbwatcher::ModelExtension
        end

        # Add middleware
        app.middleware.use Dbwatcher::Middleware

        # Setup SQL logging if enabled
        Dbwatcher::SqlLogger.instance if Dbwatcher.configuration.track_queries
      end
    end

    # Mount the engine routes automatically
    initializer "dbwatcher.routes", after: :add_routing_paths do |app|
      app.routes.prepend do
        mount Dbwatcher::Engine => "/dbwatcher", as: :dbwatcher
      end
    end

    # Serve static assets
    initializer "dbwatcher.assets" do |app|
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      app.config.assets.paths << root.join("app", "assets", "javascripts")
      app.config.assets.precompile += %w[
        dbwatcher/core/alpine_store.js
        dbwatcher/core/api_client.js
        dbwatcher/services/mermaid.js
        dbwatcher/components/changes_table.js
        dbwatcher/components/summary.js
        dbwatcher/components/diagrams.js
      ]
    end
  end
end
