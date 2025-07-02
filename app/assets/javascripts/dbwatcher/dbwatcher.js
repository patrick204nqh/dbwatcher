/**
 * DBWatcher - Main Entry Point
 * Single entry point for the entire library with auto-binding functionality
 * Version 2.0.0 - Optimized architecture
 */
window.DBWatcher = {
  // Basic information
  version: "2.0.0",
  initialized: false,
  debug: false,

  // Dependencies and configuration
  dependencies: {
    required: ['alpine', 'alpine-collapse'],
    optional: ['lodash', 'dateFns', 'mermaid', 'svgPanZoom']
  },

  // Component registry - will be initialized from core/component_registry.js
  ComponentRegistry: null,

  // Base Component - will be initialized from components/base.js
  BaseComponent: null,

  // Initialize the entire system
  init(config = {}) {
    if (this.initialized) {
      console.warn('DBWatcher already initialized');
      return this;
    }

    // Set debug mode
    this.debug = config.debug || false;

    // Validate dependencies
    this._validateDependencies();

    // Ensure critical parts are loaded
    if (!this.ComponentRegistry) {
      console.error('ComponentRegistry not loaded! Make sure core/component_registry.js is included before initialization.');
      return this;
    }

    // Initialize component registry with global config
    this.ComponentRegistry.initAll(config);

    // Mark as initialized
    this.initialized = true;
    console.log(`DBWatcher ${this.version} initialized`);

    // Setup auto-initialization for Alpine
    document.addEventListener('alpine:initialized', () => {
      console.log('Alpine.js initialized, binding components...');
      this.ComponentRegistry.initAll(config);
    });

    return this;
  },

  // Shorthand for component registration
  register(name, factory) {
    if (this.ComponentRegistry) {
      return this.ComponentRegistry.register(name, factory);
    } else {
      console.error('Cannot register component: ComponentRegistry not loaded');
      return false;
    }
  },

  // Validate that required dependencies are loaded
  _validateDependencies() {
    const missing = [];

    // Check for Alpine.js
    if (!window.Alpine) {
      missing.push('Alpine.js');
    } else if (!window.Alpine.directive('collapse')) {
      missing.push('Alpine.js collapse plugin');
    }

    // Log warnings for missing dependencies
    if (missing.length > 0) {
      console.warn(`DBWatcher missing dependencies: ${missing.join(', ')}`);
    }

    return missing.length === 0;
  },

  // Create a new component instance
  createComponent(name, config = {}) {
    if (!this.ComponentRegistry) {
      console.error('ComponentRegistry not loaded');
      return null;
    }

    const factory = this.ComponentRegistry.get(name);
    if (!factory) {
      console.error(`Component '${name}' not registered`);
      return null;
    }

    return factory(config);
  },

  // Legacy support for old API
  registerComponent(name, factory) {
    return this.register(name, factory);
  },

  // Maintain compatibility with existing components
  components: {}
};
