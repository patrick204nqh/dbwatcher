/**
 * API Client for DBWatcher
 *
 * Centralized API communication with error handling,
 * authentication, and response processing.
 */

const ApiClient = {
  // Base configuration
  baseURL: '/dbwatcher/api/v1',
  timeout: 30000,

  // Default headers
  defaultHeaders: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },

  // Add CSRF token if available
  getHeaders(additionalHeaders = {}) {
    const headers = { ...this.defaultHeaders, ...additionalHeaders };

    // Add CSRF token for Rails
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    if (csrfToken) {
      headers['X-CSRF-Token'] = csrfToken;
    }

    return headers;
  },

  // Build full URL
  buildURL(endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }

    const base = endpoint.startsWith('/') ? '' : this.baseURL;
    return `${base}${endpoint}`;
  },

  // Generic request method
  async request(method, endpoint, options = {}) {
    const {
      body,
      headers = {},
      params = {},
      timeout = this.timeout,
      ...fetchOptions
    } = options;

    const url = new URL(this.buildURL(endpoint), window.location.origin);

    // Add query parameters
    Object.entries(params).forEach(([key, value]) => {
      if (value !== null && value !== undefined) {
        url.searchParams.set(key, value);
      }
    });

    const config = {
      method,
      headers: this.getHeaders(headers),
      ...fetchOptions
    };

    // Add body for non-GET requests
    if (body && method !== 'GET') {
      config.body = typeof body === 'string' ? body : JSON.stringify(body);
    }

    // Create timeout promise
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Request timeout')), timeout);
    });

    try {
      const response = await Promise.race([
        fetch(url, config),
        timeoutPromise
      ]);

      return await this.handleResponse(response);
    } catch (error) {
      console.error(`API request failed: ${method} ${endpoint}`, error);
      throw this.handleError(error);
    }
  },

  // Handle response processing
  async handleResponse(response) {
    if (!response.ok) {
      const error = new Error(`HTTP ${response.status}: ${response.statusText}`);
      error.status = response.status;
      error.statusText = response.statusText;

      // Try to get error details from response
      try {
        const errorData = await response.json();
        error.details = errorData;
        if (errorData.error) {
          error.message = errorData.error;
        }
      } catch (parseError) {
        // Response not JSON, use status text
      }

      throw error;
    }

    // Handle different content types
    const contentType = response.headers.get('content-type');

    if (contentType?.includes('application/json')) {
      return await response.json();
    } else if (contentType?.includes('text/')) {
      return await response.text();
    } else {
      return response;
    }
  },

  // Handle errors consistently
  handleError(error) {
    if (error.name === 'AbortError') {
      return new Error('Request was cancelled');
    }

    if (error.message === 'Request timeout') {
      return new Error('Request timed out. Please try again.');
    }

    if (error.status) {
      switch (error.status) {
        case 401:
          return new Error('Authentication required');
        case 403:
          return new Error('Access forbidden');
        case 404:
          return new Error('Resource not found');
        case 422:
          return new Error(error.details?.error || 'Invalid request');
        case 500:
          return new Error('Server error. Please try again later.');
        default:
          return error;
      }
    }

    return error;
  },

  // Convenience methods
  async get(endpoint, params = {}, options = {}) {
    return this.request('GET', endpoint, { params, ...options });
  },

  async post(endpoint, body = {}, options = {}) {
    return this.request('POST', endpoint, { body, ...options });
  },

  async put(endpoint, body = {}, options = {}) {
    return this.request('PUT', endpoint, { body, ...options });
  },

  async patch(endpoint, body = {}, options = {}) {
    return this.request('PATCH', endpoint, { body, ...options });
  },

  async delete(endpoint, options = {}) {
    return this.request('DELETE', endpoint, options);
  }
};

// Make available globally
window.ApiClient = ApiClient;
