/**
 * DBWatcher - Main Entry Point
 * Provides component registry, utilities, and initialization
 */
window.DBWatcher = {
  version: "1.0.0",
  initialized: false,

  // Core utilities (leveraging libraries)
  utils: {
    debounce: function(func, wait) {
      return window._ ? _.debounce(func, wait) : func;
    },

    throttle: function(func, wait) {
      return window._ ? _.throttle(func, wait) : func;
    },

    groupBy: function(array, key) {
      return window._ ? _.groupBy(array, key) : array;
    },

    formatDate: function(date, format = "yyyy-MM-dd HH:mm:ss") {
      if (window.dateFns && window.dateFns.format) {
        return dateFns.format(new Date(date), format);
      }
      // Simple fallback
      const d = new Date(date);
      return d.toISOString().slice(0, 19).replace('T', ' ');
    },

    formatTime: function(date) {
      return this.formatDate(date, "HH:mm:ss");
    },

    formatNumber: function(num) {
      return new Intl.NumberFormat().format(num);
    }
  },

  // Component registry
  components: {},

  // Simple initialization API
  init: function() {
    if (this.initialized) {
      console.log('DBWatcher already initialized');
      return;
    }

    this.bindComponents();
    this.initialized = true;
    console.log(`DBWatcher ${this.version} initialized`);
  },

  // Auto-binding system
  bindComponents: function() {
    // Register all components with Alpine.data globally
    Object.keys(this.components).forEach(componentName => {
      if (window.Alpine && window.Alpine.data) {
        Alpine.data(componentName, (config = {}) => this.components[componentName](config));
      }
    });
  },

  // Register a component
  registerComponent: function(name, componentFactory) {
    this.components[name] = componentFactory;
    console.log(`Registered component: ${name}`);
  }
};
