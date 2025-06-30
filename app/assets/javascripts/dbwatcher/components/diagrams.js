/**
 * Diagrams Component
 * Simplified component using DBWatcher base architecture
 */

// Register component with DBWatcher
DBWatcher.registerComponent('diagrams', function(config) {
  return Object.assign(DBWatcher.BaseComponent(config), {
    // Component-specific state
    sessionId: config.sessionId,
    availableTypes: config.availableTypes || {},
    selectedType: config.selectedType || 'database_tables',
    diagramContent: null,
    panZoomInstance: null,

    // Component initialization
    componentInit() {
      // Load initial diagram
      this.loadDiagram();
    },

    // Component cleanup
    componentDestroy() {
      if (this.panZoomInstance) {
        this.panZoomInstance.destroy();
        this.panZoomInstance = null;
      }
    },

    // Load diagram data from API
    async loadDiagram() {
      if (!this.sessionId) {
        this.handleError(new Error('No session ID provided'));
        return;
      }

      try {
        const url = `/dbwatcher/api/v1/sessions/${this.sessionId}/diagram_data?type=${this.selectedType}`;
        const data = await this.fetchData(url);

        if (data.content) {
          this.diagramContent = data.content;
          // Wait for DOM update
          this.$nextTick(() => this.renderDiagram());
        } else {
          throw new Error('No diagram content received');
        }
      } catch (error) {
        // Error handling is done by fetchData
      }
    },

    // Change diagram type
    async changeType(newType) {
      if (this.selectedType === newType) return;

      this.selectedType = newType;
      await this.loadDiagram();
    },

    // Render diagram using MermaidService
    async renderDiagram() {
      const container = this.$refs.diagramContainer;

      if (!container || !this.diagramContent) {
        return;
      }

      try {
        // Cleanup previous pan/zoom instance
        if (this.panZoomInstance) {
          this.panZoomInstance.destroy();
          this.panZoomInstance = null;
        }

        if (!window.MermaidService) {
          throw new Error('MermaidService not available');
        }

        // Render with MermaidService
        const result = await window.MermaidService.render(
          this.diagramContent,
          container,
          {
            fit: true,
            center: true,
            zoomEnabled: true,
            panEnabled: true
          }
        );

        // Store pan/zoom instance if created
        if (result && result.panZoom) {
          this.panZoomInstance = result.panZoom;
        }
      } catch (error) {
        this.handleError(error);
      }
    },

    // Zoom controls
    zoomIn() {
      if (this.panZoomInstance) {
        this.panZoomInstance.zoomIn();
      }
    },

    zoomOut() {
      if (this.panZoomInstance) {
        this.panZoomInstance.zoomOut();
      }
    },

    resetZoom() {
      if (this.panZoomInstance) {
        this.panZoomInstance.resetZoom();
        this.panZoomInstance.center();
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
    }
  });
});
