/**
 * DBWatcher Error Types and Utilities
 * Provides standardized error handling for the application
 */

// Base error class for DBWatcher
class DBWatcherError extends Error {
  constructor(message, options = {}) {
    super(message);
    this.name = 'DBWatcherError';
    this.timestamp = new Date().toISOString();
    this.context = options.context || null;
    this.originalError = options.originalError || null;
    this.metadata = options.metadata || {};
    this.recoverable = options.recoverable !== false; // Default to true
  }

  // Format error for logging
  toLog() {
    return {
      name: this.name,
      message: this.message,
      context: this.context,
      timestamp: this.timestamp,
      metadata: this.metadata,
      stack: this.stack,
      originalError: this.originalError
    };
  }

  // Format error for user display
  toUserMessage() {
    return this.message;
  }
}

// API-related errors
class APIError extends DBWatcherError {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'APIError';
    this.status = options.status || null;
    this.endpoint = options.endpoint || null;
    this.method = options.method || null;
  }

  toUserMessage() {
    if (this.status === 404) {
      return 'The requested resource was not found.';
    } else if (this.status >= 500) {
      return 'A server error occurred. Please try again later.';
    }
    return this.message;
  }
}

// Component-related errors
class ComponentError extends DBWatcherError {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'ComponentError';
    this.componentName = options.componentName || null;
    this.action = options.action || null;
  }
}

// Validation errors
class ValidationError extends DBWatcherError {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'ValidationError';
    this.fields = options.fields || [];
    this.recoverable = true;
  }

  toUserMessage() {
    if (this.fields.length > 0) {
      return `Validation failed: ${this.fields.join(', ')}`;
    }
    return this.message;
  }
}

// Configuration errors
class ConfigurationError extends DBWatcherError {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'ConfigurationError';
    this.configKey = options.configKey || null;
    this.recoverable = false;
  }
}

// State errors
class StateError extends DBWatcherError {
  constructor(message, options = {}) {
    super(message, options);
    this.name = 'StateError';
    this.expectedState = options.expectedState || null;
    this.actualState = options.actualState || null;
  }

  toUserMessage() {
    return 'The application is in an unexpected state. Please refresh the page.';
  }
}

// Error factory for creating appropriate error types
const ErrorFactory = {
  create(type, message, options = {}) {
    switch (type) {
      case 'api':
        return new APIError(message, options);
      case 'component':
        return new ComponentError(message, options);
      case 'validation':
        return new ValidationError(message, options);
      case 'configuration':
        return new ConfigurationError(message, options);
      case 'state':
        return new StateError(message, options);
      default:
        return new DBWatcherError(message, options);
    }
  }
};

// Error utilities
const ErrorUtils = {
  // Format error for logging
  formatError(error) {
    if (error instanceof DBWatcherError) {
      return error.toLog();
    }
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    };
  },

  // Get user-friendly message
  getUserMessage(error) {
    if (error instanceof DBWatcherError) {
      return error.toUserMessage();
    }
    return 'An unexpected error occurred.';
  },

  // Check if error is recoverable
  isRecoverable(error) {
    if (error instanceof DBWatcherError) {
      return error.recoverable;
    }
    return true; // Default to true for unknown errors
  }
};

// Export error types and utilities
window.DBWatcher = window.DBWatcher || {};
window.DBWatcher.Errors = {
  DBWatcherError,
  APIError,
  ComponentError,
  ValidationError,
  ConfigurationError,
  StateError,
  ErrorFactory,
  ErrorUtils
};
