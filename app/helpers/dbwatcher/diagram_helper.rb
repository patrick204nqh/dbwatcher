# frozen_string_literal: true

module Dbwatcher
  module DiagramHelper
    # Generate diagram configuration for Alpine.js
    def diagram_config(session, active_tab)
      {
        auto_generate: active_tab == "diagrams",
        default_type: "database_tables",
        endpoint: diagram_data_api_v1_session_path(session),
        container_id: "diagram-container"
      }.to_json
    end

    # Generate diagram type options dynamically from registry
    def diagram_type_options
      registry = Dbwatcher::Services::DiagramTypeRegistry.new
      options = registry.available_types_with_metadata.map do |type, metadata|
        [metadata[:display_name], type]
      end

      options_for_select(options)
    end

    # Generate CSS variables for diagram container height calculation
    def diagram_container_css_variables
      {
        "--header-height": "64px",
        "--tab-bar-height": "40px",
        "--toolbar-height": "72px",
        "--footer-height": "0px",
        "--diagram-height": "calc(100vh - var(--header-height) - var(--tab-bar-height) - " \
                            "var(--toolbar-height) - var(--footer-height) - 2rem)",
        "--diagram-min-height": "500px"
      }.map { |key, value| "#{key}: #{value}" }.join("; ")
    end

    # Generate button classes for diagram controls
    def diagram_button_classes(type = :default)
      base_classes = "compact-button text-xs rounded"

      button_styles = {
        primary: "bg-blue-medium text-white px-3 py-1 hover:bg-navy-dark",
        secondary: "bg-navy-dark text-white px-2 py-1 hover:bg-blue-medium",
        toggle: "bg-blue-medium text-white px-2 py-1 hover:bg-navy-dark flex items-center gap-1",
        icon: "bg-white border border-gray-300 hover:bg-gray-50 p-1",
        danger: "bg-red-500 text-white px-2 py-1 hover:bg-red-600",
        success: "bg-green-500 text-white px-2 py-1 hover:bg-green-600"
      }

      style = button_styles[type] || button_styles[:primary]
      "#{base_classes} #{style}"
    end
  end
end
