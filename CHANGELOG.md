# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive dummy Rails application for testing and development
- Browser-based feature testing with Cucumber and Capybara
- Improved documentation and contributing guidelines
- Better code organization and style compliance

### Changed
- Refactored testing controller for better maintainability
- Improved README with comprehensive usage examples
- Enhanced project structure and documentation

### Fixed
- Code style issues throughout the dummy application
- Syntax errors in testing controllers
- Missing documentation and setup instructions

## [0.1.0] - Initial Release

### Added
- Core database tracking functionality
- Rails engine with web dashboard
- File-based storage system
- URL-based tracking activation (`?dbwatch=true`)
- Programmatic tracking with `Dbwatcher.track`
- Automatic cleanup and session management
- Alpine.js and Tailwind CSS web interface
- Basic configuration options
- Middleware for request-based tracking

### Features
- Track INSERT, UPDATE, DELETE operations
- Session-based organization of tracking data
- Real-time web dashboard
- Zero additional database dependencies
- Development-focused design
- Easy integration with existing Rails applications
