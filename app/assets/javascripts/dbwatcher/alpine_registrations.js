/**
 * Alpine Component Registrations
 * Provides direct Alpine.js component registrations as a fallback
 */

document.addEventListener('alpine:init', function() {
  if (!window.Alpine) {
    console.error('Alpine.js not found');
    return;
  }

  // Register changesTableHybrid component
  if (window.DBWatcher && window.DBWatcher.components && window.DBWatcher.components.changesTableHybrid) {
    window.Alpine.data('changesTableHybrid', function(config = {}) {
      return window.DBWatcher.components.changesTableHybrid(config);
    });
    console.log('✅ Registered changesTableHybrid component with Alpine');
  } else {
    // Minimal fallback
    console.warn('⚠️ changesTableHybrid component not found, using minimal fallback');
    window.Alpine.data('changesTableHybrid', function(config = {}) {
      return {
        sessionId: config.sessionId || null,
        tableData: {},
        filters: { search: '', operation: '', table: '' },
        showColumnSelector: false,
        loading: false,
        error: 'Component not loaded',
        
        init() {
          console.error('changesTableHybrid: Component failed to load');
        }
      };
    });
  }

  // Register other components as needed
  // diagrams, summary, etc.
});
