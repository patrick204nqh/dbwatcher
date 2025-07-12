/**
 * Diagrams Component
 * API-first implementation for DBWatcher diagrams tab
 */

// Register with DBWatcher ComponentRegistry
if (window.DBWatcher && window.DBWatcher.ComponentRegistry) {
  window.DBWatcher.ComponentRegistry.register('diagrams', DiagramsComponent);
} else {
  console.error('DBWatcher ComponentRegistry not available for diagrams component');
}
