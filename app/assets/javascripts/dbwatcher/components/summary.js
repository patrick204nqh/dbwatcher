/**
 * Summary Alpine.js Component
 *
 * Handles summary statistics display, charts, and real-time updates
 * using centralized state management
 */

document.addEventListener('alpine:init', () => {
  Alpine.data('summary', (config) => ({
    // Initialize from config
    sessionId: config.session_id,
    summaryData: config.summary_data || {},

    // State
    loading: false,
    error: null,
    autoRefresh: false,
    refreshInterval: null,

    init() {
      // Load initial data if not provided
      if (!Object.keys(this.summaryData).length) {
        this.loadSummaryData();
      }

      // Setup auto-refresh if enabled
      if (this.autoRefresh) {
        this.startAutoRefresh();
      }
    },

    // Load summary data from API
    async loadSummaryData() {
      if (!this.sessionId) return;

      this.loading = true;
      this.error = null;

      try {
        const endpoint = `sessions/${this.sessionId}/summary_data`;
        const data = await Alpine.store('session').loadData(endpoint);

        if (data.summary_data) {
          this.summaryData = data.summary_data;
        } else {
          throw new Error('No summary data received');
        }
      } catch (error) {
        this.error = error.message;
        console.error('Failed to load summary data:', error);
      } finally {
        this.loading = false;
      }
    },

    // Refresh summary data
    async refreshData() {
      // Clear cache for summary data
      Alpine.store('session').clearCache('summary_data');
      await this.loadSummaryData();
    },

    // Toggle auto-refresh
    toggleAutoRefresh() {
      this.autoRefresh = !this.autoRefresh;

      if (this.autoRefresh) {
        this.startAutoRefresh();
      } else {
        this.stopAutoRefresh();
      }
    },

    // Start auto-refresh interval
    startAutoRefresh() {
      if (this.refreshInterval) return;

      this.refreshInterval = setInterval(async () => {
        try {
          await this.refreshData();
        } catch (error) {
          console.error('Auto-refresh failed:', error);
          // Don't stop auto-refresh on single failure
        }
      }, 30000); // 30 seconds
    },

    // Stop auto-refresh
    stopAutoRefresh() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval);
        this.refreshInterval = null;
      }
    },

    // Get total changes count
    get totalChanges() {
      if (!this.summaryData.table_breakdown) return 0;

      return Object.values(this.summaryData.table_breakdown)
        .reduce((total, table) => {
          const changes = table.changes || {};
          return total + Object.values(changes).reduce((sum, count) => sum + count, 0);
        }, 0);
    },

    // Get total tables count
    get totalTables() {
      return Object.keys(this.summaryData.table_breakdown || {}).length;
    },

    // Get operation breakdown for charts
    get operationBreakdown() {
      if (!this.summaryData.table_breakdown) return {};

      const breakdown = { insert: 0, update: 0, delete: 0 };

      Object.values(this.summaryData.table_breakdown).forEach(table => {
        const changes = table.changes || {};
        breakdown.insert += changes.insert || 0;
        breakdown.update += changes.update || 0;
        breakdown.delete += changes.delete || 0;
      });

      return breakdown;
    },

    // Get table activity data for visualization
    get tableActivity() {
      if (!this.summaryData.table_breakdown) return [];

      return Object.entries(this.summaryData.table_breakdown)
        .map(([tableName, data]) => {
          const changes = data.changes || {};
          const total = Object.values(changes).reduce((sum, count) => sum + count, 0);

          return {
            name: tableName,
            total,
            insert: changes.insert || 0,
            update: changes.update || 0,
            delete: changes.delete || 0
          };
        })
        .sort((a, b) => b.total - a.total);
    },

    // Format numbers with commas
    formatNumber(num) {
      if (typeof num !== 'number') return '0';
      return num.toLocaleString();
    },

    // Format percentage
    formatPercentage(value, total) {
      if (!total || total === 0) return '0%';
      const percentage = (value / total) * 100;
      return `${percentage.toFixed(1)}%`;
    },

    // Get operation color class
    getOperationColor(operation) {
      const colors = {
        insert: 'text-green-600 bg-green-100',
        update: 'text-blue-600 bg-blue-100',
        delete: 'text-red-600 bg-red-100'
      };
      return colors[operation] || 'text-gray-600 bg-gray-100';
    },

    // Get activity level class
    getActivityLevel(count) {
      if (count === 0) return 'activity-none';
      if (count < 10) return 'activity-low';
      if (count < 50) return 'activity-medium';
      if (count < 100) return 'activity-high';
      return 'activity-very-high';
    },

    // Format duration
    formatDuration(startTime, endTime) {
      if (!startTime || !endTime) return '--';

      try {
        const start = new Date(startTime);
        const end = new Date(endTime);
        const diffMs = end - start;

        if (diffMs < 1000) return `${diffMs}ms`;
        if (diffMs < 60000) return `${(diffMs / 1000).toFixed(1)}s`;
        if (diffMs < 3600000) return `${Math.floor(diffMs / 60000)}m ${Math.floor((diffMs % 60000) / 1000)}s`;

        const hours = Math.floor(diffMs / 3600000);
        const minutes = Math.floor((diffMs % 3600000) / 60000);
        return `${hours}h ${minutes}m`;
      } catch (error) {
        return '--';
      }
    },

    // Cleanup when component is destroyed
    destroy() {
      this.stopAutoRefresh();
    }
  }));
});
