# frozen_string_literal: true

module Dbwatcher
  module DiagramHelper
    # Generate diagram configuration for Alpine.js
    def diagram_config(session, active_tab)
      {
        auto_generate: active_tab == "diagrams",
        default_type: "database_tables",
        endpoint: diagram_path(session),
        container_id: "diagram-container"
      }.to_json
    end

    # Generate diagram type options
    def diagram_type_options
      options = [
        ["Database Tables (Schema)", "database_tables"],
        ["Model Associations", "model_associations"]
      ]

      options_for_select(options)
    end

    # Generate CSS variables for diagram container height calculation
    def diagram_container_css_variables
      {
        "--header-height": "64px",
        "--tab-bar-height": "40px",
        "--toolbar-height": "72px",
        "--footer-height": "0px",
        "--diagram-height": "calc(100vh - var(--header-height) - var(--tab-bar-height) - var(--toolbar-height) - var(--footer-height) - 2rem)",
        "--diagram-min-height": "500px"
      }.map { |key, value| "#{key}: #{value}" }.join("; ")
    end

    # Generate button classes for diagram controls
    def diagram_button_classes(type = :default)
      base_classes = "compact-button"

      case type
      when :primary
        "#{base_classes} bg-blue-medium text-white hover:bg-blue-dark"
      when :secondary
        "#{base_classes} bg-white border border-gray-300 hover:bg-gray-50"
      when :toggle
        "#{base_classes} bg-white border border-gray-300 hover:bg-gray-50 flex items-center gap-1"
      when :icon
        "#{base_classes} bg-white border border-gray-300 hover:bg-gray-50 p-1"
      else
        base_classes
      end
    end

    # Generate a code view with syntax highlighting for Mermaid code
    def mermaid_code_view(content)
      return "" if content.blank?

      content_tag(:pre, class: "language-mermaid p-4 bg-gray-800 text-white rounded overflow-auto") do
        content_tag(:code, content)
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
        content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2",
                   d: "M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3")
        end
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
