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
              const data = await window.ApiService.table.getChanges(this.sessionId, {
                format: 'timeline',
                include_metadata: true
              });

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

          // Setup event listeners
          setupEventListeners() {
            // Add any event listeners needed
          },

          // Setup initial view
          setupInitialView() {
            // Initialize view with all data
            this.applyFilters();
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

          // Check if entry matches table filter
          matchesTableFilter(entry) {
            if (this.filters.tables.length === 0) return true;
            return this.filters.tables.includes(entry.table_name);
          },

          // Check if entry matches search filter
          matchesSearchFilter(entry) {
            if (!this.filters.searchText) return true;
            const searchTerm = this.filters.searchText.toLowerCase();
            return (
              entry.table_name.toLowerCase().includes(searchTerm) ||
              entry.operation.toLowerCase().includes(searchTerm) ||
              (entry.details && entry.details.toLowerCase().includes(searchTerm))
            );
          },

          // Get available tables for filtering
          getAvailableTables() {
            const tables = new Set();
            this.timelineData.forEach(entry => tables.add(entry.table_name));
            return Array.from(tables).sort();
          },

          // Toggle table filter
          toggleTableFilter(tableName) {
            const index = this.filters.tables.indexOf(tableName);
            if (index === -1) {
              this.filters.tables.push(tableName);
            } else {
              this.filters.tables.splice(index, 1);
            }
            this.applyFilters();
          },

          // Clear all filters
          clearFilters() {
            this.filters.tables = [];
            this.filters.searchText = "";
            this.tableSearch = "";
            this.applyFilters();
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
          }
        });
      });
    }
  }

  // Register timeline component
  registerTimeline();
})();
