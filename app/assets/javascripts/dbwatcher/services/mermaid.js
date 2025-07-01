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

      // Create diagram element - ensure full container size
      const diagramDiv = document.createElement('div');
      diagramDiv.className = 'mermaid-diagram';

      // Set explicit styles for better browser rendering
      const styles = {
        width: '100%',
        height: '100%',
        minHeight: '400px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden'
      };

      Object.assign(diagramDiv.style, styles);

      // Get container dimensions before appending
      const containerWidth = container.clientWidth || 800;
      const containerHeight = container.clientHeight || 600;

      console.log('Container dimensions in render:', containerWidth, containerHeight);

      // Set container to fill its parent
      container.style.width = '100%';
      container.style.height = '100%';
      container.style.minHeight = '500px';
      container.style.position = 'relative';
      container.style.overflow = 'hidden';

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

      // Post-process the SVG to ensure it has proper dimensions
      const svgElement = diagramDiv.querySelector('svg');
      if (svgElement) {
        // Set CSS styles for SVG
        Object.assign(svgElement.style, {
          width: '100%',
          height: '100%',
          maxWidth: '100%',
          maxHeight: '100%',
          display: 'block'
        });

        // Make sure viewBox is set if not already
        if (!svgElement.getAttribute('viewBox')) {
          const width = svgElement.getAttribute('width') || diagramDiv.clientWidth;
          const height = svgElement.getAttribute('height') || diagramDiv.clientHeight;
          svgElement.setAttribute('viewBox', `0 0 ${width} ${height}`);
        }
      }

      // Enable pan/zoom if svg-pan-zoom is available
      let panZoom = null;

      if (svgElement && window.svgPanZoom) {
        // enableInteractions now returns a Promise or null
        panZoom = await Promise.resolve(this.enableInteractions(svgElement, options));
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
    // Safety checks and set default dimensions if needed
    if (!svgElement) {
      console.warn('SVG element is null, cannot initialize pan-zoom');
      return null;
    }

    // Always ensure the SVG element has dimensions before initializing pan-zoom
    // Get container dimensions for reference
    const containerWidth = svgElement.parentElement?.clientWidth || 800;
    const containerHeight = svgElement.parentElement?.clientHeight || 600;

    console.log('Container dimensions:', containerWidth, containerHeight);

    // Force set dimensions regardless of existing values to ensure they're always set correctly
    svgElement.setAttribute('width', containerWidth.toString());
    svgElement.setAttribute('height', containerHeight.toString());

    // Also set CSS dimensions for better browser rendering
    svgElement.style.width = '100%';
    svgElement.style.height = '100%';
    svgElement.style.maxWidth = '100%';
    svgElement.style.maxHeight = '100%';

    // Set viewBox attribute if it doesn't exist or is invalid
    const viewBox = svgElement.getAttribute('viewBox');
    if (!viewBox || viewBox.split(' ').length !== 4) {
      svgElement.setAttribute('viewBox', `0 0 ${containerWidth} ${containerHeight}`);
    }

    // Set preserveAspectRatio for proper scaling
    svgElement.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    // Double-check dimensions are now set and valid
    const width = parseFloat(svgElement.getAttribute('width'));
    const height = parseFloat(svgElement.getAttribute('height'));

    if (isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
      console.warn('SVG element has invalid dimensions after setting defaults:', width, height);
      // Set explicit fallback dimensions as a last resort
      svgElement.setAttribute('width', '800');
      svgElement.setAttribute('height', '600');
      svgElement.setAttribute('viewBox', '0 0 800 600');
    }

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
      // Ensure SVG is properly rendered in DOM before initializing pan-zoom
      // This forces a reflow which can help with dimension calculations
      void svgElement.getBoundingClientRect();

      // Short delay to ensure SVG is fully rendered before initializing pan-zoom
      return new Promise(resolve => {
        setTimeout(() => {
          try {
            // Initialize pan-zoom with the configured options
            const panZoom = window.svgPanZoom(svgElement, config);

            // Add keyboard shortcuts for better UX
            this.addKeyboardShortcuts(panZoom);

            resolve(panZoom);
          } catch (initError) {
            console.warn('Failed to initialize svg-pan-zoom:', initError);
            resolve(null);
          }
        }, 100); // Small delay for SVG rendering
      });
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
