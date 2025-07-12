/**
 * Diagrams Component
 * API-first implementation for DBWatcher diagrams tab
 */

const DiagramsComponent = function(config) {
  // Get base component
  const baseComponent = DBWatcher.BaseComponent ? DBWatcher.BaseComponent(config) : {};

  return {
    ...baseComponent,

    // Component state
    sessionId: config.sessionId,
    diagramData: null,
    loading: false,
    error: null,

    // Component initialization
    componentInit() {
      if (this.sessionId) {
        this.loadDiagramData();
      }
    },

    // Load diagram data from API
    async loadDiagramData() {
      this.loading = true;
      this.error = null;

      try {
        const response = await this.api.diagram.getDiagramData(this.sessionId);
        this.diagramData = response.data;
      } catch (error) {
        this.error = error.message || 'Failed to load diagram data';
        console.error('Error loading diagram data:', error);
      } finally {
        this.loading = false;
      }
    }
  };
};

// Register with DBWatcher ComponentRegistry
if (window.DBWatcher && window.DBWatcher.ComponentRegistry) {
  window.DBWatcher.ComponentRegistry.register('diagrams', DiagramsComponent);
} else {
  console.error('DBWatcher ComponentRegistry not available for diagrams component');
}
