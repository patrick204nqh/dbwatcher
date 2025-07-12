/**
 * Session API Service
 * Centralized service for all session-related API operations
 */

const SessionApi = {
  /**
   * Get session summary data
   * @param {string} sessionId - The session ID
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Session summary data
   */
  getSummaryData(sessionId, options = {}) {
    if (!sessionId) {
      return Promise.reject(new Error('Session ID is required'));
    }

    return window.ApiClient.get(`sessions/${sessionId}/summary_data`, {}, options);
  },

  /**
   * Get session details
   * @param {string} sessionId - The session ID
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Session details
   */
  getDetails(sessionId, options = {}) {
    if (!sessionId) {
      return Promise.reject(new Error('Session ID is required'));
    }

    return window.ApiClient.get(`sessions/${sessionId}`, {}, options);
  },

  /**
   * Get all sessions
   * @param {Object} params - Query parameters
   * @param {Object} options - Additional request options
   * @returns {Promise<Array>} - List of sessions
   */
  getAll(params = {}, options = {}) {
    return window.ApiClient.get('sessions', params, options);
  },

  /**
   * Get session timeline data
   * @param {string} sessionId - The session ID
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Timeline data
   */
  getTimelineData(sessionId, options = {}) {
    if (!sessionId) {
      return Promise.reject(new Error('Session ID is required'));
    }

    return window.ApiClient.get(`sessions/${sessionId}/timeline_data`, {}, options);
  },

  /**
   * Get session tables data
   * @param {string} sessionId - The session ID
   * @param {Object} params - Query parameters (filters, etc.)
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Tables data
   */
  getTablesData(sessionId, params = {}, options = {}) {
    if (!sessionId) {
      return Promise.reject(new Error('Session ID is required'));
    }

    return window.ApiClient.get(`sessions/${sessionId}/tables_data`, params, options);
  },

  /**
   * Get available diagram types
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Available diagram types
   */
  getDiagramTypes(options = {}) {
    return window.ApiClient.get('sessions/diagram_types', {}, options);
  },

  /**
   * Get diagram data for a session
   * @param {string} sessionId - The session ID
   * @param {string} type - The diagram type
   * @param {Object} options - Additional request options
   * @returns {Promise<Object>} - Diagram data
   */
  getDiagramData(sessionId, type, options = {}) {
    if (!sessionId) {
      return Promise.reject(new Error('Session ID is required'));
    }

    if (!type) {
      return Promise.reject(new Error('Diagram type is required'));
    }

    return window.ApiClient.get(`sessions/${sessionId}/diagram_data`, { type }, options);
  }
};

// Export the service
export default SessionApi;
