/**
 * DBWatcher Lifecycle Management
 * Provides standardized lifecycle management for components
 */

// Lifecycle states
const LIFECYCLE_STATES = {
  UNINITIALIZED: 'uninitialized',
  INITIALIZING: 'initializing',
  READY: 'ready',
  ERROR: 'error',
  DESTROYED: 'destroyed'
};

// Lifecycle manager
const LifecycleManager = {
  // Track component states
  componentStates: new Map(),

  // Initialize component
  initComponent(component) {
    if (!component || !component.constructor) {
      throw new Error('Invalid component provided to lifecycle manager');
    }

    const componentId = this.getComponentId(component);
    this.componentStates.set(componentId, LIFECYCLE_STATES.INITIALIZING);

    try {
      // Call pre-init hooks
      if (component.beforeInit) {
        component.beforeInit();
      }

      // Initialize dependencies
      this.initializeDependencies(component);

      // Call main init
      if (component.init) {
        component.init();
      }

      // Call post-init hooks
      if (component.afterInit) {
        component.afterInit();
      }

      this.componentStates.set(componentId, LIFECYCLE_STATES.READY);
      return true;
    } catch (error) {
      this.componentStates.set(componentId, LIFECYCLE_STATES.ERROR);
      throw error;
    }
  },

  // Destroy component
  destroyComponent(component) {
    if (!component || !component.constructor) {
      throw new Error('Invalid component provided to lifecycle manager');
    }

    const componentId = this.getComponentId(component);

    try {
      // Call pre-destroy hooks
      if (component.beforeDestroy) {
        component.beforeDestroy();
      }

      // Cleanup dependencies
      this.cleanupDependencies(component);

      // Call main destroy
      if (component.destroy) {
        component.destroy();
      }

      // Call post-destroy hooks
      if (component.afterDestroy) {
        component.afterDestroy();
      }

      this.componentStates.set(componentId, LIFECYCLE_STATES.DESTROYED);
      return true;
    } catch (error) {
      this.componentStates.set(componentId, LIFECYCLE_STATES.ERROR);
      throw error;
    }
  },

  // Get component state
  getComponentState(component) {
    const componentId = this.getComponentId(component);
    return this.componentStates.get(componentId) || LIFECYCLE_STATES.UNINITIALIZED;
  },

  // Check if component is in specific state
  isInState(component, state) {
    return this.getComponentState(component) === state;
  },

  // Initialize component dependencies
  initializeDependencies(component) {
    if (!component.dependencies) {
      return;
    }

    for (const dependency of component.dependencies) {
      if (dependency && !this.isInState(dependency, LIFECYCLE_STATES.READY)) {
        this.initComponent(dependency);
      }
    }
  },

  // Cleanup component dependencies
  cleanupDependencies(component) {
    if (!component.dependencies) {
      return;
    }

    for (const dependency of component.dependencies) {
      if (dependency && this.isInState(dependency, LIFECYCLE_STATES.READY)) {
        this.destroyComponent(dependency);
      }
    }
  },

  // Generate unique component ID
  getComponentId(component) {
    return component.constructor.name + '_' +
      (component.id || component.config?.id || Date.now().toString());
  }
};

// Lifecycle mixin - adds lifecycle capabilities to components
const LifecycleMixin = {
  // Lifecycle hooks
  beforeInit: null,
  afterInit: null,
  beforeDestroy: null,
  afterDestroy: null,

  // Dependency management
  dependencies: [],

  // State management
  get lifecycleState() {
    return LifecycleManager.getComponentState(this);
  },

  isReady() {
    return LifecycleManager.isInState(this, LIFECYCLE_STATES.READY);
  },

  isDestroyed() {
    return LifecycleManager.isInState(this, LIFECYCLE_STATES.DESTROYED);
  },

  // Initialization
  initialize() {
    return LifecycleManager.initComponent(this);
  },

  // Cleanup
  cleanup() {
    return LifecycleManager.destroyComponent(this);
  }
};

// Export lifecycle utilities
window.DBWatcher = window.DBWatcher || {};
window.DBWatcher.Lifecycle = {
  STATES: LIFECYCLE_STATES,
  Manager: LifecycleManager,
  Mixin: LifecycleMixin
};
