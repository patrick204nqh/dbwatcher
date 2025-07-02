/**
 * DBWatcher Component Registry
 * Centralized system for component registration, initialization, and lifecycle management
 */

// Component Registry - Single source of truth for all components
window.DBWatcher = window.DBWatcher || {};
DBWatcher.ComponentRegistry = {
  // Component storage
  _components: {},

  // Default configuration that applies to all components
  defaultConfig: {
    debugMode: false
  },

  // Register a component
  register(name, factory) {
    if (!name || typeof name !== 'string') {
      console.error('Component name must be a non-empty string');
      return false;
    }

    if (typeof factory !== 'function') {
      console.error(`Component factory for '${name}' must be a function`);
      return false;
    }

    this._components[name] = factory;

    // Auto-register with Alpine if available
    if (window.Alpine && window.Alpine.data) {
      this._registerWithAlpine(name, factory);
    }

    return true;
  },

  // Get component factory by name
  get(name) {
    return this._components[name] || null;
  },

  // Initialize all components
  initAll(globalConfig = {}) {
    if (!window.Alpine) {
      console.warn('Alpine.js not found, components will not be initialized');
      return;
    }

    // Register all components with Alpine
    Object.keys(this._components).forEach(name => {
      this._registerWithAlpine(name, this._components[name], globalConfig);
    });

    console.log(`Initialized ${Object.keys(this._components).length} components`);
  },

  // Private: Register component with Alpine.js
  _registerWithAlpine(name, factory, globalConfig = {}) {
    // Safety check
    if (!window.Alpine || !window.Alpine.data) return;

    try {
      // Create Alpine data function that wraps our component factory
      window.Alpine.data(name, (config = {}) => {
        // Merge global config, default config, and instance config
        const mergedConfig = {
          ...this.defaultConfig,
          ...globalConfig,
          ...config
        };

        // Create component instance
        return factory(mergedConfig);
      });

      console.log(`✅ Registered ${name} with Alpine.js`);
    } catch (error) {
      console.error(`Failed to register ${name} with Alpine.js:`, error);
    }
  }
};

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = DBWatcher.ComponentRegistry;
}
