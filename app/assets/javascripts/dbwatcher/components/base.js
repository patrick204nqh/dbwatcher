/**
 * DBWatcher Base Component
 * Provides standard lifecycle, utilities, and error handling for all components
 * Optimized to leverage libraries for common utilities
 */
DBWatcher.BaseComponent = function(config = {}) {
  return {
    // Standard lifecycle properties
    loading: false,
    error: null,
    config: config,

    // Initialization - called automatically by Alpine.js
    init() {
      if (this.componentInit) {
        try {
          this.componentInit();
        } catch (error) {
          this.handleError(error);
        }
      }
    },

    // Cleanup - should be called when component is removed
    destroy() {
      if (this.componentDestroy) {
        try {
          this.componentDestroy();
        } catch (error) {
          console.error("Error during component cleanup:", error);
        }
      }
    },

    // ==========================================
    // Utility methods (directly use library methods)
    // ==========================================

    // Date and time formatting (using date-fns)
    formatDate: (date, format) => window.dateFns?.format(date, format) || new Date(date).toISOString().split('T')[0],
    formatTime: (date) => window.dateFns?.format(date, 'HH:mm:ss') || new Date(date).toTimeString().split(' ')[0],

    // Collection utilities (using lodash)
    isEmpty: (value) => window._ ? _.isEmpty(value) : (
      Array.isArray(value) ? value.length === 0 :
      typeof value === 'object' && value !== null ? Object.keys(value).length === 0 : !value
    ),

    // Performance utilities (using lodash)
    debounce: (fn, wait) => window._ ? _.debounce(fn, wait) : fn,
    throttle: (fn, wait) => window._ ? _.throttle(fn, wait) : fn,

    // ==========================================
    // State management
    // ==========================================

    // Error handling with standardized pattern
    handleError(error) {
      this.error = error.message || "An unexpected error occurred";
      console.error("Component error:", error);

      // Dispatch error event for global tracking
      if (this.$dispatch) {
        this.$dispatch('dbwatcher:error', {
          component: this.constructor.name,
          error: this.error
        });
      }
    },

    // Clear error state
    clearError() {
      this.error = null;
    },

    // Loading state management
    setLoading(loading) {
      this.loading = loading;

      // Dispatch loading state change event
      if (this.$dispatch) {
        this.$dispatch('dbwatcher:loading', { loading });
      }
    },

    // ==========================================
    // API integration (using ApiClient)
    // ==========================================

    // Fetch data with standardized error handling
    async fetchData(endpoint, options = {}) {
      this.setLoading(true);
      this.clearError();

      try {
        // Use centralized API client if available
        if (window.ApiClient) {
          return await window.ApiClient.get(endpoint, options.params || {}, options);
        }

        // Fallback to standard fetch
        const url = endpoint.startsWith('/') ? endpoint : `/dbwatcher/api/v1/${endpoint}`;
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

        return await response.json();
      } catch (error) {
        this.handleError(error);
        throw error;
      } finally {
        this.setLoading(false);
      }
    },

    // ==========================================
    // Event handling
    // ==========================================

    // Dispatch custom events
    dispatchEvent(eventName, detail = {}) {
      if (this.$dispatch) {
        this.$dispatch(eventName, detail);
      }
    },

    // Common UI helpers
    toggleVisibility(property) {
      this[property] = !this[property];
    }
  };
};
