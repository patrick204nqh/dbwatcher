/**
 * Summary Component
 * API-first implementation for DBWatcher summary tab
 */

const SummaryComponent = function(config) {
  // Get base component
  const baseComponent = DBWatcher.BaseComponent ? DBWatcher.BaseComponent(config) : {};

  return {
    ...baseComponent,

    // Component state
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
      this.loading = true;
      this.error = null;

      try {
        const response = await this.api.summary.getSummaryData(this.sessionId);
        this.summaryData = response.data;
      } catch (error) {
        this.error = error.message || 'Failed to load summary data';
        console.error('Error loading summary data:', error);
      } finally {
        this.loading = false;
      }
    },

    // Start auto-refresh
    startAutoRefresh() {
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

    // Cleanup
    destroy() {
      this.stopAutoRefresh();
      if (baseComponent.destroy) {
        baseComponent.destroy();
      }
    }
  };
};

// Register with DBWatcher ComponentRegistry
if (window.DBWatcher && window.DBWatcher.ComponentRegistry) {
  window.DBWatcher.ComponentRegistry.register('summary', SummaryComponent);
} else {
  console.error('DBWatcher ComponentRegistry not available for summary component');
}
