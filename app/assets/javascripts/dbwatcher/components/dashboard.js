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
    },
    ENDPOINTS: {
      refresh: '/dbwatcher/dashboard/system_info/refresh',
      clearCache: '/dbwatcher/dashboard/system_info/clear_cache',
      dashboard: '/dbwatcher',
      systemInfo: '/dbwatcher/dashboard/system_info'
    }
  };

  // Dashboard Component Factory
  const DashboardComponent = function(config = {}) {
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
      // Tab switching
      document.addEventListener('click', handleTabClick);
      
      // System info refresh
      document.addEventListener('click', handleRefreshClick);
      
      // Clear cache
      document.addEventListener('click', handleClearCacheClick);
    }
    
    // Handle tab click
    function handleTabClick(event) {
      const target = event.target;
      
      if (!target.matches(settings.tab)) {
        return;
      }
      
      event.preventDefault();
      const tabId = target.getAttribute('data-tab');
      
      console.log('Tab clicked:', tabId);
      
      // Handle system info tab - redirect to dedicated page
      if (tabId === 'system-info') {
        window.location.href = CONFIG.ENDPOINTS.systemInfo;
        return;
      }
      
      // Handle overview tab - redirect to dashboard
      if (tabId === 'overview') {
        window.location.href = CONFIG.ENDPOINTS.dashboard;
        return;
      }
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
      const refreshButton = safeQuerySelector(settings.refreshButton);
      
      try {
        // Update button state
        if (refreshButton) {
          refreshButton.disabled = true;
          refreshButton.textContent = 'Refreshing...';
        }
        
        // Make API call
        const response = await fetch(CONFIG.ENDPOINTS.refresh, {
          method: 'POST',
          headers: utils.getApiHeaders()
        });
        
        const data = await utils.handleApiResponse(response);
        
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
        const response = await fetch(CONFIG.ENDPOINTS.clearCache, {
          method: 'DELETE',
          headers: utils.getApiHeaders()
        });
        
        const data = await utils.handleApiResponse(response);
        
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
      const contentContainer = safeQuerySelector(settings.systemInfoContent);
      
      if (!contentContainer) {
        return;
      }
      
      try {
        // Make request to get updated HTML content
        const response = await fetch(CONFIG.ENDPOINTS.dashboard, {
          headers: {
            'Accept': 'text/html',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (response.ok) {
          const html = await response.text();
          const parser = new DOMParser();
          const doc = parser.parseFromString(html, 'text/html');
          const newContent = doc.querySelector('#system-info-content');
          
          if (newContent) {
            contentContainer.innerHTML = newContent.innerHTML;
          }
        }
      } catch (error) {
        console.error('Error updating system info content:', error);
      }
    }

    // Safe DOM access helper
    function safeQuerySelector(selector) {
      try {
        return document.querySelector(selector);
      } catch (e) {
        console.warn('Error accessing DOM element:', selector, e);
        return null;
      }
    }


    // Utility functions
    const utils = {
      // Get CSRF token
      getCsrfToken() {
        const metaTag = safeQuerySelector('meta[name="csrf-token"]');
        return metaTag?.getAttribute('content');
      },
      
      // Common headers for API requests
      getApiHeaders() {
        return {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCsrfToken()
        };
      },
      
      // Handle API response
      async handleApiResponse(response) {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        return await response.json();
      }
    };

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
      init,
      refreshSystemInfo,
      clearSystemInfoCache
    };
  };

  // Register component with DBWatcher
  if (window.DBWatcher && window.DBWatcher.register) {
    window.DBWatcher.register('dashboard', DashboardComponent);
  }

  // Safe DOM access helper
  function safeQuerySelector(selector) {
    try {
      return document.querySelector(selector);
    } catch (e) {
      console.warn('Error accessing DOM element:', selector, e);
      return null;
    }
  }

  // Auto-initialize when DOM is ready with better error handling
  function initializeDashboard() {
    try {
      if (safeQuerySelector('.dashboard-container') || safeQuerySelector('.tab-bar') || safeQuerySelector('#refresh-system-info') || safeQuerySelector('#clear-cache-system-info')) {
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
  } else if (document.readyState === 'interactive' || document.readyState === 'complete') {
    // DOM is already loaded, but wait a bit for Alpine to initialize
    setTimeout(initializeDashboard, 100);
  }

  // Also listen for Alpine initialization
  document.addEventListener('alpine:init', () => {
    setTimeout(initializeDashboard, 50);
  });

})();