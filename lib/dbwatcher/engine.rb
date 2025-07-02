# frozen_string_literal: true

module Dbwatcher
  class Engine < ::Rails::Engine
    isolate_namespace Dbwatcher

    # Configure autoload paths
    config.autoload_paths += %W[
      #{root}/lib
    ]

    # Serve static assets
    initializer "dbwatcher.assets", before: :add_to_load_path do |app|
      # Define asset paths
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      app.config.assets.paths << root.join("app", "assets", "javascripts")
    end

    initializer "dbwatcher.setup" do |app|
      if Dbwatcher.configuration.enabled
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
  end
end
