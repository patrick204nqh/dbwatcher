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

  // Core services
  ComponentRegistry: null,
  BaseComponent: null,
  ApiService: null,

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

    // Initialize API Service if available
    if (this.ApiService) {
      this.ApiService.init({
        debug: this.debug
      });
    }

    // Mark as initialized
    this.initialized = true;
    console.log(`DBWatcher ${this.version} initialized`);

    return this;
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
  }
}
