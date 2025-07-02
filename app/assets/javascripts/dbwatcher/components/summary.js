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

    // Component cleanup
    componentDestroy() {
      this.stopAutoRefresh();
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
        const url = `/dbwatcher/api/v1/sessions/${this.sessionId}/summary_data`;
        const data = await this.fetchData(url);

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

      this.refreshInterval = setInterval(() => {
        this.loadSummaryData();
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
    getTotalChanges() {
      return this.summaryData.enhanced_stats?.total_changes || 0;
    },

    // Get total tables count
    getTotalTables() {
      return this.summaryData.enhanced_stats?.tables_count || 0;
    },

    // Get operation breakdown for charts
    getOperationBreakdown() {
      return this.summaryData.enhanced_stats?.operations_breakdown || { "INSERT": 0, "UPDATE": 0, "DELETE": 0 };
    },

    // Get table activity data for visualization
    getTableActivity() {
      if (!this.summaryData.tables_breakdown) return [];

      return this.summaryData.tables_breakdown.map(table => ({
        name: table.table_name,
        total: table.change_count,
        ...table.operations
      }));
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

    // Format duration using timing info
    formatDuration() {
      if (!this.summaryData.timing) return '--';
      const timing = this.summaryData.timing;

      if (timing.duration === null) return '--';

      const ms = timing.duration;
      if (ms < 1000) return `${ms}ms`;
      if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
      if (ms < 3600000) return `${Math.floor(ms / 60000)}m ${Math.floor((ms % 60000) / 1000)}s`;

      const hours = Math.floor(ms / 3600000);
      const minutes = Math.floor((ms % 3600000) / 60000);
      return `${hours}h ${minutes}m`;
    },

    // Format start time
    formatStartTime() {
      if (!this.summaryData.timing?.started_at) return '--';
      return this.formatDate(this.summaryData.timing.started_at, 'MMM dd, yyyy HH:mm:ss');
    },

    // Format end time
    formatEndTime() {
      if (!this.summaryData.timing?.ended_at) return 'Active';
      return this.formatDate(this.summaryData.timing.ended_at, 'MMM dd, yyyy HH:mm:ss');
    },

    // Format operations per minute
    formatOperationsPerMinute() {
      if (!this.summaryData.enhanced_stats) return '0';

      const duration = this.calculateDurationInMinutes();
      if (duration <= 0) return '0';

      const totalOps = this.summaryData.enhanced_stats.total_changes || 0;
      const opsPerMin = totalOps / duration;
      return opsPerMin.toFixed(1);
    },

    // Format peak activity time range
    formatPeakActivity() {
      if (!this.summaryData.enhanced_stats || !this.summaryData.enhanced_stats.peak_activity) {
        return 'N/A';
      }

      const peak = this.summaryData.enhanced_stats.peak_activity;
      return `${peak.count} / ${peak.period}s`;
    },

    // Calculate duration in minutes for stats
    calculateDurationInMinutes() {
      if (!this.summaryData.timing) return 0;

      const start = new Date(this.summaryData.timing.started_at);
      const end = this.summaryData.timing.ended_at ?
        new Date(this.summaryData.timing.ended_at) :
        new Date();

      return (end - start) / (1000 * 60); // Convert ms to minutes
    },

    // Enhanced time formatting methods
    formatStartTime() {
      if (!this.summaryData.timing || !this.summaryData.timing.started_at) return 'N/A';
      return new Date(this.summaryData.timing.started_at).toLocaleString();
    },

    formatEndTime() {
      if (!this.summaryData.timing) return 'N/A';
      if (!this.summaryData.timing.ended_at) return 'Active';
      return new Date(this.summaryData.timing.ended_at).toLocaleString();
    },

    formatDuration() {
      if (!this.summaryData.timing) return 'N/A';

      const duration = this.summaryData.timing.duration;
      if (!duration) return 'N/A';

      if (duration < 60) {
        return `${duration}s`;
      } else if (duration < 3600) {
        const minutes = Math.floor(duration / 60);
        const seconds = duration % 60;
        return `${minutes}m ${seconds}s`;
      } else {
        const hours = Math.floor(duration / 3600);
        const minutes = Math.floor((duration % 3600) / 60);
        const seconds = duration % 60;
        return `${hours}h ${minutes}m ${seconds}s`;
      }
    },
  });
});
