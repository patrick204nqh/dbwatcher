# frozen_string_literal: true

module Dbwatcher
  module DiagramHelper
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
