/**
 * Alpine Component Registrations
 * Provides direct Alpine.js component registrations
 */

document.addEventListener('alpine:init', function() {
  if (!window.Alpine) {
    console.error('Alpine.js not found');
    return;
  }

  // Register components through ComponentRegistry
  if (window.DBWatcher && window.DBWatcher.ComponentRegistry) {
    const registry = window.DBWatcher.ComponentRegistry;

    // Register all components with Alpine
    Object.entries(registry._components).forEach(([name, factory]) => {
      window.Alpine.data(name, (config = {}) => {
        return factory(config);
      });
      console.log(`✅ Registered ${name} component with Alpine`);
    });
  } else {
    console.error('DBWatcher ComponentRegistry not available');
  }
});
