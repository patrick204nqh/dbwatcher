/**
 * Minimal SVG Interaction Helper
 * 
 * Provides native mouse/touch interactions for SVG diagrams
 * Replaces custom zoom/pan implementation with standard web APIs
 */

const SvgInteractions = {
  /**
   * Enable native interactions on an SVG element
   * @param {HTMLElement} container - Container element with SVG
   * @param {Object} options - Configuration options
   */
  enable(container, options = {}) {
    const svg = container.querySelector('svg');
    if (!svg) {
      console.warn('No SVG found in container');
      return null;
    }

    const config = {
      enableZoom: true,
      enablePan: true,
      enableKeyboard: true,
      enableTouch: true,
      minZoom: 0.1,
      maxZoom: 5,
      zoomStep: 0.1,
      ...options
    };

    // Store original viewBox for reset functionality
    const originalViewBox = svg.getAttribute('viewBox') || '0 0 800 600';
    svg.setAttribute('data-original-viewbox', originalViewBox);

    // Set up initial state
    let currentZoom = 1;
    let currentPanX = 0;
    let currentPanY = 0;
    let isPanning = false;
    let panStartX = 0;
    let panStartY = 0;

    // Make SVG focusable for keyboard events
    svg.setAttribute('tabindex', '0');
    svg.style.outline = 'none';
    svg.style.cursor = 'grab';

    // Parse viewBox dimensions
    const [vbX, vbY, vbW, vbH] = originalViewBox.split(' ').map(Number);

    /**
     * Update SVG viewBox based on current zoom and pan
     */
    function updateViewBox() {
      const newWidth = vbW / currentZoom;
      const newHeight = vbH / currentZoom;
      const newX = vbX + currentPanX;
      const newY = vbY + currentPanY;
      
      svg.setAttribute('viewBox', `${newX} ${newY} ${newWidth} ${newHeight}`);
      
      // Dispatch custom event for external listeners
      container.dispatchEvent(new CustomEvent('svgTransformChanged', {
        detail: { zoom: currentZoom, panX: currentPanX, panY: currentPanY }
      }));
    }

    /**
     * Zoom to a specific level at a point
     */
    function zoomTo(newZoom, centerX = null, centerY = null) {
      const clampedZoom = Math.max(config.minZoom, Math.min(config.maxZoom, newZoom));
      
      if (centerX !== null && centerY !== null) {
        // Adjust pan to keep the zoom centered on the specified point
        const zoomRatio = clampedZoom / currentZoom;
        const rect = svg.getBoundingClientRect();
        const svgX = centerX - rect.left;
        const svgY = centerY - rect.top;
        
        // Convert screen coordinates to SVG coordinates
        const pt = svg.createSVGPoint();
        pt.x = svgX;
        pt.y = svgY;
        const svgPt = pt.matrixTransform(svg.getScreenCTM().inverse());
        
        currentPanX += (svgPt.x - vbX) * (1 - 1/zoomRatio);
        currentPanY += (svgPt.y - vbY) * (1 - 1/zoomRatio);
      }
      
      currentZoom = clampedZoom;
      updateViewBox();
    }

    /**
     * Pan by delta amounts
     */
    function panBy(deltaX, deltaY) {
      const panSpeed = 50 / currentZoom; // Adjust pan speed based on zoom level
      currentPanX += deltaX * panSpeed;
      currentPanY += deltaY * panSpeed;
      updateViewBox();
    }

    /**
     * Reset to original view
     */
    function reset() {
      currentZoom = 1;
      currentPanX = 0;
      currentPanY = 0;
      updateViewBox();
    }

    // Mouse wheel zoom
    if (config.enableZoom) {
      svg.addEventListener('wheel', (e) => {
        e.preventDefault();
        
        const delta = e.deltaY > 0 ? -config.zoomStep : config.zoomStep;
        const newZoom = currentZoom + delta;
        
        zoomTo(newZoom, e.clientX, e.clientY);
      }, { passive: false });
    }

    // Mouse pan
    if (config.enablePan) {
      svg.addEventListener('mousedown', (e) => {
        if (e.button !== 0) return; // Only left mouse button
        
        isPanning = true;
        panStartX = e.clientX;
        panStartY = e.clientY;
        svg.style.cursor = 'grabbing';
        
        e.preventDefault();
      });

      document.addEventListener('mousemove', (e) => {
        if (!isPanning) return;
        
        const deltaX = (panStartX - e.clientX) / currentZoom;
        const deltaY = (panStartY - e.clientY) / currentZoom;
        
        currentPanX += deltaX;
        currentPanY += deltaY;
        
        panStartX = e.clientX;
        panStartY = e.clientY;
        
        updateViewBox();
      });

      document.addEventListener('mouseup', () => {
        if (isPanning) {
          isPanning = false;
          svg.style.cursor = 'grab';
        }
      });
    }

    // Double-click reset
    svg.addEventListener('dblclick', (e) => {
      e.preventDefault();
      reset();
    });

    // Keyboard shortcuts
    if (config.enableKeyboard) {
      svg.addEventListener('keydown', (e) => {
        switch(e.key) {
          case '+':
          case '=':
            e.preventDefault();
            zoomTo(currentZoom + config.zoomStep);
            break;
          case '-':
            e.preventDefault();
            zoomTo(currentZoom - config.zoomStep);
            break;
          case '0':
            e.preventDefault();
            reset();
            break;
          case 'ArrowUp':
            e.preventDefault();
            panBy(0, -1);
            break;
          case 'ArrowDown':
            e.preventDefault();
            panBy(0, 1);
            break;
          case 'ArrowLeft':
            e.preventDefault();
            panBy(-1, 0);
            break;
          case 'ArrowRight':
            e.preventDefault();
            panBy(1, 0);
            break;
        }
      });
    }

    // Touch support
    if (config.enableTouch) {
      let initialDistance = 0;
      let initialZoom = 1;
      let touches = [];

      svg.addEventListener('touchstart', (e) => {
        touches = Array.from(e.touches);
        
        if (touches.length === 2) {
          // Pinch zoom start
          const touch1 = touches[0];
          const touch2 = touches[1];
          initialDistance = Math.hypot(
            touch2.clientX - touch1.clientX,
            touch2.clientY - touch1.clientY
          );
          initialZoom = currentZoom;
        } else if (touches.length === 1) {
          // Pan start
          isPanning = true;
          panStartX = touches[0].clientX;
          panStartY = touches[0].clientY;
        }
        
        e.preventDefault();
      }, { passive: false });

      svg.addEventListener('touchmove', (e) => {
        const currentTouches = Array.from(e.touches);
        
        if (currentTouches.length === 2 && touches.length === 2) {
          // Pinch zoom
          const touch1 = currentTouches[0];
          const touch2 = currentTouches[1];
          const currentDistance = Math.hypot(
            touch2.clientX - touch1.clientX,
            touch2.clientY - touch1.clientY
          );
          
          const scale = currentDistance / initialDistance;
          const newZoom = initialZoom * scale;
          
          // Center zoom between the two touches
          const centerX = (touch1.clientX + touch2.clientX) / 2;
          const centerY = (touch1.clientY + touch2.clientY) / 2;
          
          zoomTo(newZoom, centerX, centerY);
        } else if (currentTouches.length === 1 && isPanning) {
          // Pan
          const deltaX = (panStartX - currentTouches[0].clientX) / currentZoom;
          const deltaY = (panStartY - currentTouches[0].clientY) / currentZoom;
          
          currentPanX += deltaX;
          currentPanY += deltaY;
          
          panStartX = currentTouches[0].clientX;
          panStartY = currentTouches[0].clientY;
          
          updateViewBox();
        }
        
        e.preventDefault();
      }, { passive: false });

      svg.addEventListener('touchend', (e) => {
        if (e.touches.length === 0) {
          isPanning = false;
          touches = [];
        }
      });
    }

    // Return control object
    return {
      zoomTo,
      panBy,
      reset,
      getState: () => ({ zoom: currentZoom, panX: currentPanX, panY: currentPanY }),
      destroy: () => {
        // Clean up event listeners if needed
        svg.removeAttribute('tabindex');
        svg.style.cursor = '';
      }
    };
  }
};

// Export for use in other files
window.SvgInteractions = SvgInteractions;
