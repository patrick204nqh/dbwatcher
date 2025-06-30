/**
 * DBWatcher Base Component
 * Provides standard lifecycle, utilities, and error handling for all components
 */
DBWatcher.BaseComponent = function(config = {}) {
  return {
    // Standard lifecycle properties
    loading: false,
    error: null,
    config: config,

    // Initialization
    init() {
      if (this.componentInit) {
        try {
          this.componentInit();
        } catch (error) {
          this.handleError(error);
        }
      }
    },

    // Cleanup
    destroy() {
      if (this.componentDestroy) {
        try {
          this.componentDestroy();
        } catch (error) {
          console.error("Error during component cleanup:", error);
        }
      }
    },

    // Utilities available to all components
    debounce(func, wait) {
      return DBWatcher.utils.debounce(func, wait);
    },

    throttle(func, wait) {
      return DBWatcher.utils.throttle(func, wait);
    },

    formatDate(date, format) {
      return DBWatcher.utils.formatDate(date, format);
    },

    formatTime(date) {
      return DBWatcher.utils.formatTime(date);
    },

    formatNumber(num) {
      return DBWatcher.utils.formatNumber(num);
    },

    groupBy(array, key) {
      return DBWatcher.utils.groupBy(array, key);
    },

    // Standard error handling
    handleError(error) {
      this.error = error.message || "An unexpected error occurred";
      console.error("Component error:", error);
    },

    // Clear error state
    clearError() {
      this.error = null;
    },

    // Standard loading state management
    setLoading(loading) {
      this.loading = loading;
    },

    // API helper methods
    async fetchData(url, options = {}) {
      this.setLoading(true);
      this.clearError();

      try {
        const response = await fetch(url, {
          headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            ...options.headers
          },
          ...options
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
      } catch (error) {
        this.handleError(error);
        throw error;
      } finally {
        this.setLoading(false);
      }
    },

    // Dispatch custom events
    dispatchEvent(eventName, detail = {}) {
      this.$dispatch(eventName, detail);
    },

    // Common UI helpers
    toggleVisibility(property) {
      this[property] = !this[property];
    },

    // Data validation helpers
    isValidData(data) {
      return data !== null && data !== undefined;
    },

    // Array/Object helpers
    isEmpty(value) {
      if (Array.isArray(value)) return value.length === 0;
      if (typeof value === 'object' && value !== null) {
        return Object.keys(value).length === 0;
      }
      return !value;
    }
  };
};
