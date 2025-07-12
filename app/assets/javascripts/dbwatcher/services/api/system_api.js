/**
 * System API Service
 * Centralized service for all system-related API operations
 */

const SystemApi = {
  /**
   * Refresh system information
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Refresh result
   */
  refresh(options = {}) {
    return window.ApiClient.post('/dbwatcher/dashboard/system_info/refresh', {}, {
      ...options,
      fullUrl: true // Use the full URL as provided
    });
  },

  /**
   * Clear system information cache
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Clear cache result
   */
  clearCache(options = {}) {
    return window.ApiClient.delete('/dbwatcher/dashboard/system_info/clear_cache', {}, {
      ...options,
      fullUrl: true // Use the full URL as provided
    });
  },

  /**
   * Get system information
   * @param {Object} params - Query parameters
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - System information
   */
  getInfo(params = {}, options = {}) {
    return window.ApiClient.get('/dbwatcher/system_info', params, {
      ...options,
      fullUrl: true // Use the full URL as provided
    });
  },

  /**
   * Get dashboard HTML content
   * @param {Object} options - Additional request options
   * @returns {Promise<string>} - Dashboard HTML content
   */
  getDashboardContent(options = {}) {
    return window.ApiClient.get('/dbwatcher/dashboard', {}, {
      ...options,
      fullUrl: true,
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    });
  }
};

// Export the service
export default SystemApi;
