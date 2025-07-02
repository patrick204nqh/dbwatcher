/**
 * DBWatcher Component Loader
 * Handles component initialization and dependencies
 */

window.DBWatcher = window.DBWatcher || {};

DBWatcher.ComponentLoader = {
  // Track loaded components to prevent duplicates
  loadedComponents: new Set(),

  // Map of component dependencies
  componentDependencies: {
    'diagrams': ['mermaid_service'],
    'changes_table': [],
    'summary': []
  },

  // Load a component and its dependencies
  async load(componentName) {
    if (this.loadedComponents.has(componentName)) {
      console.log(`Component ${componentName} already loaded`);
      return true;
    }

    // Check for dependencies
    const dependencies = this.componentDependencies[componentName] || [];

    // Load dependencies first
    for (const dependency of dependencies) {
      await this.load(dependency);
    }

    // Mark as loaded
    this.loadedComponents.add(componentName);
    console.log(`Loaded component: ${componentName}`);
    return true;
  },

  // Initialize the component system
  init(config = {}) {
    // Setup auto-loading for Alpine.js components
    document.addEventListener('alpine:init', () => {
      // Register loader directive for on-demand loading
      window.Alpine.directive('dbcomponent', (el, { value, expression }, { evaluate }) => {
        const componentName = evaluate(expression);
        this.load(componentName).then(() => {
          console.log(`Component ${componentName} loaded via directive`);
        });
      });

      // Auto-load components from data attributes
      document.querySelectorAll('[data-component]').forEach(el => {
        const componentName = el.dataset.component;
        if (componentName) {
          this.load(componentName);
        }
      });
    });

    return this;
  }
};

// Auto-init if DBWatcher is available
if (window.DBWatcher && window.DBWatcher.init) {
  document.addEventListener('DOMContentLoaded', () => {
    DBWatcher.ComponentLoader.init();
  });
}
