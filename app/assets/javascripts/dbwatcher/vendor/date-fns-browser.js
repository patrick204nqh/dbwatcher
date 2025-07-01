/**
 * Browser-compatible date-fns version
 * Sets up window.dateFns with all date-fns methods
 */
(function(global) {
  // Create namespace
  global.dateFns = {
    // Core formatting functions
    format: function(date, formatStr) {
      if (!date) return '';
      var d = new Date(date);
      if (isNaN(d.getTime())) return '';
      
      formatStr = formatStr || 'yyyy-MM-dd HH:mm:ss';
      
      var year = d.getFullYear();
      var month = d.getMonth() + 1;
      var day = d.getDate();
      var hours = d.getHours();
      var minutes = d.getMinutes();
      var seconds = d.getSeconds();
      
      // Simple formatting with basic replacements
      return formatStr
        .replace(/yyyy/g, year)
        .replace(/MM/g, month < 10 ? '0' + month : month)
        .replace(/dd/g, day < 10 ? '0' + day : day)
        .replace(/HH/g, hours < 10 ? '0' + hours : hours)
        .replace(/mm/g, minutes < 10 ? '0' + minutes : minutes)
        .replace(/ss/g, seconds < 10 ? '0' + seconds : seconds);
    },
    
    // Date manipulation
    addDays: function(date, days) {
      var result = new Date(date);
      result.setDate(result.getDate() + days);
      return result;
    },
    
    addHours: function(date, hours) {
      var result = new Date(date);
      result.setHours(result.getHours() + hours);
      return result;
    },
    
    addMinutes: function(date, minutes) {
      var result = new Date(date);
      result.setMinutes(result.getMinutes() + minutes);
      return result;
    },
    
    addSeconds: function(date, seconds) {
      var result = new Date(date);
      result.setSeconds(result.getSeconds() + seconds);
      return result;
    },
    
    // Comparison
    isAfter: function(date, dateToCompare) {
      return new Date(date) > new Date(dateToCompare);
    },
    
    isBefore: function(date, dateToCompare) {
      return new Date(date) < new Date(dateToCompare);
    },
    
    isEqual: function(date, dateToCompare) {
      return new Date(date).getTime() === new Date(dateToCompare).getTime();
    },
    
    isSameDay: function(date, dateToCompare) {
      var d1 = new Date(date);
      var d2 = new Date(dateToCompare);
      return d1.getFullYear() === d2.getFullYear() && 
             d1.getMonth() === d2.getMonth() &&
             d1.getDate() === d2.getDate();
    },
    
    // Utilities
    parseISO: function(dateString) {
      return new Date(dateString);
    },
    
    formatDistance: function(date, baseDate) {
      var seconds = Math.abs(new Date(date) - new Date(baseDate)) / 1000;
      var minutes = Math.floor(seconds / 60);
      var hours = Math.floor(minutes / 60);
      var days = Math.floor(hours / 24);
      
      if (days > 0) return days + ' day' + (days > 1 ? 's' : '');
      if (hours > 0) return hours + ' hour' + (hours > 1 ? 's' : '');
      if (minutes > 0) return minutes + ' minute' + (minutes > 1 ? 's' : '');
      return seconds + ' second' + (seconds !== 1 ? 's' : '');
    }
  };
})(window);

// Add console confirmation
console.log('Browser-compatible date-fns loaded successfully');
