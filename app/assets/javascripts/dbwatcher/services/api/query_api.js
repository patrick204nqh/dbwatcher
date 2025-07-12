/**
 * Query API Service
 * Handles all query-related API calls for DBWatcher
 */

(function() {
  'use strict';

  // QueryApi class definition
  class QueryApi {
    constructor(config = {}) {
      this.config = {
        baseUrl: '/dbwatcher/api/v1',
        debug: false,
        ...config
      };
    }

    /**
     * Get all queries for a session
     * @param {string} sessionId - The session ID
     * @param {Object} params - Query parameters (optional)
     * @returns {Promise<Object>} List of queries and metadata
     */
    async getAll(sessionId, params = {}) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/queries`,
          params
        );
      } catch (error) {
        console.error('Error fetching queries:', error);
        throw new Error('Failed to fetch queries');
      }
    }

    /**
     * Get a specific query by ID
     * @param {string} sessionId - The session ID
     * @param {string} queryId - The query ID
     * @returns {Promise<Object>} Query details
     */
    async getById(sessionId, queryId) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!queryId) {
        throw new Error('Query ID is required');
      }

      try {
        return await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/queries/${queryId}`
        );
      } catch (error) {
        console.error('Error fetching query:', error);
        throw new Error('Failed to fetch query');
      }
    }

    /**
     * Create a new query
     * @param {string} sessionId - The session ID
     * @param {Object} queryData - The query data
     * @returns {Promise<Object>} Created query
     */
    async create(sessionId, queryData) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!queryData || !queryData.sql) {
        throw new Error('Query data with SQL is required');
      }

      try {
        return await window.ApiClient.post(
          `${this.config.baseUrl}/sessions/${sessionId}/queries`,
          queryData
        );
      } catch (error) {
        console.error('Error creating query:', error);
        throw new Error('Failed to create query');
      }
    }

    /**
     * Update an existing query
     * @param {string} sessionId - The session ID
     * @param {string} queryId - The query ID
     * @param {Object} queryData - The updated query data
     * @returns {Promise<Object>} Updated query
     */
    async update(sessionId, queryId, queryData) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!queryId) {
        throw new Error('Query ID is required');
      }

      if (!queryData) {
        throw new Error('Query data is required');
      }

      try {
        return await window.ApiClient.put(
          `${this.config.baseUrl}/sessions/${sessionId}/queries/${queryId}`,
          queryData
        );
      } catch (error) {
        console.error('Error updating query:', error);
        throw new Error('Failed to update query');
      }
    }

    /**
     * Delete a query
     * @param {string} sessionId - The session ID
     * @param {string} queryId - The query ID
     * @returns {Promise<Object>} Deletion status
     */
    async delete(sessionId, queryId) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!queryId) {
        throw new Error('Query ID is required');
      }

      try {
        return await window.ApiClient.delete(
          `${this.config.baseUrl}/sessions/${sessionId}/queries/${queryId}`
        );
      } catch (error) {
        console.error('Error deleting query:', error);
        throw new Error('Failed to delete query');
      }
    }

    /**
     * Execute a query
     * @param {string} sessionId - The session ID
     * @param {string} queryId - The query ID
     * @param {Object} params - Execution parameters (optional)
     * @returns {Promise<Object>} Query execution results
     */
    async execute(sessionId, queryId, params = {}) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!queryId) {
        throw new Error('Query ID is required');
      }

      try {
        return await window.ApiClient.post(
          `${this.config.baseUrl}/sessions/${sessionId}/queries/${queryId}/execute`,
          params
        );
      } catch (error) {
        console.error('Error executing query:', error);
        throw new Error('Failed to execute query');
      }
    }
  }

  // Register with DBWatcher API service
  if (window.ApiService) {
    window.ApiService.query = new QueryApi(window.ApiService.config);
  } else {
    console.error('ApiService not found. QueryApi will not be registered.');
  }
})();
