# frozen_string_literal: true

module Dbwatcher
  module ApplicationHelper
    include FormattingHelper
    include SessionHelper

    # Common view helpers for templates

    # Create icon HTML for stats cards
    def stats_icon(type)
      icons = {
        sessions: '<svg class="w-4 h-4 text-blue-medium" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"/>
                    <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"/>
                   </svg>',
        tables: '<svg class="w-4 h-4 text-gold-dark" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M3 3a1 1 0 000 2v8a2 2 0 002 2h2.586l-1.293 1.293a1 1 0 101.414 1.414L10 15.414l2.293 2.293a1 1 0 001.414-1.414L12.414 15H15a2 2 0 002-2V5a1 1 0 100-2H3zm11 4a1 1 0 10-2 0v4a1 1 0 102 0V7zm-3 1a1 1 0 10-2 0v3a1 1 0 102 0V8zM8 9a1 1 0 00-2 0v2a1 1 0 102 0V9z" clip-rule="evenodd"/>
                 </svg>',
        queries: '<svg class="w-4 h-4 text-blue-light" fill="currentColor" viewBox="0 0 20 20">
                   <path fill-rule="evenodd" d="M2 5a2 2 0 012-2h12a2 2 0 012 2v10a2 2 0 01-2 2H4a2 2 0 01-2-2V5zm3.293 1.293a1 1 0 011.414 0l3 3a1 1 0 010 1.414l-3 3a1 1 0 01-1.414-1.414L7.586 10 5.293 7.707a1 1 0 010-1.414zM11 12a1 1 0 100 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"/>
                  </svg>',
        performance: '<svg class="w-4 h-4 text-gold-light" fill="currentColor" viewBox="0 0 20 20">
                       <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
                      </svg>'
      }

      icons[type.to_sym]&.html_safe
    end

    # Generate operation badges for tables
    def operation_badges
      content_tag(:div, class: "flex gap-1 justify-center") do
        [
          content_tag(:span, "I", class: "badge badge-insert", title: "Inserts"),
          content_tag(:span, "U", class: "badge badge-update", title: "Updates"),
          content_tag(:span, "D", class: "badge badge-delete", title: "Deletes")
        ].join.html_safe
      end
    end

    # Create action buttons with consistent styling
    def action_button(text, path, color: "blue")
      link_to text, path, class: "px-3 py-1 text-xs bg-#{color}-600 text-white rounded hover:bg-#{color}-700"
    end

    # Safe value extraction with fallback
    def safe_value(data, key, fallback = "N/A")
      return fallback unless data.is_a?(Hash)

      data[key] || data[key.to_s] || fallback
    end

    # Format count with proper fallback
    def format_count(value)
      value.to_i.to_s
    end

    # Create empty state message
    def empty_state(message, icon: nil)
      content_tag(:div, class: "text-center py-8 text-gray-500") do
        content = []
        content << icon if icon
        content << content_tag(:p, message, class: "text-xs")
        content.join.html_safe
      end
    end
  end
end
