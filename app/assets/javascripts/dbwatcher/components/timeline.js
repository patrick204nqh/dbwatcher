/**
 * Timeline Component
 * Interactive timeline visualization for database operations
 * API-first implementation for DBWatcher timeline tab
 */

// Register component with DBWatcher
(function() {
  function registerTimeline() {
    if (window.DBWatcher && window.DBWatcher.ComponentRegistry) {
      DBWatcher.ComponentRegistry.register('timeline', function(config) {
        return Object.assign(DBWatcher.BaseComponent(config), {
          // Component-specific state
          sessionId: config.sessionId,
          timelineData: [],
          filteredData: [],
          metadata: {},

          // Filter state
          filters: {
            tables: [],
            searchText: ""
          },
          tableSearch: "",

          // Component initialization
          componentInit() {
            this.loadTimelineData();
            this.setupEventListeners();
          },

          // Component cleanup
          componentDestroy() {
            // Clean up any event listeners or intervals
          },

          // Load timeline data from API
          async loadTimelineData() {
            if (!this.sessionId) {
              console.error('No session ID provided to timeline component');
              this.handleError(new Error('No session ID provided'));
              return;
            }

            this.setLoading(true);
            this.clearError();

            try {
              const url = `/dbwatcher/api/v1/sessions/${this.sessionId}/timeline_data`;
              const data = await this.fetchData(url);

              if (!data.error) {
                this.timelineData = data.timeline || [];
                this.metadata = data.metadata || {};
                this.filteredData = [...this.timelineData];

                this.setupInitialView();
              } else {
                throw new Error(data.error || 'No timeline data received');
              }
            } catch (error) {
              this.handleError(error);
            } finally {
              this.setLoading(false);
            }
          },

          // Setup initial view after data load
          setupInitialView() {
            // Initialize filters based on available data
            if (this.metadata.tables_affected) {
              // Set up available filter options but don't apply any filters initially
            }
          },

          // Setup event listeners
          setupEventListeners() {
            // Reserved for future keyboard shortcuts
          },

          // ==========================================
          // Filtering functionality
          // ==========================================

          // Apply all filters to timeline data
          applyFilters() {
            this.filteredData = this.timelineData.filter((entry) => {
              return (
                this.matchesTableFilter(entry) &&
                this.matchesSearchFilter(entry)
              );
            });
          },

          // Filter by table name
          matchesTableFilter(entry) {
            return (
              this.filters.tables.length === 0 ||
              this.filters.tables.includes(entry.table_name)
            );
          },

          // Filter by search text
          matchesSearchFilter(entry) {
            if (!this.filters.searchText) return true;

            const searchLower = this.filters.searchText.toLowerCase();
            return (
              entry.table_name.toLowerCase().includes(searchLower) ||
              entry.operation.toLowerCase().includes(searchLower) ||
              (entry.record_id && entry.record_id.toString().includes(searchLower))
            );
          },

          // Clear all filters
          clearFilters() {
            this.filters = {
              tables: [],
              searchText: ""
            };
            this.applyFilters();
          },

          // ==========================================
          // Utility methods
          // ==========================================

          // Format timestamp for display
          formatTimestamp(timestamp) {
            if (!timestamp) return 'N/A';
            return this.formatDate(new Date(timestamp), 'MMM dd, yyyy HH:mm:ss');
          },

          // Format duration in milliseconds
          formatDuration(ms) {
            if (!ms || ms < 0) return '0ms';
            if (ms < 1000) return `${ms}ms`;
            if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
            return `${(ms / 60000).toFixed(1)}m`;
          },

          // Get color for operation type
          getOperationColor(operation) {
            const colors = {
              INSERT: "#10b981", // green
              UPDATE: "#f59e0b", // amber
              DELETE: "#ef4444", // red
              SELECT: "#3b82f6"  // blue
            };
            return colors[operation] || "#6b7280";
          },

          // Get operation icon
          getOperationIcon(operation) {
            const icons = {
              INSERT: "plus",
              UPDATE: "pencil",
              DELETE: "trash",
              SELECT: "eye"
            };
            return icons[operation] || "circle";
          },

          // Get available tables for filtering
          getAvailableTables() {
            return this.metadata.tables_affected || [];
          },

          // Get available operations for filtering
          getAvailableOperations() {
            return Object.keys(this.metadata.operation_counts || {});
          },

          // Get operation count for display
          getOperationCount(operation) {
            return this.metadata.operation_counts?.[operation] || 0;
          },

          // Get total filtered operations count
          getTotalFilteredOperations() {
            return this.filteredData.length;
          },

          // Get session statistics
          getSessionStats() {
            return {
              totalOperations: this.timelineData.length,
              filteredOperations: this.filteredData.length,
              tablesAffected: this.getAvailableTables().length,
              sessionDuration: this.metadata.session_duration || 'N/A',
              timeRange: this.metadata.time_range || {}
            };
          },

          // Format relative time from session start
          formatRelativeTime(operation) {
            if (!operation) return '00:00';
            return operation.relative_time || '00:00';
          }
        });  // End of Object.assign
      });  // End of registerComponent
      console.log('✅ Timeline component registered successfully');
    } else {
      console.warn('DBWatcher ComponentRegistry not ready, retrying timeline registration...');
      setTimeout(registerTimeline, 100);
    }
  }

  // Register immediately without waiting for DOM
  registerTimeline();
})();
