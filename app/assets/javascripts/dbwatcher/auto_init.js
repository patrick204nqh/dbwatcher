/**
 * DBWatcher Auto-Initializer
 * This file is the main entry point for auto-initializing the DBWatcher system
 * and its components when loaded into the browser.
 */

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
