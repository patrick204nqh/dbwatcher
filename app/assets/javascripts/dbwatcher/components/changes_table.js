/**
 * Changes Table Alpine.js Component
 *
 * Handles table interactions, filtering, and column visibility
 * using centralized Alpine store and modern APIs
 */

document.addEventListener('alpine:init', () => {
  Alpine.data('changesTable', (config) => ({
    // Initialize from config
    sessionId: config.session_id,
    tablesData: config.tables_summary || {},

    // Local state
    filters: config.active_filters || {},
    loading: false,
    error: null,

    // Debounced filter application
    applyFilters: null,

    init() {
      // Initialize table columns in store
      Alpine.store('session').initializeTableColumns(this.tablesData);

      // Setup debounced filter application
      this.applyFilters = this.debounce(async () => {
        await this.loadFilteredData();
      }, 300);

      // Setup intersection observer for performance
      this.setupIntersectionObserver();
    },

    // Load filtered data via API
    async loadFilteredData() {
      if (!this.sessionId) return;

      this.loading = true;
      this.error = null;

      try {
        const endpoint = `/sessions/${this.sessionId}/changes_data`;
        const data = await Alpine.store('session').loadData(endpoint, this.filters);

        // Update tables data
        if (data.tables_summary) {
          this.tablesData = data.tables_summary;
          Alpine.store('session').initializeTableColumns(this.tablesData);
        }
      } catch (error) {
        this.error = error.message;
        console.error('Failed to load filtered data:', error);
      } finally {
        this.loading = false;
      }
    },

    // Clear all filters
    clearFilters() {
      this.filters = {};
      this.applyFilters();
    },

    // Scroll to specific table
    scrollToTable(tableName) {
      const element = document.getElementById(`table-${tableName}`);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    },

    // Column visibility methods (delegated to store)
    get showColumnSelector() {
      return Alpine.store('session').showColumnSelector;
    },

    get tableColumns() {
      return Alpine.store('session').tableColumns;
    },

    toggleColumnSelector(tableName) {
      Alpine.store('session').toggleColumnSelector(tableName);
    },

    selectAllColumns(tableName) {
      Alpine.store('session').selectAllColumns(tableName);
    },

    selectNoneColumns(tableName) {
      Alpine.store('session').selectNoneColumns(tableName);
    },

    // Setup intersection observer for performance optimization
    setupIntersectionObserver() {
      if (!window.IntersectionObserver) return;

      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          const tableElement = entry.target;
          const tableName = tableElement.getAttribute('data-table-name');

          if (entry.isIntersecting) {
            // Table is visible - could load additional data if needed
            tableElement.classList.add('table-visible');
          } else {
            tableElement.classList.remove('table-visible');
          }
        });
      }, {
        root: null,
        rootMargin: '50px',
        threshold: 0.1
      });

      // Observe table containers
      this.$nextTick(() => {
        const tables = this.$el.querySelectorAll('[data-table-name]');
        tables.forEach(table => observer.observe(table));
      });
    },

    // Utility: Debounce function
    debounce(func, wait) {
      let timeout;
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout);
          func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
      };
    },

    // Format helpers
    formatTimestamp(timestamp) {
      if (!timestamp) return '--';

      try {
        const date = new Date(timestamp);
        return date.toLocaleTimeString('en-US', {
          hour12: false,
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        });
      } catch (error) {
        return timestamp;
      }
    },

    // Get operation badge class
    getOperationClass(operation) {
      if (!operation) return 'badge';

      const op = operation.toLowerCase();
      return `badge badge-${op}`;
    },

    // Check if column has changes
    hasColumnChanges(change, column) {
      const columnChanges = change.changes || [];
      return columnChanges.some(c =>
        (c.column || c.column) === column.toString()
      );
    }
  }));
});
