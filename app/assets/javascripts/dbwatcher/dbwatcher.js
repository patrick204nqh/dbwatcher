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
      return this.formatDate(date, "yyyy-MM-dd HH:mm:ss");
    },

    formatNumber: function(num) {
      return new Intl.NumberFormat().format(num);
    },

    // Error handling utility
    handleError: function(context, error, fallbackValue = null) {
      console.error(`[DBWatcher] Error in ${context}:`, error);
      return fallbackValue;
    },
    
    // Safe function execution with error boundary
    safeExecute: function(fn, args, context, fallbackValue = null) {
      try {
        return fn.apply(context, args);
      } catch (error) {
        return this.handleError(`${context || 'unknown'} execution`, error, fallbackValue);
      }
    }
  },

  // Component registry
  components: {},

  // Plugin management
  plugins: {
    required: ['collapse'],
    
    // Check if all required Alpine plugins are loaded
    validateAlpine: function() {
      if (!window.Alpine) {
        console.error('Alpine.js is not loaded!');
        return false;
      }
      
      // Verify required plugins
      let allPluginsLoaded = true;
      
      // Check for collapse plugin
      if (!window.Alpine.directive('collapse')) {
        console.error('Alpine.js Collapse plugin is not loaded!');
        allPluginsLoaded = false;
      }
      
      return allPluginsLoaded;
    }
  },
  
  // Enhanced initialization API
  init: function() {
    if (this.initialized) {
      console.log('DBWatcher already initialized');
      return;
    }
    
    // Validate Alpine plugins
    if (!this.plugins.validateAlpine()) {
      console.error('DBWatcher initialization failed: Required Alpine plugins missing');
      
      // Set a retry mechanism
      if (!this._retryCount) {
        this._retryCount = 0;
      }
      
      if (this._retryCount < 3) {
        console.log(`Retrying initialization in 100ms (attempt ${this._retryCount + 1}/3)`);
        this._retryCount++;
        setTimeout(() => this.init(), 100);
        return;
      } else {
        console.error('Maximum retry attempts reached. Please check if Alpine.js and its plugins are properly loaded.');
        return;
      }
    }
    
    this.bindComponents();
    this.initialized = true;
    console.log(`DBWatcher ${this.version} initialized with all required plugins`);
  },

  // Enhanced auto-binding system with better error handling and validation
  bindComponents: function() {
    if (!window.Alpine || !window.Alpine.data) {
      console.error('Alpine.js is not loaded or missing data API. Components cannot be bound.');
      return;
    }
    
    // Register all components with Alpine.data globally
    const componentNames = Object.keys(this.components);
    console.log(`Binding ${componentNames.length} components to Alpine.js...`);
    
    let successCount = 0;
    let errorCount = 0;
    
    componentNames.forEach(componentName => {
      try {
        // Validate component factory
        const componentFactory = this.components[componentName];
        if (typeof componentFactory !== 'function') {
          throw new Error(`Component factory for ${componentName} is not a function`);
        }
        
        // Register with Alpine
        Alpine.data(componentName, (config = {}) => {
          try {
            const componentInstance = componentFactory(config);
            return componentInstance;
          } catch (instanceError) {
            console.error(`Error instantiating component ${componentName}:`, instanceError);
            // Return a minimal working component to prevent UI crashes
            return { error: instanceError.message };
          }
        });
        
        console.log(`✅ Successfully bound component: ${componentName}`);
        successCount++;
      } catch (error) {
        console.error(`❌ Failed to bind component ${componentName}:`, error);
        errorCount++;
      }
    });
    
    console.log(`Component binding complete: ${successCount} succeeded, ${errorCount} failed`);
  },

  // Enhanced component registration with validation
  registerComponent: function(name, componentFactory) {
    // Validate inputs
    if (!name || typeof name !== 'string') {
      console.error('Invalid component name:', name);
      return false;
    }
    
    if (typeof componentFactory !== 'function') {
      console.error(`Invalid component factory for ${name}. Must be a function.`);
      return false;
    }
    
    // Register the component
    this.components[name] = componentFactory;
    console.log(`✅ Registered component: ${name}`);
    
    // If already initialized, bind this component immediately
    if (this.initialized && window.Alpine && window.Alpine.data) {
      try {
        Alpine.data(name, (config = {}) => componentFactory(config));
        console.log(`✅ Immediately bound new component: ${name}`);
      } catch (error) {
        console.error(`❌ Failed to immediately bind component ${name}:`, error);
      }
    }
    
    return true;
  }
};
