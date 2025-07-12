/**
 * Table API Service
 * Handles all table-related API calls for DBWatcher
 */

(function() {
  'use strict';

  // TableApi class definition
  class TableApi {
    constructor(config = {}) {
      this.config = {
        baseUrl: '/dbwatcher/api/v1',
        debug: false,
        ...config
      };
    }

    /**
     * Get all tables for a session
     * @param {string} sessionId - The session ID
     * @param {Object} params - Filter parameters (optional)
     * @returns {Promise<Object>} List of tables and metadata
     */
    async getAll(sessionId, params = {}) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables`,
          params
        );
      } catch (error) {
        console.error('Error fetching tables:', error);
        throw new Error('Failed to fetch tables');
      }
    }

    /**
     * Get details for a specific table
     * @param {string} sessionId - The session ID
     * @param {string} tableName - The table name
     * @returns {Promise<Object>} Table details
     */
    async getDetails(sessionId, tableName) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!tableName) {
        throw new Error('Table name is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables/${encodeURIComponent(tableName)}`
        );
      } catch (error) {
        console.error('Error fetching table details:', error);
        throw new Error('Failed to fetch table details');
      }
    }

    /**
     * Get changes data for tables
     * @param {string} sessionId - The session ID
     * @param {Object} params - Filter parameters (optional)
     * @returns {Promise<Object>} Tables changes data
     */
    async getChanges(sessionId, params = {}) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables/changes`,
          params
        );
      } catch (error) {
        console.error('Error fetching table changes:', error);
        throw new Error('Failed to fetch table changes');
      }
    }

    /**
     * Get table structure
     * @param {string} sessionId - The session ID
     * @param {string} tableName - The table name
     * @returns {Promise<Object>} Table structure details
     */
    async getStructure(sessionId, tableName) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!tableName) {
        throw new Error('Table name is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables/${encodeURIComponent(tableName)}/structure`
        );
      } catch (error) {
        console.error('Error fetching table structure:', error);
        throw new Error('Failed to fetch table structure');
      }
    }

    /**
     * Get table statistics
     * @param {string} sessionId - The session ID
     * @param {string} tableName - The table name
     * @returns {Promise<Object>} Table statistics
     */
    async getStats(sessionId, tableName) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!tableName) {
        throw new Error('Table name is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables/${encodeURIComponent(tableName)}/stats`
        );
      } catch (error) {
        console.error('Error fetching table statistics:', error);
        throw new Error('Failed to fetch table statistics');
      }
    }

    /**
     * Get table relationships
     * @param {string} sessionId - The session ID
     * @param {string} tableName - The table name
     * @returns {Promise<Object>} Table relationships
     */
    async getRelationships(sessionId, tableName) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!tableName) {
        throw new Error('Table name is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables/${encodeURIComponent(tableName)}/relationships`
        );
      } catch (error) {
        console.error('Error fetching table relationships:', error);
        throw new Error('Failed to fetch table relationships');
      }
    }

    /**
     * Get table summary data
     * @param {string} sessionId - The session ID
     * @param {Object} params - Filter parameters (optional)
     * @returns {Promise<Object>} Tables summary data
     */
    async getSummary(sessionId, params = {}) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/tables/summary`,
          params
        );
      } catch (error) {
        console.error('Error fetching tables summary:', error);
        throw new Error('Failed to fetch tables summary');
      }
    }
  }

  // Register with DBWatcher API service
  if (window.ApiService) {
    window.ApiService.table = new TableApi(window.ApiService.config);
  } else {
    console.error('ApiService not found. TableApi will not be registered.');
  }
})();
