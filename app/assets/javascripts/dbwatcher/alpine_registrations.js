/**
 * Alpine Component Registrations
 * Provides direct Alpine.js component registrations as a fallback
 */

document.addEventListener('alpine:init', function() {
  if (!window.Alpine) {
    console.error('Alpine.js not found');
    return;
  }

  // Register changesTable component
  if (window.DBWatcher && window.DBWatcher.components && window.DBWatcher.components.changesTable) {
    window.Alpine.data('changesTable', function(config = {}) {
      return window.DBWatcher.components.changesTable(config);
    });
    console.log('✅ Registered changesTable component with Alpine');
  } else {
    // Direct fallback implementation
    window.Alpine.data('changesTable', function(config = {}) {
      return {
        // Component state
        sessionId: config.sessionId || null,
        tableData: config.tableData || {},
        filters: config.filters || { search: '', operation: '', table: '' },
        showColumnSelector: null,
        tableColumns: {},

        // Initialization
        init() {
          console.log('changesTable: Fallback initialization');
          this.initializeColumns();
          this.setupFiltering();
        },

        // Initialize column visibility tracking
        initializeColumns() {
          this.tableColumns = {};
          if (this.tableData) {
            Object.keys(this.tableData).forEach((tableName) => {
              if (this.tableData[tableName] && this.tableData[tableName].columns) {
                this.tableColumns[tableName] = {};
                this.tableData[tableName].columns.forEach(column => {
                  this.tableColumns[tableName][column] = true;
                });
              }
            });
          }
        },

        // Setup filtering with debouncing
        setupFiltering() {
          // Simple debouncing implementation
          this.applyFilters = function() {
            console.log('Applying filters:', this.filters);
          };
        },

        // Clear all filters
        clearFilters() {
          this.filters = { search: '', operation: '', table: '' };
          this.applyFilters();
        },

        // Toggle column selector visibility
        toggleColumnSelector(tableName) {
          this.showColumnSelector = this.showColumnSelector === tableName ? null : tableName;
        },

        // Select all columns for a table
        selectAllColumns(tableName) {
          if (!this.tableColumns[tableName]) return;

          Object.keys(this.tableColumns[tableName]).forEach((column) => {
            this.tableColumns[tableName][column] = true;
          });
        },

        // Deselect all columns for a table
        selectNoneColumns(tableName) {
          if (!this.tableColumns[tableName]) return;

          Object.keys(this.tableColumns[tableName]).forEach((column) => {
            this.tableColumns[tableName][column] = false;
          });
        },

        // Check if column is visible
        isColumnVisible(tableName, column) {
          return this.tableColumns[tableName] &&
                 this.tableColumns[tableName][column] !== false;
        },

        // Format helpers using BaseComponent utilities
        formatTimestamp(timestamp) {
          if (!timestamp) return '';
          return new Date(timestamp).toLocaleString();
        }
      };
    });
    console.log('✅ Registered changesTable fallback with Alpine');
  }

  // Register other components as needed
  // diagrams, summary, etc.
});
