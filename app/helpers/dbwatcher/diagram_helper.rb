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

    # Generate a code view with syntax highlighting for Mermaid code
    def diagram_code_view(content)
      content_tag(:div, class: "diagram-code-view") do
        content_tag(:pre,
                    class: "text-xs font-mono p-4 bg-gray-50 rounded border border-gray-200 " \
                           "overflow-x-auto whitespace-pre-wrap",
                    style: "max-height: calc(100vh - 220px); overflow-y: auto;") do
          content_tag(:code, content)
        end
      end
    end

    # Generate copy to clipboard button
    def copy_to_clipboard_button(target_id)
      button_tag(
        type: "button",
        class: diagram_button_classes(:icon),
        "x-on:click": "copyToClipboard('#{target_id}')",
        title: "Copy to clipboard"
      ) do
        copy_icon_svg
      end
    end

    private

    # Generate copy icon SVG
    def copy_icon_svg
      content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        tag.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: "M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2" \
             "M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
        )
      end
    end

    # Generate toggle view button
    def toggle_view_button
      button_tag(
        type: "button",
        class: diagram_button_classes(:toggle),
        "x-on:click": "toggleViewMode()",
        title: "Toggle between code and preview"
      ) do
        concat(content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2",
                   d: "M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4")
        end)
        concat(content_tag(:span, "x-text": "viewMode === 'preview' ? 'View Code' : 'View Preview'"))
      end
    end
  end
end
