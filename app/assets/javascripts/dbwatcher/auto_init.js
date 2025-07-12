/**
 * DBWatcher Auto-Initializer
 * This file is the main entry point for auto-initializing the DBWatcher system
 * and its components when loaded into the browser.
 */

// Import API modules
import SessionApi from './services/api/session_api';
import SystemApi from './services/api/system_api';
import DiagramApi from './services/api/diagram_api';
import QueryApi from './services/api/query_api';
import TableApi from './services/api/table_api';

document.addEventListener('DOMContentLoaded', function() {
  // Initialize DBWatcher
  if (window.DBWatcher) {
    window.DBWatcher.init({
      debug: false
    });
  } else {
    console.error('DBWatcher not loaded!');
  }

  // Initialize API Service
  if (window.ApiService) {
    window.ApiService.init({
      baseUrl: '/dbwatcher/api/v1',
      timeout: 30000,
      debug: window.DBWatcher?.debug || false
    });

    // Register API modules
    window.ApiService.registerModule('session', SessionApi);
    window.ApiService.registerModule('system', SystemApi);
    window.ApiService.registerModule('diagram', DiagramApi);
    window.ApiService.registerModule('query', QueryApi);
    window.ApiService.registerModule('table', TableApi);
  } else {
    console.warn('ApiService not loaded - API functionality may be limited');
  }

  // Initialize Alpine Store
  if (window.Alpine) {
    document.dispatchEvent(new Event('alpine:init'));
  } else {
    console.warn('Alpine.js not loaded!');
  }
});
