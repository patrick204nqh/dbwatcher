/**
 * Changes Table Component
 * API-first implementation for DBWatcher changes tab
 */

// Register component with DBWatcher
DBWatcher.registerComponent('changesTable', function(config) {
  const baseComponent = DBWatcher.BaseComponent ? DBWatcher.BaseComponent(config) : {};

  return {
    // Include BaseComponent
    ...baseComponent,

    // Component-specific state
    sessionId: config.sessionId || null,
    tableData: {},
    filters: {
      search: '',
      operation: '',
      table: ''
      // No pagination - we want full dataset
    },
    showColumnSelector: null,

    // Alpine init hook (auto-called by Alpine.js)
    init() {
      // Initialize empty state
      this.tableColumns = {};
      this.expandedRows = {};

      // Setup filtering
      this.setupFiltering();

      // Load data from API
      this.loadChangesData();

      // Setup URL state sync
      this.setupURLStateSync();

      // Call base init if it exists
      if (baseComponent.init) {
        baseComponent.init.call(this);
      }
    },
    tableColumns: {},
    expandedRows: {},

    // Component initialization
    componentInit() {
      console.log('Changes table component initialized, loading data from API');
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
        this.loadChangesData();
        this.updateURL();
      }, 300);
    },

    // Load data from API
    async loadChangesData() {
      if (!this.sessionId) {
        console.error('No session ID provided to changes table component');
        this.handleError(new Error('No session ID provided'));
        return;
      }

      this.setLoading(true);
      this.clearError();

      try {
        // Build query parameters from filters
        const params = new URLSearchParams();
        if (this.filters.table) params.append('table', this.filters.table);
        if (this.filters.operation) params.append('operation', this.filters.operation);
        if (this.filters.search) params.append('search', this.filters.search);

        // Always request full dataset (no pagination)

        const url = `/dbwatcher/api/v1/sessions/${this.sessionId}/changes_data?${params.toString()}`;
        const data = await this.fetchData(url);

        if (data.tables_summary) {
          this.tableData = data.tables_summary;
          this.initializeColumns();
        } else {
          throw new Error('No changes data received');
        }
      } catch (error) {
        this.handleError(error);
      } finally {
        this.setLoading(false);
      }
    },

    // Setup URL state synchronization
    setupURLStateSync() {
      // Read initial filters from URL if present
      const urlParams = new URLSearchParams(window.location.search);
      const tableParam = urlParams.get('table');
      const operationParam = urlParams.get('operation');

      if (tableParam) this.filters.table = tableParam;
      if (operationParam) this.filters.operation = operationParam;
    },

    // Update URL with current filters
    updateURL() {
      const url = new URL(window.location.href);
      const params = new URLSearchParams(url.search);

      // Update or remove parameters based on filter state
      if (this.filters.table) {
        params.set('table', this.filters.table);
      } else {
        params.delete('table');
      }

      if (this.filters.operation) {
        params.set('operation', this.filters.operation);
      } else {
        params.delete('operation');
      }

      // Update URL without full page reload
      url.search = params.toString();
      window.history.replaceState({}, '', url.toString());
    },

    // Clear all filters
    clearFilters() {
      this.filters = {
        search: '',
        operation: '',
        table: ''
      };
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
