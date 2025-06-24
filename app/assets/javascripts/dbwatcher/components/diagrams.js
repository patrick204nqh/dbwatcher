/**
 * Diagrams Alpine.js Component
 *
 * Handles diagram rendering, type selection, and interactions
 * using simplified MermaidService and centralized state
 */

document.addEventListener('alpine:init', () => {
  Alpine.data('diagrams', (config) => ({
    // Initialize from config
    sessionId: config.session_id,
    availableTypes: config.available_types || ['erd', 'flowchart'],

    // State
    selectedType: config.selected_type || 'erd',
    loading: false,
    error: null,
    diagramContent: null,
    panZoomInstance: null,

    init() {
      // Load initial diagram
      this.loadDiagram();

      // Setup resize handler
      this.setupResizeHandler();
    },

    // Load diagram data from API
    async loadDiagram() {
      if (!this.sessionId) return;

      this.loading = true;
      this.error = null;

      try {
        const endpoint = `/sessions/${this.sessionId}/diagram_data`;
        const params = {
          type: this.selectedType,
          refresh: false
        };

        const data = await Alpine.store('session').loadData(endpoint, params);

        if (data.diagram_content) {
          this.diagramContent = data.diagram_content;
          await this.$nextTick();
          await this.renderDiagram();
        } else {
          throw new Error('No diagram content received');
        }
      } catch (error) {
        this.error = error.message;
        console.error('Failed to load diagram:', error);
      } finally {
        this.loading = false;
      }
    },

    // Refresh diagram with latest data
    async refreshDiagram() {
      if (!this.sessionId) return;

      // Clear cache for this session's diagrams
      Alpine.store('session').clearCache('diagram_data');

      await this.loadDiagram();
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
      if (!container || !this.diagramContent) return;

      try {
        // Cleanup previous pan/zoom instance
        if (this.panZoomInstance) {
          this.panZoomInstance.destroy();
          this.panZoomInstance = null;
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
        if (result.panZoom) {
          this.panZoomInstance = result.panZoom;
        }

        console.log('Diagram rendered successfully');
      } catch (error) {
        this.error = `Failed to render diagram: ${error.message}`;
        console.error('Diagram rendering error:', error);
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
        console.error('Failed to download SVG:', error);
      }
    },

    // Setup window resize handler
    setupResizeHandler() {
      let resizeTimeout;

      const handleResize = () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
          if (this.panZoomInstance) {
            this.panZoomInstance.resize();
            this.panZoomInstance.fit();
            this.panZoomInstance.center();
          }
        }, 250);
      };

      window.addEventListener('resize', handleResize);

      // Cleanup on destroy
      this.$cleanup = () => {
        window.removeEventListener('resize', handleResize);
        if (this.panZoomInstance) {
          this.panZoomInstance.destroy();
        }
      };
    },

    // Format diagram type for display
    formatType(type) {
      const typeMap = {
        'erd': 'Entity Relationship',
        'flowchart': 'Flowchart'
      };
      return typeMap[type] || type.toUpperCase();
    },

    // Get type description
    getTypeDescription(type) {
      const descriptions = {
        'erd': 'Shows database relationships and foreign keys',
        'flowchart': 'Shows data flow and table dependencies'
      };
      return descriptions[type] || '';
    },

    // Cleanup when component is destroyed
    destroy() {
      if (this.$cleanup) {
        this.$cleanup();
      }
    }
  }));
});
