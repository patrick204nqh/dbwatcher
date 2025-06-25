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

      // Suppress warnings for better UX
      logLevel: 'error',

      // ER diagram settings
      er: {
        useMaxWidth: true,
        layoutDirection: 'LR',
        entityPadding: 15,
        fontSize: 14
      },

      // Flowchart settings with better compatibility
      flowchart: {
        useMaxWidth: true,
        htmlLabels: true,
        curve: 'basis',
        padding: 20,
        nodeSpacing: 50,
        rankSpacing: 50
      },

      // Suppress internal warnings
      suppressErrorRendering: false,
      suppressWarnings: true
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

      // Render with modern API and error handling
      let renderResult;
      try {
        renderResult = await window.mermaid.render('diagram-' + Date.now(), content);
      } catch (renderError) {
        // Try to clean up content and retry once
        const cleanContent = this.cleanDiagramContent(content);
        renderResult = await window.mermaid.render('diagram-' + Date.now() + '-retry', cleanContent);
      }

      const { svg } = renderResult;
      diagramDiv.innerHTML = svg;

      // Enable pan/zoom if svg-pan-zoom is available
      const svgElement = diagramDiv.querySelector('svg');
      let panZoom = null;
      if (svgElement && window.svgPanZoom) {
        panZoom = this.enableInteractions(svgElement, options);
      }

      return { success: true, element: svgElement, panZoom };
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

  // Clean diagram content to fix common issues
  cleanDiagramContent(content) {
    return content
      // Remove any problematic characters
      .replace(/[^\x00-\x7F]/g, '')
      // Normalize whitespace
      .replace(/\s+/g, ' ')
      // Remove empty lines
      .split('\n')
      .filter(line => line.trim())
      .join('\n');
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
