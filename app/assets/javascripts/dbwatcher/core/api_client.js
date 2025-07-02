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
    if (endpoint.startsWith('http') || endpoint.startsWith('/')) {
      return endpoint;
    }

    return `${this.baseURL}/${endpoint}`;
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
        url.searchParams.append(key, value);
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
      return this.handleError(error);
    }
  },

  // Handle response processing
  async handleResponse(response) {
    if (!response.ok) {
      const error = new Error(`HTTP error ${response.status}: ${response.statusText}`);
      error.status = response.status;
      error.statusText = response.statusText;

      try {
        error.data = await response.json();
      } catch (e) {
        error.data = null;
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
      console.error('Request aborted');
    }

    if (error.message === 'Request timeout') {
      console.error('Request timeout');
    }

    if (error.status) {
      console.error(`HTTP error: ${error.status} ${error.statusText}`);
    }

    throw error;
  },

  // Convenience methods
  get(endpoint, params = {}, options = {}) {
    return this.request('GET', endpoint, { params, ...options });
  },

  post(endpoint, body = {}, options = {}) {
    return this.request('POST', endpoint, { body, ...options });
  },

  put(endpoint, body = {}, options = {}) {
    return this.request('PUT', endpoint, { body, ...options });
  },

  patch(endpoint, body = {}, options = {}) {
    return this.request('PATCH', endpoint, { body, ...options });
  },

  delete(endpoint, options = {}) {
    return this.request('DELETE', endpoint, options);
  }
};

// Register with DBWatcher if available
if (window.DBWatcher) {
  window.DBWatcher.ApiClient = ApiClient;
}

// Make available globally
window.ApiClient = ApiClient;
