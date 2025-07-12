/**
 * DBWatcher Utilities
 * Provides standardized utility functions for common operations
 */

// Date and time utilities
const DateUtils = {
  // Format date using date-fns or fallback
  formatDate(date, format = 'yyyy-MM-dd') {
    return window.dateFns?.format(date, format) ||
      new Date(date).toISOString().split('T')[0];
  },

  // Format time using date-fns or fallback
  formatTime(date, format = 'HH:mm:ss') {
    return window.dateFns?.format(date, format) ||
      new Date(date).toTimeString().split(' ')[0];
  },

  // Format datetime using date-fns or fallback
  formatDateTime(date, format = 'yyyy-MM-dd HH:mm:ss') {
    return window.dateFns?.format(date, format) ||
      new Date(date).toISOString().replace('T', ' ').split('.')[0];
  },

  // Parse date string to Date object
  parseDate(dateString) {
    return window.dateFns?.parseISO(dateString) || new Date(dateString);
  },

  // Get relative time (e.g., "2 hours ago")
  getRelativeTime(date) {
    if (window.dateFns?.formatDistanceToNow) {
      return window.dateFns.formatDistanceToNow(
        typeof date === 'string' ? this.parseDate(date) : date,
        { addSuffix: true }
      );
    }
    return new Date(date).toLocaleString();
  }
};

// Collection utilities
const CollectionUtils = {
  // Check if value is empty using lodash or fallback
  isEmpty(value) {
    return window._ ? _.isEmpty(value) : (
      Array.isArray(value) ? value.length === 0 :
      typeof value === 'object' && value !== null ? Object.keys(value).length === 0 : !value
    );
  },

  // Group array by key
  groupBy(array, key) {
    return window._ ? _.groupBy(array, key) :
      array.reduce((result, item) => {
        const group = item[key];
        result[group] = result[group] || [];
        result[group].push(item);
        return result;
      }, {});
  },

  // Sort array by key
  sortBy(array, key, order = 'asc') {
    if (window._) {
      return order === 'asc' ? _.sortBy(array, key) : _.sortBy(array, key).reverse();
    }
    return [...array].sort((a, b) => {
      const aVal = a[key];
      const bVal = b[key];
      return order === 'asc' ?
        (aVal > bVal ? 1 : aVal < bVal ? -1 : 0) :
        (aVal < bVal ? 1 : aVal > bVal ? -1 : 0);
    });
  },

  // Filter array by predicate
  filter(array, predicate) {
    return window._ ? _.filter(array, predicate) : array.filter(predicate);
  },

  // Find item in array by predicate
  find(array, predicate) {
    return window._ ? _.find(array, predicate) : array.find(predicate);
  }
};

// Performance utilities
const PerformanceUtils = {
  // Debounce function using lodash or fallback
  debounce(fn, wait) {
    if (window._) {
      return _.debounce(fn, wait);
    }
    let timeout;
    return function(...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => fn.apply(this, args), wait);
    };
  },

  // Throttle function using lodash or fallback
  throttle(fn, wait) {
    if (window._) {
      return _.throttle(fn, wait);
    }
    let lastCall = 0;
    return function(...args) {
      const now = Date.now();
      if (now - lastCall >= wait) {
        fn.apply(this, args);
        lastCall = now;
      }
    };
  },

  // Memoize function using lodash or fallback
  memoize(fn) {
    return window._ ? _.memoize(fn) : function(...args) {
      const key = JSON.stringify(args);
      const cache = this._memoizeCache = this._memoizeCache || {};
      return cache[key] || (cache[key] = fn.apply(this, args));
    };
  }
};

// URL utilities
const URLUtils = {
  // Update URL parameter
  updateParam(param, value) {
    const url = new URL(window.location.href);
    if (value) {
      url.searchParams.set(param, value);
    } else {
      url.searchParams.delete(param);
    }
    window.history.replaceState({}, '', url);
  },

  // Get URL parameter
  getParam(param) {
    return new URLSearchParams(window.location.search).get(param);
  },

  // Get all URL parameters
  getAllParams() {
    const params = {};
    new URLSearchParams(window.location.search).forEach((value, key) => {
      params[key] = value;
    });
    return params;
  },

  // Build URL with parameters
  buildURL(base, params = {}) {
    const url = new URL(base, window.location.origin);
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        url.searchParams.set(key, value);
      }
    });
    return url.toString();
  }
};

// DOM utilities
const DOMUtils = {
  // Safe querySelector with error handling
  querySelector(selector, context = document) {
    try {
      return context.querySelector(selector);
    } catch (e) {
      console.warn('Error accessing DOM element:', selector, e);
      return null;
    }
  },

  // Safe querySelectorAll with error handling
  querySelectorAll(selector, context = document) {
    try {
      return Array.from(context.querySelectorAll(selector));
    } catch (e) {
      console.warn('Error accessing DOM elements:', selector, e);
      return [];
    }
  },

  // Add event listener with automatic cleanup
  addListener(element, event, handler, options = {}) {
    if (!element) return null;
    element.addEventListener(event, handler, options);
    return () => element.removeEventListener(event, handler, options);
  },

  // Add multiple event listeners
  addListeners(element, events) {
    if (!element) return [];
    return Object.entries(events).map(([event, handler]) =>
      this.addListener(element, event, handler)
    );
  },

  // Remove multiple event listeners
  removeListeners(cleanupFns) {
    cleanupFns.forEach(cleanup => cleanup && cleanup());
  }
};

// String utilities
const StringUtils = {
  // Capitalize first letter
  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  },

  // Convert to camelCase
  camelCase(str) {
    return window._ ? _.camelCase(str) :
      str.toLowerCase()
         .replace(/[^a-zA-Z0-9]+(.)/g, (_, chr) => chr.toUpperCase());
  },

  // Convert to snake_case
  snakeCase(str) {
    return window._ ? _.snakeCase(str) :
      str.replace(/[A-Z]/g, chr => `_${chr.toLowerCase()}`);
  },

  // Truncate string
  truncate(str, length = 30, suffix = '...') {
    return str.length > length ? str.slice(0, length - suffix.length) + suffix : str;
  }
};

// Object utilities
const ObjectUtils = {
  // Deep clone object
  clone(obj) {
    return window._ ? _.cloneDeep(obj) : JSON.parse(JSON.stringify(obj));
  },

  // Merge objects
  merge(...objects) {
    return window._ ? _.merge({}, ...objects) :
      objects.reduce((result, obj) => ({...result, ...obj}), {});
  },

  // Pick properties from object
  pick(obj, props) {
    return window._ ? _.pick(obj, props) :
      props.reduce((result, prop) => {
        if (obj.hasOwnProperty(prop)) {
          result[prop] = obj[prop];
        }
        return result;
      }, {});
  },

  // Omit properties from object
  omit(obj, props) {
    return window._ ? _.omit(obj, props) :
      Object.entries(obj).reduce((result, [key, value]) => {
        if (!props.includes(key)) {
          result[key] = value;
        }
        return result;
      }, {});
  }
};

// Export utilities
window.DBWatcher = window.DBWatcher || {};
window.DBWatcher.Utils = {
  Date: DateUtils,
  Collection: CollectionUtils,
  Performance: PerformanceUtils,
  URL: URLUtils,
  DOM: DOMUtils,
  String: StringUtils,
  Object: ObjectUtils
};
