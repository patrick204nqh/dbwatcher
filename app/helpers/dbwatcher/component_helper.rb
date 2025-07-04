# frozen_string_literal: true

module Dbwatcher
  module ComponentHelper
    # Removed as part of API-first migration (Story 6.8)
    # All data is now loaded directly from API endpoints

    # Removed as part of API-first migration (Story 6.8)
    # All data is now loaded directly from API endpoints

    # Removed as part of API-first migration (Story 6.8)
    # All data is now loaded directly from API endpoints

    # Generate data attributes for component binding
    def dbwatcher_component(component_name, config)
      {
        "data-dbwatcher" => component_name,
        "data-config" => config.to_json
      }
    end

    # Helper to render a DBWatcher component
    def render_dbwatcher_component(component_name, config, html_options = {})
      content_tag :div, dbwatcher_component(component_name, config).merge(html_options) do
        yield if block_given?
      end
    end
  end
end
