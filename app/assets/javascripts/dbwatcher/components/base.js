/**
 * DBWatcher Base Component
 * Provides standard lifecycle, utilities, and error handling for all components
 * Optimized to leverage libraries for common utilities and API services
 */
DBWatcher.BaseComponent = function(config = {}) {
  // Get utilities
  const lifecycle = window.DBWatcher?.Lifecycle;
  const events = window.DBWatcher?.Events;
  const utils = window.DBWatcher?.Utils;

  // Validate required dependencies
  if (!lifecycle || !events || !utils) {
    console.error('Required utilities not loaded for BaseComponent');
    return null;
  }

  // Create component instance
  const component = {
    // Standard lifecycle properties
    loading: false,
    error: null,
    config: config,
    dependencies: [],

    // API service access - standardized pattern
    get api() {
      return window.ApiService || null;
    },

    // Error types access
    get errors() {
      return window.DBWatcher.Errors || null;
    },

    // Lifecycle state access
    get state() {
      return lifecycle.Manager.getComponentState(this);
    },

    // Initialization - called automatically by Alpine.js
    init() {
      try {
        // Initialize lifecycle
        lifecycle.Manager.initComponent(this);
      } catch (error) {
        this.handleError(error);
      }
    },

    // Pre-initialization hook
    beforeInit() {
      // Validate API service availability
      if (!this.api) {
        throw this.createError('configuration', 'API service not initialized', {
          configKey: 'ApiService',
          recoverable: false
        });
      }

      // Validate error types availability
      if (!this.errors) {
        throw this.createError('configuration', 'Error handling system not initialized', {
          configKey: 'Errors',
          recoverable: false
        });
      }

      // Emit init event
      this.emit(events.TYPES.INIT);
    },

    // Post-initialization hook
    afterInit() {
      // Setup standard event listeners
      this.setupBaseEventListeners();

      // Call component-specific initialization if it exists
      if (this.componentInit) {
        try {
          this.componentInit();
        } catch (error) {
          throw this.createError('component', 'Component initialization failed', {
            componentName: this.constructor.name,
            action: 'init',
            originalError: error
          });
        }
      }

      // Emit ready event
      this.emit(events.TYPES.READY);
    },

    // Pre-destroy hook
    beforeDestroy() {
      // Remove standard event listeners
      this.removeBaseEventListeners();

      // Emit destroy event
      this.emit(events.TYPES.DESTROY);
    },

    // Post-destroy hook
    afterDestroy() {
      // Clear state
      this.loading = false;
      this.error = null;

      // Remove all event listeners
      this.removeEventListeners();
    },

    // Cleanup - called automatically by Alpine.js
    destroy() {
      try {
        lifecycle.Manager.destroyComponent(this);
      } catch (error) {
        console.error('Error during component cleanup:', error);
      }
    },

    // ==========================================
    // State management
    // ==========================================

    // Loading state management with optional message
    setLoading(state, message = '') {
      this.loading = state;
      this.emit(state ? events.TYPES.LOADING : events.TYPES.LOADED, { message });
    },

    // Error state management
    clearError() {
      this.error = null;
      this.emit(events.TYPES.ERROR_CLEAR);
    },

    // Enhanced error handling with standardized pattern
    handleError(error, context = '') {
      // Convert to DBWatcherError if needed
      const dbError = error instanceof this.errors.DBWatcherError
        ? error
        : this.createError('component', error.message, {
            componentName: this.constructor.name,
            context,
            originalError: error
          });

      // Set error message using user-friendly format
      this.error = this.errors.ErrorUtils.getUserMessage(dbError);

      // Log error with full context
      console.error(
        "Component error:",
        this.errors.ErrorUtils.formatError(dbError)
      );

      // Emit error event
      this.emit(events.TYPES.ERROR, {
        error: dbError.toLog(),
        recoverable: this.errors.ErrorUtils.isRecoverable(dbError)
      });

      // Return false to indicate error occurred
      return false;
    },

    // Create standardized error
    createError(type, message, options = {}) {
      return this.errors.ErrorFactory.create(type, message, {
        ...options,
        context: options.context || this.constructor.name
      });
    },

    // ==========================================
    // API helpers
    // ==========================================

    // Standard API request wrapper with error handling
    async apiRequest(serviceName, methodName, ...args) {
      if (!this.api || !this.api[serviceName] || !this.api[serviceName][methodName]) {
        return this.handleError(
          this.createError('api', `API method ${serviceName}.${methodName} not available`, {
            endpoint: `${serviceName}.${methodName}`,
            method: 'call'
          })
        );
      }

      // Emit API request event
      this.emit(events.TYPES.API_REQUEST, {
        service: serviceName,
        method: methodName,
        args
      });

      try {
        const response = await this.api[serviceName][methodName](...args);

        // Emit API response event
        this.emit(events.TYPES.API_RESPONSE, {
          service: serviceName,
          method: methodName,
          response
        });

        return response;
      } catch (error) {
        const apiError = this.createError('api', error.message, {
          endpoint: `${serviceName}.${methodName}`,
          method: 'call',
          originalError: error,
          status: error.status
        });

        // Emit API error event
        this.emit(events.TYPES.API_ERROR, {
          service: serviceName,
          method: methodName,
          error: apiError.toLog()
        });

        return this.handleError(apiError);
      }
    },

    // ==========================================
    // Event handling
    // ==========================================

    // Setup standard event listeners
    setupBaseEventListeners() {
      // Listen for global refresh events
      this.on(events.TYPES.REFRESH, () => {
        if (this.refresh) {
          this.refresh();
        }
      });

      // Listen for global reset events
      this.on(events.TYPES.RESET, () => {
        if (this.reset) {
          this.reset();
        }
      });

      // Listen for data changes
      this.on(events.TYPES.DATA_CHANGE, (detail) => {
        if (this.onDataChange) {
          this.onDataChange(detail);
        }
      });

      // Listen for UI changes
      this.on(events.TYPES.UI_CHANGE, (detail) => {
        if (this.onUIChange) {
          this.onUIChange(detail);
        }
      });
    },

    // Remove standard event listeners
    removeBaseEventListeners() {
      this.removeEventListeners();
    },

    // ==========================================
    // Utility methods
    // ==========================================

    // Date and time formatting
    formatDate(date, format) {
      return utils.Date.formatDate(date, format);
    },

    formatTime(date, format) {
      return utils.Date.formatTime(date, format);
    },

    formatDateTime(date, format) {
      return utils.Date.formatDateTime(date, format);
    },

    getRelativeTime(date) {
      return utils.Date.getRelativeTime(date);
    },

    // Collection utilities
    isEmpty(value) {
      return utils.Collection.isEmpty(value);
    },

    groupBy(array, key) {
      return utils.Collection.groupBy(array, key);
    },

    sortBy(array, key, order) {
      return utils.Collection.sortBy(array, key, order);
    },

    filter(array, predicate) {
      return utils.Collection.filter(array, predicate);
    },

    find(array, predicate) {
      return utils.Collection.find(array, predicate);
    },

    // Performance utilities
    debounce(fn, wait) {
      return utils.Performance.debounce(fn, wait);
    },

    throttle(fn, wait) {
      return utils.Performance.throttle(fn, wait);
    },

    memoize(fn) {
      return utils.Performance.memoize(fn);
    },

    // URL utilities
    updateURLParam(param, value) {
      utils.URL.updateParam(param, value);
    },

    getURLParam(param) {
      return utils.URL.getParam(param);
    },

    getAllURLParams() {
      return utils.URL.getAllParams();
    },

    buildURL(base, params) {
      return utils.URL.buildURL(base, params);
    },

    // DOM utilities
    querySelector(selector, context) {
      return utils.DOM.querySelector(selector, context);
    },

    querySelectorAll(selector, context) {
      return utils.DOM.querySelectorAll(selector, context);
    },

    addListener(element, event, handler, options) {
      return utils.DOM.addListener(element, event, handler, options);
    },

    addListeners(element, events) {
      return utils.DOM.addListeners(element, events);
    },

    removeListeners(cleanupFns) {
      utils.DOM.removeListeners(cleanupFns);
    },

    // String utilities
    capitalize(str) {
      return utils.String.capitalize(str);
    },

    camelCase(str) {
      return utils.String.camelCase(str);
    },

    snakeCase(str) {
      return utils.String.snakeCase(str);
    },

    truncate(str, length, suffix) {
      return utils.String.truncate(str, length, suffix);
    },

    // Object utilities
    clone(obj) {
      return utils.Object.clone(obj);
    },

    merge(...objects) {
      return utils.Object.merge(...objects);
    },

    pick(obj, props) {
      return utils.Object.pick(obj, props);
    },

    omit(obj, props) {
      return utils.Object.omit(obj, props);
    }
  };

  // Mix in lifecycle and event capabilities
  return Object.assign(component, lifecycle.Mixin, events.Mixin);
};
