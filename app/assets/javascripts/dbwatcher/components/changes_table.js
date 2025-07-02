/**
 * Changes Table Component
 * Simplified component using DBWatcher base architecture
 */

// Register component with DBWatcher
DBWatcher.registerComponent('changesTable', function(config) {
  const baseComponent = DBWatcher.BaseComponent ? DBWatcher.BaseComponent(config) : {};

  return {
    // Include BaseComponent
    ...baseComponent,

    // Component-specific state
    sessionId: config.sessionId || null,
    tableData: config.tableData || {},
    filters: config.filters || {
      search: '',
      operation: '',
      table: ''
    },
    showColumnSelector: null,

    // Alpine init hook (auto-called by Alpine.js)
    init() {
      // Initialize columns
      this.initializeColumns();

      // Setup filtering
      this.setupFiltering();

      // Call base init if it exists
      if (baseComponent.init) {
        baseComponent.init.call(this);
      }
    },
    tableColumns: {},
    expandedRows: {},

    // Component initialization
    componentInit() {
      // Initialize columns and filters
      this.initializeColumns();
      this.setupFiltering();

      console.log('Changes table component initialized with',
        Object.keys(this.tableData).length, 'tables');
    },

    // Initialize column visibility tracking
    initializeColumns() {
      this.tableColumns = {};
      Object.keys(this.tableData || {}).forEach((tableName) => {
        this.tableColumns[tableName] = {};
        const columns = this.tableData[tableName]?.columns || [];
        columns.forEach((col) => {
          this.tableColumns[tableName][col] = true;
        });
      });
    },

    // Setup filtering with debouncing
    setupFiltering() {
      // Use library debouncing from BaseComponent
      this.applyFilters = this.debounce(() => {
        this.dispatchEvent("table-filtered", { filters: this.filters });
      }, 300);
    },

    // Clear all filters
    clearFilters() {
      this.filters = {};
      this.applyFilters();
    },

    // Toggle column selector visibility
    toggleColumnSelector(tableName) {
      this.showColumnSelector =
        this.showColumnSelector === tableName ? null : tableName;
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

    // Get visible columns for a table
    getVisibleColumns(tableName) {
      if (!this.tableColumns[tableName]) return [];

      return Object.keys(this.tableColumns[tableName])
        .filter(col => this.tableColumns[tableName][col]);
    },

    // Format helpers using BaseComponent utilities
    formatTimestamp(timestamp) {
      if (!timestamp) return '--';
      return this.formatTime(timestamp);
    },

    // Get operation badge class
    getOperationClass(operation) {
      if (!operation) return 'badge';
      const op = operation.toLowerCase();
      return `badge badge-${op}`;
    },

    // Check if there are any visible changes
    hasVisibleChanges() {
      return Object.keys(this.tableData).some(tableName => {
        const data = this.tableData[tableName];
        return data.changes && data.changes.length > 0;
      });
    },

    // Get filtered table count
    getFilteredTableCount() {
      return Object.keys(this.tableData).filter(tableName => {
        const data = this.tableData[tableName];
        return data.changes && data.changes.length > 0;
      }).length;
    },

    // JSON utility functions for better data display
    isJsonValue(value) {
      if (typeof value !== 'string') return false;
      try {
        const parsed = JSON.parse(value);
        return typeof parsed === 'object' && parsed !== null;
      } catch {
        return false;
      }
    },

    formatJsonValue(value) {
      if (!value) return 'No value';
      try {
        if (typeof value === 'string') {
          const parsed = JSON.parse(value);
          return JSON.stringify(parsed, null, 2);
        }
        return JSON.stringify(value, null, 2);
      } catch {
        return value;
      }
    },

    // Check if a column was changed in an UPDATE operation
    isColumnChanged(change, column) {
      return change.operation === 'UPDATE' &&
             change.changes &&
             change.changes.find(c => c.column === column);
    },

    // Get the value for a column (handles both changed and unchanged)
    getColumnValue(change, column, type = 'current') {
      if (change.operation === 'UPDATE' && change.changes) {
        const columnChange = change.changes.find(c => c.column === column);
        if (columnChange) {
          return type === 'old' ? columnChange.old_value : columnChange.new_value;
        }
      }
      return change.record_snapshot?.[column];
    }
  };
});
