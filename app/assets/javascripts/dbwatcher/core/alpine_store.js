// Alpine.js Global Store for DBWatcher
// Provides centralized state management for sessions UI

document.addEventListener('alpine:init', () => {
  Alpine.store('dbwatcher', {
    // Session state
    currentSession: null,
    sessions: [],

    // UI state
    activeTab: 'changes',
    loading: false,
    error: null,

    // Cache for API responses
    cache: {
      changes: new Map(),
      summary: new Map(),
      diagrams: new Map()
    },

    // Cache TTL in milliseconds (5 minutes)
    cacheTtl: 5 * 60 * 1000,

    // Initialize store
    init() {
      console.log('DBWatcher Alpine store initialized');
    },

    // Session management
    setCurrentSession(session) {
      this.currentSession = session;
    },

    // Tab navigation
    setActiveTab(tab) {
      this.activeTab = tab;
      this.updateUrl(tab);
    },

    updateUrl(tab) {
      if (typeof window !== 'undefined') {
        const url = new URL(window.location);
        url.searchParams.set('tab', tab);
        window.history.pushState({}, '', url);
      }
    },

    // Cache management
    getCacheKey(type, sessionId, params = {}) {
      const paramString = Object.keys(params)
        .sort()
        .map(key => `${key}=${params[key]}`)
        .join('&');
      return `${type}_${sessionId}_${paramString}`;
    },

    setCache(type, key, data) {
      this.cache[type].set(key, {
        data: data,
        timestamp: Date.now()
      });
    },

    getCache(type, key) {
      const cached = this.cache[type].get(key);
      if (!cached) return null;

      // Check if cache is still valid
      if (Date.now() - cached.timestamp > this.cacheTtl) {
        this.cache[type].delete(key);
        return null;
      }

      return cached.data;
    },

    clearCache(type = null) {
      if (type) {
        this.cache[type].clear();
      } else {
        Object.keys(this.cache).forEach(key => {
          this.cache[key].clear();
        });
      }
    },

    // Error handling
    setError(error) {
      this.error = error;
      console.error('DBWatcher error:', error);
    },

    clearError() {
      this.error = null;
    },

    // Loading state
    setLoading(loading) {
      this.loading = loading;
    }
  });
});

// Session navigation component
function sessionNavigation(sessionId) {
  return {
    sessionId: sessionId,

    init() {
      // Set current session in store
      Alpine.store('dbwatcher').setCurrentSession({ id: this.sessionId });

      // Handle browser navigation
      window.addEventListener('popstate', () => {
        const params = new URLSearchParams(window.location.search);
        const tab = params.get('tab') || 'changes';
        Alpine.store('dbwatcher').setActiveTab(tab);
      });
    },

    navigateToTab(tab) {
      Alpine.store('dbwatcher').setActiveTab(tab);
    },

    get activeTab() {
      return Alpine.store('dbwatcher').activeTab;
    },

    get loading() {
      return Alpine.store('dbwatcher').loading;
    },

    get error() {
      return Alpine.store('dbwatcher').error;
    }
  };
}
