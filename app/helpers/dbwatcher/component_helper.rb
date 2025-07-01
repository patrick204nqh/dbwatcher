module Dbwatcher
  module ComponentHelper
    # Generate configuration for changes table component
    def changes_table_config(session, tables_summary)
      {
        sessionId: session.id,
        tableData: tables_summary.transform_values do |summary|
          {
            columns: summary[:sample_record]&.keys || [],
            operations: summary[:operations] || {},
            changes: summary[:changes] || [],
            total_changes: summary[:total_changes] || 0
          }
        end,
        filters: {
          search: "",
          operation: "",
          table: ""
        }
      }
    end

    # Generate configuration for diagram component
    def diagram_config(session, diagram_types)
      {
        sessionId: session&.id,
        availableTypes: diagram_types || {},
        selectedType: params[:diagram_type] || "database_tables"
      }
    end

    # Generate configuration for summary component
    def summary_config(session, summary_data)
      {
        sessionId: session.id,
        summaryData: summary_data || {},
        autoRefresh: false
      }
    end

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
