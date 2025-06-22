/**
 * Mermaid.js Helper
 *
 * This module provides utilities for working with Mermaid.js diagrams
 * in the DBWatcher application with native SVG interactions.
 */

const MermaidHelper = {
  initialized: false,

  /**
   * Initialize Mermaid with default configuration
   *
   * @returns {Promise} Promise that resolves when Mermaid is ready
   */
  initialize: function() {
    return new Promise((resolve, reject) => {
      // If already initialized, resolve immediately
      if (this.initialized) {
        resolve();
        return;
      }

      if (window.mermaid) {
        try {
          // Configure mermaid globally with responsive settings
          window.mermaid.initialize({
            startOnLoad: false, // We'll manually trigger rendering
            theme: 'neutral',
            securityLevel: 'loose',
            logLevel: 'warn',

            // Global responsive settings
            useMaxWidth: true,
            htmlLabels: true,

            // Configure flowchart for model associations
            flowchart: {
              useMaxWidth: true,
              htmlLabels: true,
              curve: 'linear',
              diagramPadding: 8,
              nodeSpacing: 50,
              rankSpacing: 80
            },

            // Configure ER diagrams for database tables with responsive sizing
            er: {
              useMaxWidth: true,
              layoutDirection: 'LR',
              entityPadding: 15,
              minEntityWidth: 100,
              fontSize: 14,
              diagramPadding: 20
            }
          });

          this.initialized = true;
          console.log('Mermaid initialized successfully with responsive settings');
          resolve();
        } catch (e) {
          console.error('Failed to initialize Mermaid:', e);
          reject(e);
        }
      } else {
        console.warn('Mermaid library not loaded, attempting to load it');
        this.loadLibrary()
          .then(() => {
            this.initialize().then(resolve).catch(reject);
          })
          .catch(reject);
      }
    });
  },

  /**
   * Load Mermaid library if not already loaded
   *
   * @returns {Promise} Promise that resolves when library is loaded
   */
  loadLibrary: function() {
    return new Promise((resolve, reject) => {
      if (window.mermaid) {
        resolve();
        return;
      }

      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js';
      script.onload = () => {
        console.log('Mermaid library loaded successfully');
        resolve();
      };
      script.onerror = (e) => {
        console.error('Failed to load Mermaid library:', e);
        reject(new Error('Failed to load Mermaid library'));
      };
      document.head.appendChild(script);
    });
  },

  /**
   * Render a Mermaid diagram with native interactions
   *
   * @param {string} content - Mermaid diagram content
   * @param {HTMLElement} container - Container element
   * @param {string} diagramType - Type of diagram (e.g., 'database_tables', 'model_associations')
   * @returns {Promise} Promise that resolves when diagram is rendered
   */
  renderDiagram: function(content, container, diagramType) {
    return new Promise(async (resolve, reject) => {
      if (!content || !container) {
        reject(new Error('Missing content or container'));
        return;
      }

      try {
        // Ensure mermaid is initialized with timeout
        const initPromise = this.initialize();
        const timeoutPromise = new Promise((_, timeoutReject) => {
          setTimeout(() => timeoutReject(new Error('Mermaid initialization timeout')), 10000);
        });

        await Promise.race([initPromise, timeoutPromise]);

        // Clear the container
        container.innerHTML = '';

        // Create a responsive wrapper
        const wrapper = document.createElement('div');
        wrapper.className = 'mermaid-responsive-wrapper';
        wrapper.style.cssText = 'width: 100%; height: 100%; display: flex; justify-content: center; align-items: center;';
        container.appendChild(wrapper);

        // Create mermaid element with responsive configuration
        const diagramDiv = document.createElement('div');
        diagramDiv.className = 'mermaid';
        diagramDiv.style.cssText = 'width: 100%; height: 100%; max-width: none;';

        // Clean content for better rendering
        const cleanContent = this.prepareContent(content, diagramType);
        diagramDiv.textContent = cleanContent;
        wrapper.appendChild(diagramDiv);

        // Configure responsive settings for this specific diagram
        const responsiveSettings = this.getResponsiveSettings(diagramType);
        window.mermaid.initialize(responsiveSettings);

        try {
          // Use modern API with responsive configuration
          await window.mermaid.run({
            querySelector: '.mermaid',
            nodes: [diagramDiv]
          });

          // Apply responsive styling after rendering
          this.applyResponsiveStyling(container);

          console.log('Diagram rendered successfully with responsive sizing');
          resolve({ success: true, method: 'responsive-modern-api' });
        } catch (modernError) {
          console.warn('Modern API rendering failed, trying fallback:', modernError);

          try {
            // Fallback to render method
            const id = `mermaid-${Date.now()}`;
            diagramDiv.id = id;

            const { svg } = await window.mermaid.render(id, diagramDiv.textContent);
            wrapper.innerHTML = svg;

            // Apply responsive styling after rendering
            this.applyResponsiveStyling(container);

            console.log('Diagram rendered successfully using fallback method');
            resolve({ success: true, method: 'responsive-fallback' });
          } catch (fallbackError) {
            console.error('All rendering methods failed:', fallbackError);
            reject(new Error(`Diagram rendering failed: ${fallbackError.message}`));
          }
        }
      } catch (error) {
        console.error('Mermaid rendering error:', error);
        reject(error);
      }
    });
  },

  /**
   * Prepare content for optimal rendering
   *
   * @param {string} content - Raw diagram content
   * @param {string} diagramType - Type of diagram
   * @returns {string} Cleaned content
   */
  prepareContent: function(content, diagramType) {
    // Remove any existing init configurations that might conflict
    let cleanContent = content.replace(/%%\{init:.*?\}%%\n?/g, '');

    // Special handling for model association diagrams
    if (diagramType === 'model_associations') {
      if (!cleanContent.includes('flowchart') && !cleanContent.includes('graph')) {
        cleanContent = 'flowchart LR\n' + cleanContent;
      }
      // Replace graph with flowchart for better responsive behavior
      cleanContent = cleanContent.replace(/^graph\s+/, 'flowchart ');
    }

    return cleanContent.trim();
  },

  /**
   * Get responsive settings for specific diagram type
   *
   * @param {string} diagramType - Type of diagram
   * @returns {Object} Mermaid configuration
   */
  getResponsiveSettings: function(diagramType) {
    const baseSettings = {
      startOnLoad: false,
      theme: 'neutral',
      securityLevel: 'loose',
      logLevel: 'warn',
      useMaxWidth: true,
      htmlLabels: true,
      maxTextSize: 90000,
      maxEdges: 1000
    };

    if (diagramType === 'model_associations') {
      return {
        ...baseSettings,
        flowchart: {
          useMaxWidth: true,
          htmlLabels: true,
          curve: 'linear',
          diagramPadding: 20,
          nodeSpacing: 60,
          rankSpacing: 100,
          padding: 20
        }
      };
    } else {
      // Database tables (ER diagram)
      return {
        ...baseSettings,
        er: {
          useMaxWidth: true,
          layoutDirection: 'LR',
          entityPadding: 20,
          minEntityWidth: 120,
          fontSize: 14,
          diagramPadding: 30
        }
      };
    }
  },

  /**
   * Apply responsive styling to rendered SVG
   *
   * @param {HTMLElement} container - Container element
   */
  applyResponsiveStyling: function(container) {
    const svg = container.querySelector('svg');
    if (!svg) return;

    // Remove fixed dimensions and apply responsive styling
    svg.removeAttribute('width');
    svg.removeAttribute('height');
    svg.style.cssText = `
      width: 100% !important;
      height: 100% !important;
      max-width: none !important;
      max-height: none !important;
      display: block;
    `;

    // Ensure proper viewBox for scaling
    if (!svg.getAttribute('viewBox')) {
      const bbox = svg.getBBox();
      svg.setAttribute('viewBox', `${bbox.x - 20} ${bbox.y - 20} ${bbox.width + 40} ${bbox.height + 40}`);
    }

    // Add responsive container class
    container.classList.add('mermaid-responsive-container');
  },





  /**
   * Get current zoom level from native interactions
   *
   * @param {HTMLElement} container - Container element with the diagram
   * @returns {number} Current zoom level (1.0 = 100%)
   */
  getCurrentZoom: function(container) {
    // With native Mermaid responsive, zoom is handled by browser
    return 1.0;
  },

  /**
   * Set zoom level using native interactions
   *
   * @param {HTMLElement} container - Container element with the diagram
   * @param {number} zoomLevel - Zoom level (1.0 = 100%)
   */
  setZoom: function(container, zoomLevel) {
    // With native Mermaid responsive, zoom is handled by browser
    console.log('Zoom is handled natively by Mermaid responsive settings');
  },

  /**
   * Reset diagram view to original state
   *
   * @param {HTMLElement} container - Container element with the diagram
   */
  resetView: function(container) {
    // With native Mermaid responsive, reset means reloading
    console.log('View reset is handled by diagram reload');
  },

  /**
   * Add accessibility features to diagram
   *
   * @param {HTMLElement} container - Container element with the diagram
   */
  enhanceAccessibility: function(container) {
    const svg = container.querySelector('svg');
    if (!svg) return;

    // Add ARIA attributes
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-roledescription', 'diagram');

    // Try to find a title or create one
    let titleElement = svg.querySelector('title');
    if (!titleElement) {
      titleElement = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      svg.insertBefore(titleElement, svg.firstChild);
    }

    // Set title based on diagram type
    if (svg.innerHTML.includes('erDiagram')) {
      titleElement.textContent = 'Entity Relationship Diagram of Database Tables';
      svg.setAttribute('aria-label', 'Entity Relationship Diagram of Database Tables');
    } else if (svg.innerHTML.includes('flowchart')) {
      titleElement.textContent = 'Flowchart of Model Associations';
      svg.setAttribute('aria-label', 'Flowchart of Model Associations');
    } else {
      titleElement.textContent = 'Database Structure Diagram';
      svg.setAttribute('aria-label', 'Database Structure Diagram');
    }

    // Make nodes and edges more accessible
    const nodes = svg.querySelectorAll('.node, .entityBox');
    nodes.forEach((node, index) => {
      node.setAttribute('tabindex', '0');
      node.setAttribute('role', 'graphics-symbol');

      // Try to extract node label
      const label = node.querySelector('.label, text')?.textContent;
      if (label) {
        node.setAttribute('aria-label', `Node: ${label}`);
      }
    });
  }
};

// Export the helper for use in other files
window.MermaidHelper = MermaidHelper;
