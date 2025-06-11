# frozen_string_literal: true

module Dbwatcher
  class Engine < ::Rails::Engine
    isolate_namespace Dbwatcher

    initializer "dbwatcher.setup" do |app|
      # Auto-include in all models
      ActiveSupport.on_load(:active_record) do
        include Dbwatcher::ModelExtension
      end

      # Add middleware
      app.middleware.use Dbwatcher::Middleware
    end

    # Mount the engine routes automatically
    initializer "dbwatcher.routes", after: :add_routing_paths do |app|
      app.routes.append do
        mount Dbwatcher::Engine => "/dbwatcher", as: :dbwatcher
      end
    end

    # Serve static assets
    initializer "dbwatcher.assets" do |app|
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      app.config.assets.paths << root.join("app", "assets", "javascripts")
    end
  end
end
