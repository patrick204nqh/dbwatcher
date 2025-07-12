/**
 * DBWatcher API Service
 * Central entry point for all API services
 * Version: 1.0.0
 */

const ApiService = {
  // API modules (to be populated by other stories)
  session: null,
  system: null,
  diagram: null,
  query: null,
  table: null,

  // Configuration state
  config: {
    baseUrl: '/dbwatcher/api/v1',
    timeout: 30000,
    debug: false
  },

  /**
   * Initialize all API services
   * @param {Object} config - Configuration options
   * @param {string} [config.baseUrl] - Base URL for API endpoints
   * @param {number} [config.timeout] - Request timeout in milliseconds
   * @param {boolean} [config.debug] - Enable debug logging
   * @returns {Object} - The ApiService instance
   */
  init(config = {}) {
    // Merge configuration
    this.config = {
      ...this.config,
      ...config
    };

    // Configure ApiClient if available
    if (window.ApiClient) {
      window.ApiClient.baseURL = this.config.baseUrl;
      window.ApiClient.timeout = this.config.timeout;
    } else {
      console.warn('ApiClient not found - API services may not function correctly');
    }

    // Initialize debug mode
    if (this.config.debug) {
      this._enableDebugMode();
    }

    return this;
  },

  /**
   * Enable debug mode for API services
   * @private
   */
  _enableDebugMode() {
    // Wrap all public methods with debug logging
    Object.keys(this).forEach(key => {
      const prop = this[key];
      if (typeof prop === 'function' && !key.startsWith('_')) {
        const originalMethod = prop;
        this[key] = async (...args) => {
          console.group(`ApiService.${key}`);
          console.log('Arguments:', args);
          try {
            const result = await originalMethod.apply(this, args);
            console.log('Result:', result);
            return result;
          } catch (error) {
            console.error('Error:', error);
            throw error;
          } finally {
            console.groupEnd();
          }
        };
      }
    });

    console.log('API Service debug mode enabled');
  },

  /**
   * Register an API module
   * @param {string} name - The module name (e.g., 'session', 'system')
   * @param {Object} module - The API module implementation
   */
  registerModule(name, module) {
    if (!name || typeof name !== 'string') {
      throw new Error('Module name must be a non-empty string');
    }

    if (!module || typeof module !== 'object') {
      throw new Error('Module must be a valid object');
    }

    // Store the module
    this[name] = module;

    // Apply debug wrapping if enabled
    if (this.config.debug) {
      Object.keys(module).forEach(key => {
        const prop = module[key];
        if (typeof prop === 'function' && !key.startsWith('_')) {
          const originalMethod = prop;
          module[key] = async (...args) => {
            console.group(`ApiService.${name}.${key}`);
            console.log('Arguments:', args);
            try {
              const result = await originalMethod.apply(module, args);
              console.log('Result:', result);
              return result;
            } catch (error) {
              console.error('Error:', error);
              throw error;
            } finally {
              console.groupEnd();
            }
          };
        }
      });
    }

    if (this.config.debug) {
      console.log(`Registered API module: ${name}`);
    }
  },

  /**
   * Get configuration value
   * @param {string} key - Configuration key
   * @returns {*} - Configuration value
   */
  getConfig(key) {
    return this.config[key];
  },

  /**
   * Set configuration value
   * @param {string} key - Configuration key
   * @param {*} value - Configuration value
   */
  setConfig(key, value) {
    this.config[key] = value;

    // Update ApiClient if relevant
    if (key === 'baseUrl' && window.ApiClient) {
      window.ApiClient.baseURL = value;
    } else if (key === 'timeout' && window.ApiClient) {
      window.ApiClient.timeout = value;
    }
  }
};

// Register with DBWatcher if available
if (window.DBWatcher) {
  window.DBWatcher.ApiService = ApiService;
}

// Export globally for easy access
window.ApiService = ApiService;

export default ApiService;
