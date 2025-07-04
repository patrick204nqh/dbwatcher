/**
 * Optimized Mermaid Service
 *
 * Modern implementation using Mermaid v10+ API and svg-pan-zoom library
 * Uses tree-shakable design pattern for minimal code footprint
 */

const MermaidService = {
  initialized: false,

  // Initialize Mermaid with optimal settings
  async initialize() {
    if (this.initialized) return;

    // Ensure Mermaid is loaded
    if (!window.mermaid) {
      console.error('Mermaid library not loaded');
      throw new Error('Mermaid library not loaded');
    }

    // Configure with modern settings
    window.mermaid.initialize({
      startOnLoad: false,
      theme: 'neutral',
      useMaxWidth: true,
      responsive: true,
      securityLevel: 'loose',
      logLevel: 'error',
      er: {
        useMaxWidth: true,
        layoutDirection: 'LR',
        entityPadding: 15,
        fontSize: 14
      },
      flowchart: {
        useMaxWidth: true,
        htmlLabels: true,
        curve: 'basis',
        padding: 20,
        nodeSpacing: 50,
        rankSpacing: 50
      },
      suppressErrorRendering: false,
      suppressWarnings: true
    });

    this.initialized = true;
    console.log('Mermaid service initialized');
  },

  // Render diagram with svg-pan-zoom integration
  async render(content, container, options = {}) {
    if (!content || !container) {
      console.error('Missing required parameters for rendering diagram');
      return null;
    }

    await this.initialize();

    try {
      // Clean content before rendering
      const cleanedContent = this.cleanDiagramContent(content);

      // Use Mermaid's modern promise-based API
      const { svg } = await window.mermaid.render('diagram-' + Date.now(), cleanedContent);

      // Insert SVG into container
      container.innerHTML = svg;

      // Get the SVG element for pan-zoom initialization
      const svgElement = container.querySelector('svg');
      if (!svgElement) {
        throw new Error('Failed to render SVG');
      }

      // Initialize pan-zoom
      const panZoomInstance = this.enableInteractions(svgElement, options);

      return {
        svg: svgElement,
        panZoom: panZoomInstance
      };
    } catch (error) {
      console.error('Error rendering diagram:', error);
      this.showError(container, error.message || 'Failed to render diagram');
      return null;
    }
  },

  // Enable SVG interactions using svg-pan-zoom library
  enableInteractions(svgElement, options = {}) {
    // Safety checks
    if (!svgElement || !window.svgPanZoom) {
      console.error('SVG element or svg-pan-zoom library not available');
      return null;
    }

    // Get container dimensions for reference
    const containerWidth = svgElement.parentElement?.clientWidth || 800;
    const containerHeight = svgElement.parentElement?.clientHeight || 600;

    // Force set dimensions for better rendering
    svgElement.setAttribute('width', containerWidth.toString());
    svgElement.setAttribute('height', containerHeight.toString());
    svgElement.style.width = '100%';
    svgElement.style.height = '100%';
    svgElement.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    // Initialize pan-zoom
    try {
      const panZoomInstance = window.svgPanZoom(svgElement, {
        zoomEnabled: true,
        controlIconsEnabled: false,
        fit: true,
        center: true,
        minZoom: 0.2,
        maxZoom: 5,
        zoomScaleSensitivity: 0.4
      });

      // Add keyboard shortcuts
      this.addKeyboardShortcuts(panZoomInstance);

      return panZoomInstance;
    } catch (error) {
      console.error('Error initializing pan-zoom:', error);
      return null;
    }
  },

  // Clean diagram content to fix common issues
  cleanDiagramContent(content) {
    if (!content) return '';

    // Replace common problematic patterns
    return content
      .replace(/&nbsp;/g, ' ')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&')
      .trim();
  },

  // Add keyboard shortcuts for pan/zoom
  addKeyboardShortcuts(panZoom) {
    if (!panZoom) return;

    // Add keyboard event listener
    document.addEventListener('keydown', (event) => {
      // Only handle events when diagram is focused
      if (!event.target.closest('.diagram-container')) return;

      switch (event.key) {
        case '+':
        case '=':
          panZoom.zoomIn();
          break;
        case '-':
          panZoom.zoomOut();
          break;
        case '0':
          panZoom.resetZoom();
          break;
        case 'ArrowUp':
          panZoom.panBy({x: 0, y: 50});
          break;
        case 'ArrowDown':
          panZoom.panBy({x: 0, y: -50});
          break;
        case 'ArrowLeft':
          panZoom.panBy({x: 50, y: 0});
          break;
        case 'ArrowRight':
          panZoom.panBy({x: -50, y: 0});
          break;
      }
    });
  },

  // Show error in container
  showError(container, message) {
    if (!container) return;

    container.innerHTML = `
      <div class="diagram-error p-4 bg-red-50 text-red-700 rounded">
        <h3 class="font-semibold mb-2">Error rendering diagram</h3>
        <p>${message || 'An unknown error occurred'}</p>
      </div>
    `;
  }
};

// Register with DBWatcher if available
if (window.DBWatcher) {
  window.DBWatcher.MermaidService = MermaidService;
}

// Make available globally
window.MermaidService = MermaidService;
