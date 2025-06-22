/**
 * Mermaid.js Helper
 *
 * This module provides utilities for working with Mermaid.js diagrams
 * in the DBWatcher application with native SVG interactions.
 */

const MermaidHelper = {
  /**
   * Initialize Mermaid with default configuration
   *
   * @returns {Promise} Promise that resolves when Mermaid is ready
   */
  initialize: function() {
    return new Promise((resolve, reject) => {
      if (window.mermaid) {
        try {
          // Configure mermaid globally with baseline settings
          window.mermaid.initialize({
            startOnLoad: false, // We'll manually trigger rendering
            theme: 'neutral',
            securityLevel: 'loose',
            logLevel: 'warn',

            // Configure flowchart for model associations
            flowchart: {
              useMaxWidth: true,
              htmlLabels: true,
              curve: 'linear',
              diagramPadding: 8,
              nodeSpacing: 50,
              rankSpacing: 80
            },

            // Configure ER diagrams for database tables
            er: {
              useMaxWidth: true,
              layoutDirection: 'LR',
              entityPadding: 15,
              minEntityWidth: 100
            }
          });

          console.log('Mermaid initialized successfully');
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
        // Ensure mermaid is initialized
        await this.initialize();

        // Clear the container
        container.innerHTML = '';

        // Create a wrapper with unique ID
        const wrapperId = `diagram-wrapper-${Date.now()}`;
        const wrapper = document.createElement('div');
        wrapper.id = wrapperId;
        wrapper.className = 'mermaid-wrapper';
        container.appendChild(wrapper);

        // Create a fresh mermaid element
        const diagramDiv = document.createElement('div');
        diagramDiv.className = 'mermaid';

        // Special handling for model association diagrams
        const isModelAssociationDiagram = diagramType === 'model_associations';

        if (isModelAssociationDiagram) {
          // For model associations, ensure we're using flowchart syntax
          if (!content.includes('flowchart')) {
            // If not already containing flowchart, modify it
            diagramDiv.textContent = content.replace(/^graph LR/, 'flowchart LR');
          } else {
            diagramDiv.textContent = content;
          }
        } else {
          diagramDiv.textContent = content;
        }

        wrapper.appendChild(diagramDiv);

        // Reset Mermaid to avoid any state issues
        if (typeof window.mermaid.reset === 'function') {
          window.mermaid.reset();
        }

        // Configure specific settings based on diagram type
        const settings = this.getSettingsForDiagramType(diagramType);

        // Initialize with our settings
        window.mermaid.initialize(settings);

        try {
          // Try modern API approach first
          const result = await window.mermaid.run({
            querySelector: '.mermaid',
            nodes: [diagramDiv]
          });

          // Enable native SVG interactions after rendering
          this.enableInteractions(container);

          console.log('Diagram rendered successfully using modern API');
          resolve({ success: true, method: 'modern-api' });
        } catch (modernError) {
          console.warn('Modern API rendering failed, trying alternative methods:', modernError);

          try {
            // Try ID-based rendering
            const id = `mermaid-${Date.now()}`;
            diagramDiv.id = id;

            const { svg } = await window.mermaid.render(id, diagramDiv.textContent);
            wrapper.innerHTML = svg;

            // Enable native SVG interactions after rendering
            this.enableInteractions(container);

            console.log('Diagram rendered successfully using ID-based rendering');
            resolve({ success: true, method: 'id-based' });
          } catch (idError) {
            console.error('ID-based rendering also failed:', idError);

            // One last attempt with direct parsing - simplest approach
            try {
              window.mermaid.parse(diagramDiv.textContent);
              console.log('Parsing successful, letting mermaid handle rendering');

              // If parsing succeeds but rendering fails, we'll try the manual approach
              wrapper.innerHTML = '<div class="mermaid">' + diagramDiv.textContent + '</div>';
              window.mermaid.init(undefined, wrapper.querySelectorAll('.mermaid'));

              // Enable native SVG interactions after rendering
              setTimeout(() => this.enableInteractions(container), 100);

              resolve({ success: true, method: 'init' });
            } catch (parseError) {
              reject(new Error(`Cannot parse diagram: ${parseError.message}`));
            }
          }
        }
      } catch (error) {
        console.error('Mermaid rendering error:', error);
        reject(error);
      }
    });
  },

  /**
   * Enable native SVG interactions on the rendered diagram
   *
   * @param {HTMLElement} container - Container element with the diagram
   * @returns {Object|null} Interaction controller or null if failed
   */
  enableInteractions: function(container) {
    if (!window.SvgInteractions) {
      console.warn('SvgInteractions not available, interactions will be limited');
      return null;
    }

    try {
      const controller = window.SvgInteractions.enable(container, {
        enableZoom: true,
        enablePan: true,
        enableKeyboard: true,
        enableTouch: true,
        minZoom: 0.1,
        maxZoom: 5,
        zoomStep: 0.1
      });

      if (controller) {
        // Store controller on container for external access
        container._svgController = controller;

        // Add visual feedback for interactions
        this.addInteractionFeedback(container);

        console.log('Native SVG interactions enabled');
      }

      return controller;
    } catch (error) {
      console.error('Failed to enable SVG interactions:', error);
      return null;
    }
  },

  /**
   * Add visual feedback for interactions
   *
   * @param {HTMLElement} container - Container element
   */
  addInteractionFeedback: function(container) {
    // Add zoom level indicator
    const indicator = document.createElement('div');
    indicator.className = 'zoom-indicator';
    indicator.style.cssText = `
      position: absolute;
      top: 10px;
      right: 10px;
      background: rgba(0, 0, 0, 0.7);
      color: white;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-family: monospace;
      pointer-events: none;
      opacity: 0;
      transition: opacity 0.3s;
      z-index: 1000;
    `;
    indicator.textContent = '100%';

    // Make container relative if not already
    if (getComputedStyle(container).position === 'static') {
      container.style.position = 'relative';
    }

    container.appendChild(indicator);

    // Listen for transform changes to update indicator
    container.addEventListener('svgTransformChanged', (e) => {
      const { zoom } = e.detail;
      indicator.textContent = `${Math.round(zoom * 100)}%`;

      // Show indicator briefly
      indicator.style.opacity = '1';
      clearTimeout(indicator._hideTimeout);
      indicator._hideTimeout = setTimeout(() => {
        indicator.style.opacity = '0';
      }, 1500);
    });

    // Add keyboard hint
    const hint = document.createElement('div');
    hint.className = 'interaction-hint';
    hint.style.cssText = `
      position: absolute;
      bottom: 10px;
      left: 10px;
      background: rgba(0, 0, 0, 0.7);
      color: white;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      font-family: sans-serif;
      pointer-events: none;
      opacity: 0;
      transition: opacity 0.3s;
      z-index: 1000;
      max-width: 200px;
      line-height: 1.3;
    `;
    hint.innerHTML = `
      <div><strong>Mouse:</strong> Wheel=zoom, Drag=pan</div>
      <div><strong>Keys:</strong> +/- zoom, 0 reset, arrows pan</div>
      <div><strong>Touch:</strong> Pinch zoom, drag pan</div>
    `;

    container.appendChild(hint);

    // Show hint on focus/hover
    const svg = container.querySelector('svg');
    if (svg) {
      const showHint = () => {
        hint.style.opacity = '1';
      };
      const hideHint = () => {
        hint.style.opacity = '0';
      };

      svg.addEventListener('focus', showHint);
      svg.addEventListener('blur', hideHint);
      container.addEventListener('mouseenter', showHint);
      container.addEventListener('mouseleave', hideHint);
    }
  },

  /**
   * Get Mermaid settings for a specific diagram type
   *
   * @param {string} diagramType - Type of diagram
   * @returns {Object} Mermaid configuration settings
   */
  getSettingsForDiagramType: function(diagramType) {
    const baseSettings = {
      startOnLoad: false,
      theme: 'neutral',
      securityLevel: 'loose',
      logLevel: 'warn',
      themeVariables: {
        fontSize: '14px',
        fontFamily: 'Consolas, Monaco, Lucida Console, monospace'
      }
    };

    // Add type-specific settings
    if (diagramType === 'model_associations') {
      return {
        ...baseSettings,
        flowchart: {
          htmlLabels: true,
          useMaxWidth: true,
          curve: 'linear',
          nodeSpacing: 50,
          rankSpacing: 100
        }
      };
    } else {
      // Default to ER diagram settings
      return {
        ...baseSettings,
        er: {
          useMaxWidth: true,
          layoutDirection: 'LR',
          minEntityWidth: 100,
          minEntityHeight: 75
        }
      };
    }
  },



  /**
   * Get current zoom level from native interactions
   *
   * @param {HTMLElement} container - Container element with the diagram
   * @returns {number} Current zoom level (1.0 = 100%)
   */
  getCurrentZoom: function(container) {
    const controller = container._svgController;
    if (controller) {
      return controller.getState().zoom;
    }
    return 1.0;
  },

  /**
   * Set zoom level using native interactions
   *
   * @param {HTMLElement} container - Container element with the diagram
   * @param {number} zoomLevel - Zoom level (1.0 = 100%)
   */
  setZoom: function(container, zoomLevel) {
    const controller = container._svgController;
    if (controller) {
      controller.zoomTo(zoomLevel);
    }
  },

  /**
   * Reset diagram view to original state
   *
   * @param {HTMLElement} container - Container element with the diagram
   */
  resetView: function(container) {
    const controller = container._svgController;
    if (controller) {
      controller.reset();
    }
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
