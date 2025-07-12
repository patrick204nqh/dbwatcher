/**
 * DBWatcher Event Bus
 * Provides standardized event handling and component communication
 */

// Event types
const EVENT_TYPES = {
  // Lifecycle events
  INIT: 'init',
  READY: 'ready',
  DESTROY: 'destroy',
  ERROR: 'error',
  ERROR_CLEAR: 'error:clear',

  // State events
  LOADING: 'loading',
  LOADED: 'loaded',
  RESET: 'reset',
  REFRESH: 'refresh',

  // Data events
  DATA_CHANGE: 'data:change',
  DATA_UPDATE: 'data:update',
  DATA_DELETE: 'data:delete',
  DATA_ERROR: 'data:error',

  // UI events
  UI_CHANGE: 'ui:change',
  UI_UPDATE: 'ui:update',
  UI_ERROR: 'ui:error',

  // API events
  API_REQUEST: 'api:request',
  API_RESPONSE: 'api:response',
  API_ERROR: 'api:error',

  // Component events
  COMPONENT_MOUNT: 'component:mount',
  COMPONENT_UNMOUNT: 'component:unmount',
  COMPONENT_UPDATE: 'component:update',
  COMPONENT_ERROR: 'component:error'
};

// Event bus implementation
const EventBus = {
  // Event registry
  listeners: new Map(),
  componentListeners: new Map(),

  // Add event listener
  on(eventType, handler, options = {}) {
    const { component, once = false } = options;

    // Validate event type
    if (!Object.values(EVENT_TYPES).includes(eventType)) {
      console.warn(`Unknown event type: ${eventType}`);
    }

    // Create handler wrapper
    const wrappedHandler = (event) => {
      try {
        handler(event.detail);
        if (once) {
          this.off(eventType, wrappedHandler);
        }
      } catch (error) {
        console.error(`Error in event handler for ${eventType}:`, error);
      }
    };

    // Store handler reference
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, new Set());
    }
    this.listeners.get(eventType).add(wrappedHandler);

    // Track component listeners for cleanup
    if (component) {
      if (!this.componentListeners.has(component)) {
        this.componentListeners.set(component, new Map());
      }
      if (!this.componentListeners.get(component).has(eventType)) {
        this.componentListeners.get(component).set(eventType, new Set());
      }
      this.componentListeners.get(component).get(eventType).add(wrappedHandler);
    }

    // Add DOM listener
    document.addEventListener(`dbwatcher:${eventType}`, wrappedHandler);

    // Return cleanup function
    return () => this.off(eventType, wrappedHandler);
  },

  // Remove event listener
  off(eventType, handler) {
    if (this.listeners.has(eventType)) {
      this.listeners.get(eventType).delete(handler);
      document.removeEventListener(`dbwatcher:${eventType}`, handler);
    }
  },

  // Emit event
  emit(eventType, detail = {}) {
    // Add timestamp and event type to detail
    const eventDetail = {
      ...detail,
      timestamp: new Date().toISOString(),
      eventType
    };

    // Create and dispatch event
    const event = new CustomEvent(`dbwatcher:${eventType}`, {
      detail: eventDetail,
      bubbles: true
    });
    document.dispatchEvent(event);

    return eventDetail;
  },

  // Listen for event once
  once(eventType, handler, options = {}) {
    return this.on(eventType, handler, { ...options, once: true });
  },

  // Remove all listeners for a component
  removeComponentListeners(component) {
    if (this.componentListeners.has(component)) {
      const componentEvents = this.componentListeners.get(component);
      componentEvents.forEach((handlers, eventType) => {
        handlers.forEach(handler => this.off(eventType, handler));
      });
      this.componentListeners.delete(component);
    }
  },

  // Remove all listeners for an event type
  removeAllListeners(eventType) {
    if (this.listeners.has(eventType)) {
      this.listeners.get(eventType).forEach(handler => {
        document.removeEventListener(`dbwatcher:${eventType}`, handler);
      });
      this.listeners.delete(eventType);
    }
  }
};

// Event mixin - adds event capabilities to components
const EventMixin = {
  // Event handling
  on(eventType, handler) {
    return EventBus.on(eventType, handler, { component: this });
  },

  once(eventType, handler) {
    return EventBus.once(eventType, handler, { component: this });
  },

  emit(eventType, detail = {}) {
    return EventBus.emit(eventType, {
      ...detail,
      component: this.constructor.name
    });
  },

  // Cleanup
  removeEventListeners() {
    EventBus.removeComponentListeners(this);
  }
};

// Export event system
window.DBWatcher = window.DBWatcher || {};
window.DBWatcher.Events = {
  TYPES: EVENT_TYPES,
  Bus: EventBus,
  Mixin: EventMixin
};
