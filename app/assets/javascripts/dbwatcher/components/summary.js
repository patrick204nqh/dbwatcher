/**
 * Summary Component
 * API-first implementation for DBWatcher summary tab
 */

// Register component with DBWatcher
DBWatcher.registerComponent('summary', function(config) {
  return Object.assign(DBWatcher.BaseComponent(config), {
    // Component-specific state
    sessionId: config.sessionId,
    summaryData: {},
    autoRefresh: config.autoRefresh || false,
    refreshInterval: null,

    // Component initialization
    componentInit() {
      // Always load from API in API-first architecture
      this.loadSummaryData();

      // Setup auto-refresh if enabled
      if (this.autoRefresh) {
        this.startAutoRefresh();
      }
    },

    // Load summary data from API
    async loadSummaryData() {
      if (!this.sessionId) {
        console.error('No session ID provided to summary component');
        this.handleError(new Error('No session ID provided'));
        return;
      }

      this.setLoading(true);
      this.clearError();

      try {
        const data = await window.ApiService.table.getSummary(this.sessionId);

        if (!data.error) {
          // API returns complete data structure including tables_breakdown and enhanced_stats
          this.summaryData = data;
        } else {
          throw new Error(data.error || 'No summary data received');
        }
      } catch (error) {
        this.handleError(error);
      } finally {
        this.setLoading(false);
      }
    },

    // Start auto-refresh if enabled
    startAutoRefresh() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval);
      }

      this.refreshInterval = setInterval(() => {
        this.loadSummaryData();
      }, 30000); // Refresh every 30 seconds
    },

    // Stop auto-refresh
    stopAutoRefresh() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval);
        this.refreshInterval = null;
      }
    },

    // Get table activity data for visualization
    getTableActivity() {
      if (!this.summaryData.tables_breakdown) return [];

      return this.summaryData.tables_breakdown.map(table => ({
        name: table.table_name,
        total: table.change_count,
        ...table.operations
      }));
    }
  });
});
