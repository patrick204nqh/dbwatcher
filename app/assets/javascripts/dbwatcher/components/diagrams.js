/**
 * Diagrams Component
 * API-first implementation for DBWatcher diagrams tab
 */

// Register component with DBWatcher
DBWatcher.registerComponent('diagrams', function(config) {
  // Ensure we have a sessionId from config or elsewhere
  const sessionId = config.sessionId || config.session_id || (config.session && config.session.id);

  return Object.assign(DBWatcher.BaseComponent(config), {
    // Component-specific state
    sessionId: sessionId,
    diagramTypes: {},
    selectedType: 'database_tables',
    diagramContent: null,
    panZoomInstance: null,
    generating: false,

    // Component initialization
    componentInit() {
      // Validate sessionId before proceeding
      if (!this.sessionId) {
        console.error('No session ID available in component. Config was:', config);
        this.handleError(new Error('No session ID provided'));
        return;
      }

      // First load available diagram types from API
      this.loadDiagramTypes().then(() => {
        // Then load the actual diagram
        this.loadDiagram();
      });
    },

    // Component cleanup
    componentDestroy() {
      this.safelyDestroyPanZoom();
    },

    // Load available diagram types from API
    async loadDiagramTypes() {
      this.setLoading(true);
      this.clearError();

      try {
        const url = `/dbwatcher/api/v1/sessions/diagram_types`;
        const data = await this.fetchData(url);

        if (data.types) {
          this.diagramTypes = data.types;

          // If URL has type parameter, use it, otherwise use default
          const urlParams = new URLSearchParams(window.location.search);
          const typeParam = urlParams.get('diagram_type');

          if (typeParam && this.diagramTypes[typeParam]) {
            this.selectedType = typeParam;
          } else if (data.default_type) {
            this.selectedType = data.default_type;
          }
        } else {
          throw new Error('No diagram types received');
        }
      } catch (error) {
        this.handleError(error);
      } finally {
        this.setLoading(false);
      }
    },

    // Load diagram data from API
    async loadDiagram() {
      if (!this.sessionId) {
        console.error('No session ID provided to diagrams component');
        this.handleError(new Error('No session ID provided'));
        return;
      }

      this.generating = true;
      this.clearError();

      try {
        const url = `/dbwatcher/api/v1/sessions/${this.sessionId}/diagram_data?type=${this.selectedType}`;
        const data = await this.fetchData(url);

        if (data.content) {
          this.diagramContent = data.content;
          // Update URL to reflect current diagram type
          this.updateURL();
          // Wait for DOM update
          this.$nextTick(() => this.renderDiagram());
        } else {
          throw new Error('No diagram content received');
        }
      } catch (error) {
        this.handleError(error);
      } finally {
        this.generating = false;
      }
    },

    // Update URL with current diagram type
    updateURL() {
      const url = new URL(window.location.href);
      const params = new URLSearchParams(url.search);

      params.set('diagram_type', this.selectedType);

      // Update URL without full page reload
      url.search = params.toString();
      window.history.replaceState({}, '', url.toString());
    },

    // Change diagram type
    async changeType(newType) {
      if (this.selectedType === newType) return;

      this.selectedType = newType;
      this.updateURL();
      await this.loadDiagram();
    },

    // Render diagram using MermaidService
    async renderDiagram() {
      const container = this.$refs.diagramContainer;

      if (!container || !this.diagramContent) {
        return;
      }

      try {
        // Cleanup previous pan/zoom instance safely
        this.safelyDestroyPanZoom();

        if (!window.MermaidService) {
          throw new Error('MermaidService not available');
        }

        // Set container to full height to maximize diagram display area
        container.style.height = '100%';
        container.style.minHeight = '500px';

        // Maximize diagram within its container
        this.maximizeInContainer(container);

        // Render with MermaidService
        const result = await window.MermaidService.render(
          this.diagramContent,
          container,
          {
            fit: true,
            center: true,
            zoomEnabled: true,
            panEnabled: true,
            controlIconsEnabled: true
          }
        );

        // Store pan/zoom instance if created
        if (result && result.panZoom) {
          this.panZoomInstance = result.panZoom;
          console.log('Pan/zoom instance initialized successfully');
        } else {
          console.warn('Pan/zoom instance was not created');
        }
      } catch (error) {
        this.handleError(error);
      }
    },

    // Safely destroy pan zoom instance with error handling
    safelyDestroyPanZoom() {
      if (!this.panZoomInstance) return;

      try {
        this.panZoomInstance.destroy();
      } catch (error) {
        console.warn('Error destroying pan zoom instance:', error);
      } finally {
        this.panZoomInstance = null;
      }
    },

    // Zoom controls
    zoomIn() {
      if (!this.panZoomInstance) return;

      try {
        this.panZoomInstance.zoomIn();
      } catch (error) {
        console.warn('Error zooming in:', error);
      }
    },

    zoomOut() {
      if (!this.panZoomInstance) return;

      try {
        this.panZoomInstance.zoomOut();
      } catch (error) {
        console.warn('Error zooming out:', error);
      }
    },

    resetZoom() {
      if (!this.panZoomInstance) return;

      try {
        this.panZoomInstance.resetZoom();
        this.panZoomInstance.center();
      } catch (error) {
        console.warn('Error resetting zoom:', error);
      }
    },

    // Reset view - alias for resetZoom for consistency with template
    resetView() {
      this.resetZoom();
    },

    // Download diagram as SVG
    downloadSVG() {
      const svgElement = this.$refs.diagramContainer?.querySelector('svg');
      if (!svgElement) return;

      try {
        const svgData = new XMLSerializer().serializeToString(svgElement);
        const blob = new Blob([svgData], { type: 'image/svg+xml' });
        const url = URL.createObjectURL(blob);

        const link = document.createElement('a');
        link.href = url;
        link.download = `dbwatcher-${this.selectedType}-diagram.svg`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        URL.revokeObjectURL(url);
      } catch (error) {
        this.handleError(new Error('Failed to download SVG'));
      }
    },

    // Get diagram type metadata
    getDiagramTypeInfo(type) {
      return this.availableTypes[type] || {
        display_name: type,
        description: ''
      };
    },

    // Maximize diagram within its container
    maximizeInContainer(container) {
      if (!container) return;

      // Apply styles to ensure diagram fills available container space
      const containerStyles = {
        height: '100%',
        minHeight: '500px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        position: 'relative',
        padding: '0.75rem',
        margin: '0',
        boxSizing: 'border-box',
        borderRadius: '0.375rem'
      };

      Object.assign(container.style, containerStyles);

      // Find SVG element and ensure it fills the container
      const svgElement = container.querySelector('svg');
      if (svgElement) {
        // Make SVG responsive and fit container with enhanced styling
        const svgStyles = {
          width: '100%',
          height: '100%',
          maxWidth: '100%',
          maxHeight: '100%',
          display: 'block',
          margin: 'auto',
          borderRadius: '0.25rem',
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)'
        };

        Object.assign(svgElement.style, svgStyles);

        // Update SVG attributes for proper scaling
        if (!svgElement.getAttribute('preserveAspectRatio')) {
          svgElement.setAttribute('preserveAspectRatio', 'xMidYMid meet');
        }

        // Ensure dimensions are set
        const containerWidth = container.clientWidth || 800;
        const containerHeight = container.clientHeight || 600;

        if (!svgElement.getAttribute('width') || !svgElement.getAttribute('height')) {
          svgElement.setAttribute('width', containerWidth.toString());
          svgElement.setAttribute('height', containerHeight.toString());
        }

        if (!svgElement.getAttribute('viewBox')) {
          svgElement.setAttribute('viewBox', `0 0 ${containerWidth} ${containerHeight}`);
        }
      }

      // Ensure any child div is also maximized
      const childDiv = container.querySelector('div.mermaid-diagram');
      if (childDiv) {
        const childStyles = {
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0',
          padding: '0.5rem',
          borderRadius: '0.375rem',
          backgroundColor: '#f9fafb'
        };

        Object.assign(childDiv.style, childStyles);
      }
    },



    // Error handling with user-friendly message and diagnostic logging
    handleError(error) {
      console.error('Error in diagrams component:', error);

      // If we have a diagram container, display a user-friendly error
      if (this.$refs.diagramContainer) {
        this.$refs.diagramContainer.innerHTML = `
          <div class="p-6 text-center bg-gray-50 rounded-md border border-gray-200 shadow-sm">
            <div class="text-red-600 mb-3 font-medium">Error loading diagram</div>
            <div class="text-sm text-gray-600 mb-4 p-2 bg-red-50 rounded border border-red-100">${error.message}</div>
            <div class="mt-4">
              <button class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 shadow-sm"
                      onclick="window.location.reload()">
                Refresh Page
              </button>
            </div>
          </div>
        `;
      }

      // Add additional diagnostic logging
      if (error.stack) {
        console.debug('Error stack:', error.stack);
      }

      // Cleanup any existing pan/zoom instance
      this.safelyDestroyPanZoom();
    }
  });
});

// Immediate fallback registration for Alpine.js
if (window.Alpine && window.Alpine.data) {
  window.Alpine.data('diagrams', (config = {}) => {
    console.log('Direct Alpine registration for diagrams called with config:', config);
    if (window.DBWatcher && window.DBWatcher.components && window.DBWatcher.components.diagrams) {
      return window.DBWatcher.components.diagrams(config);
    } else {
      console.error('DBWatcher diagrams component not available, providing fallback');
      return {
        error: 'Component not initialized',
        init() {
          this.error = 'DBWatcher not properly initialized';
        }
      };
    }
  });
}

// Also add a global function as a backup
window.diagrams = function(config = {}) {
  console.log('Global diagrams function called with config:', config);
  if (window.DBWatcher && window.DBWatcher.components && window.DBWatcher.components.diagrams) {
    return window.DBWatcher.components.diagrams(config);
  } else {
    console.error('DBWatcher diagrams component not available in global function');
    return {
      error: 'Component not initialized',
      init() {
        this.error = 'DBWatcher not properly initialized';
      }
    };
  }
};
