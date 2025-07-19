/**
 * Dashboard Component for DBWatcher
 * Handles tab switching and system info refresh functionality
 */

(function() {
  'use strict';

  // Configuration constants
  const CONFIG = {
    SELECTORS: {
      container: '.dashboard-container',
      tab: '.tab-item',
      tabContent: '.tab-content',
      refreshButton: '#refresh-system-info',
      clearCacheButton: '#clear-cache-system-info',
      systemInfoContent: '#system-info-content'
    }
  };

  // Dashboard Component Factory
  const DashboardComponent = function(config = {}) {
    // Get base component
    const baseComponent = DBWatcher.BaseComponent ? DBWatcher.BaseComponent(config) : {};

    // Merge configuration with defaults
    const settings = {
      ...CONFIG.SELECTORS,
      ...config
    };

    // Component state
    let isRefreshing = false;

    // Initialize component
    function init() {
      console.log('Dashboard component init() called');
      setupEventListeners();
      console.log('Dashboard component initialized successfully');
    }

    // Setup event listeners
    function setupEventListeners() {
      // System info refresh
      document.addEventListener('click', handleRefreshClick);

      // Clear cache
      document.addEventListener('click', handleClearCacheClick);
    }

    // Handle refresh button click
    function handleRefreshClick(event) {
      const target = event.target;

      if (!target.matches(settings.refreshButton)) {
        return;
      }

      event.preventDefault();
      refreshSystemInfo();
    }

    // Handle clear cache button click
    function handleClearCacheClick(event) {
      const target = event.target;

      if (!target.matches(settings.clearCacheButton)) {
        return;
      }

      event.preventDefault();

      if (confirm('Are you sure you want to clear the system information cache?')) {
        clearSystemInfoCache();
      }
    }

    // Refresh system information
    async function refreshSystemInfo() {
      if (isRefreshing) {
        return;
      }

      isRefreshing = true;
      const refreshButton = baseComponent.querySelector(settings.refreshButton);

      try {
        // Update button state
        if (refreshButton) {
          refreshButton.disabled = true;
          refreshButton.textContent = 'Refreshing...';
        }

        // Make API call using SystemApi
        const data = await window.ApiService.system.refresh();

        if (data.success) {
          // Update the system info content
          await updateSystemInfoContent();
          showNotification('System information refreshed successfully', 'success');
        } else {
          showNotification(data.error || 'Failed to refresh system information', 'error');
        }

      } catch (error) {
        console.error('Error refreshing system info:', error);
        showNotification('Failed to refresh system information', 'error');
      } finally {
        isRefreshing = false;

        // Restore button state
        if (refreshButton) {
          refreshButton.disabled = false;
          refreshButton.textContent = 'Refresh';
        }
      }
    }

    // Clear system information cache
    async function clearSystemInfoCache() {
      try {
        const data = await window.ApiService.system.clearCache();

        if (data.success) {
          showNotification('System information cache cleared successfully', 'success');
        } else {
          showNotification(data.error || 'Failed to clear cache', 'error');
        }

      } catch (error) {
        console.error('Error clearing cache:', error);
        showNotification('Failed to clear cache', 'error');
      }
    }

    // Update system info content
    async function updateSystemInfoContent() {
      const contentContainer = baseComponent.querySelector(settings.systemInfoContent);

      if (!contentContainer) {
        return;
      }

      try {
        // Get updated HTML content using SystemApi
        const html = await window.ApiService.system.getDashboardContent();
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const newContent = doc.querySelector('#system-info-content');

        if (newContent) {
          contentContainer.innerHTML = newContent.innerHTML;
        }
      } catch (error) {
        console.error('Error updating system info content:', error);
      }
    }

    // Show notification
    function showNotification(message, type = 'info') {
      // Create notification element
      const notification = document.createElement('div');
      notification.className = `notification notification-${type}`;
      notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 12px 16px;
        border-radius: 4px;
        color: white;
        font-size: 14px;
        z-index: 1000;
        max-width: 300px;
        word-wrap: break-word;
        opacity: 0;
        transform: translateY(-20px);
        transition: all 0.3s ease;
      `;

      // Set background color based on type
      switch (type) {
        case 'success':
          notification.style.backgroundColor = '#10b981';
          break;
        case 'error':
          notification.style.backgroundColor = '#ef4444';
          break;
        default:
          notification.style.backgroundColor = '#3b82f6';
      }

      notification.textContent = message;

      // Add to page
      if (document.body) {
        document.body.appendChild(notification);
      }

      // Animate in
      setTimeout(() => {
        notification.style.opacity = '1';
        notification.style.transform = 'translateY(0)';
      }, 100);

      // Remove after 5 seconds
      setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateY(-20px)';
        setTimeout(() => {
          if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
          }
        }, 300);
      }, 5000);
    }

    // Public API
    return {
      ...baseComponent,
      init,
      refreshSystemInfo,
      clearSystemInfoCache
    };
  };

  // Register component with DBWatcher
  if (window.DBWatcher && window.DBWatcher.register) {
    window.DBWatcher.register('dashboard', DashboardComponent);
  }

  // Auto-initialize when DOM is ready with better error handling
  function initializeDashboard() {
    try {
      if (document.querySelector('.dashboard-container') || document.querySelector('.tab-bar') || document.querySelector('#refresh-system-info') || document.querySelector('#clear-cache-system-info')) {
        const dashboard = DashboardComponent();
        dashboard.init();
      }
    } catch (error) {
      console.error('Error initializing dashboard:', error);
    }
  }

  // Multiple initialization strategies
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDashboard);
  } else {
    initializeDashboard();
  }
})();
