/**
 * Diagram API Service
 * Handles all diagram-related API calls for DBWatcher
 */

(function() {
  'use strict';

  // DiagramApi class definition
  class DiagramApi {
    constructor(config = {}) {
      this.config = {
        baseUrl: '/dbwatcher/api/v1',
        debug: false,
        ...config
      };
    }

    /**
     * Get available diagram types
     * @returns {Promise<Object>} Available diagram types and default type
     */
    async getDiagramTypes() {
      try {
        const response = await window.ApiClient.get(`${this.config.baseUrl}/diagrams/types`);
        return {
          types: response.types || {},
          default_type: response.default_type
        };
      } catch (error) {
        console.error('Error fetching diagram types:', error);
        throw new Error('Failed to fetch diagram types');
      }
    }

    /**
     * Get diagram data for a specific session and type
     * @param {string} sessionId - The session ID
     * @param {string} diagramType - The type of diagram to generate
     * @returns {Promise<Object>} Diagram content and metadata
     */
    async getDiagramData(sessionId, diagramType) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!diagramType) {
        throw new Error('Diagram type is required');
      }

      try {
        const response = await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/diagrams`,
          { type: diagramType }
        );

        if (!response.content) {
          throw new Error('No diagram content received');
        }

        return {
          content: response.content,
          metadata: response.metadata || {}
        };
      } catch (error) {
        console.error('Error fetching diagram data:', error);
        throw new Error('Failed to fetch diagram data');
      }
    }

    /**
     * Export diagram as SVG
     * @param {string} sessionId - The session ID
     * @param {string} diagramType - The type of diagram to export
     * @returns {Promise<Object>} SVG content and filename
     */
    async exportDiagram(sessionId, diagramType) {
      if (!sessionId) {
        throw new Error('Session ID is required');
      }

      if (!diagramType) {
        throw new Error('Diagram type is required');
      }

      try {
        const response = await window.ApiClient.get(
          `${this.config.baseUrl}/sessions/${sessionId}/diagrams/export`,
          { type: diagramType, format: 'svg' }
        );

        return {
          content: response.content,
          filename: response.filename || `dbwatcher-${diagramType}-diagram.svg`
        };
      } catch (error) {
        console.error('Error exporting diagram:', error);
        throw new Error('Failed to export diagram');
      }
    }
  }

  // Register with DBWatcher API service
  if (window.ApiService) {
    window.ApiService.diagram = new DiagramApi(window.ApiService.config);
  } else {
    console.error('ApiService not found. DiagramApi will not be registered.');
  }
})();
