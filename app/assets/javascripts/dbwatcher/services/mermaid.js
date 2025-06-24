/**
 * Simplified Mermaid Service
 *
 * Modern implementation using Mermaid v10+ API and svg-pan-zoom library
 * Replaces 374 lines of complex custom implementation with ~50 lines
 */

const MermaidService = {
  initialized: false,

  // Initialize Mermaid with optimal settings
  async initialize() {
    if (this.initialized) return;

    // Ensure Mermaid is loaded
    if (!window.mermaid) {
      await this.loadMermaid();
    }

    // Configure with modern settings
    window.mermaid.initialize({
      startOnLoad: false,
      theme: 'neutral',
      useMaxWidth: true,
      responsive: true,
      securityLevel: 'loose',

      // Optimized for performance
      logLevel: 'warn',

      // ER diagram settings
      er: {
        useMaxWidth: true,
        layoutDirection: 'LR',
        entityPadding: 15,
        fontSize: 14
      },

      // Flowchart settings
      flowchart: {
        useMaxWidth: true,
        htmlLabels: true,
        curve: 'linear'
      }
    });

    this.initialized = true;
    console.log('Mermaid service initialized');
  },

  // Load Mermaid library if not available
  async loadMermaid() {
    if (window.mermaid) return;

    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js';
      script.onload = resolve;
      script.onerror = () => reject(new Error('Failed to load Mermaid library'));
      document.head.appendChild(script);
    });
  },

  // Render diagram with svg-pan-zoom integration
  async render(content, container, options = {}) {
    if (!content || !container) {
      throw new Error('Content and container are required');
    }

    await this.initialize();

    try {
      // Clear container
      container.innerHTML = '';

      // Create diagram element
      const diagramDiv = document.createElement('div');
      diagramDiv.className = 'mermaid-diagram';
      diagramDiv.style.cssText = 'width: 100%; height: 100%;';
      container.appendChild(diagramDiv);

      // Render with modern API
      const { svg } = await window.mermaid.render('diagram-' + Date.now(), content);
      diagramDiv.innerHTML = svg;

      // Enable pan/zoom if svg-pan-zoom is available
      const svgElement = diagramDiv.querySelector('svg');
      if (svgElement && window.svgPanZoom) {
        this.enableInteractions(svgElement, options);
      }

      return { success: true, element: svgElement };
    } catch (error) {
      console.error('Mermaid rendering failed:', error);
      this.showError(container, error.message);
      throw error;
    }
  },

  // Enable SVG interactions using svg-pan-zoom library
  enableInteractions(svgElement, options = {}) {
    const config = {
      zoomEnabled: true,
      panEnabled: true,
      controlIconsEnabled: false,
      fit: true,
      center: true,
      minZoom: 0.1,
      maxZoom: 5,
      zoomScaleSensitivity: 0.1,
      ...options
    };

    try {
      const panZoom = window.svgPanZoom(svgElement, config);

      // Add keyboard shortcuts
      this.addKeyboardShortcuts(panZoom);

      return panZoom;
    } catch (error) {
      console.warn('Failed to enable SVG interactions:', error);
      return null;
    }
  },

  // Add keyboard shortcuts for pan/zoom
  addKeyboardShortcuts(panZoom) {
    const handleKeydown = (e) => {
      if (!e.target.closest('.mermaid-diagram')) return;

      switch (e.key) {
        case '+':
        case '=':
          e.preventDefault();
          panZoom.zoomIn();
          break;
        case '-':
          e.preventDefault();
          panZoom.zoomOut();
          break;
        case '0':
          e.preventDefault();
          panZoom.resetZoom();
          panZoom.center();
          break;
      }
    };

    document.addEventListener('keydown', handleKeydown);

    // Return cleanup function
    return () => document.removeEventListener('keydown', handleKeydown);
  },

  // Show error in container
  showError(container, message) {
    container.innerHTML = `
      <div class="flex items-center justify-center h-full">
        <div class="text-center p-4">
          <div class="text-red-600 mb-2">
            <svg class="w-8 h-8 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
          </div>
          <div class="text-sm text-gray-600">
            Failed to render diagram<br>
            <span class="text-xs text-gray-500">${message}</span>
          </div>
        </div>
      </div>
    `;
  }
};

// Make available globally
window.MermaidService = MermaidService;
