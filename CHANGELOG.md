# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.5] - 2025-06-15
### Testing

- Enhance gem installation testing by validating gem structure and contents


## [0.1.4] - 2025-06-15
### Testing

- Enhance gem installation testing by verifying gem loading and compatibility with Rails environment


## [0.1.3] - 2025-06-15
### Changed

- Enhance gem release workflow with installation testing and improve gemspec metadata


## [0.1.2] - 2025-06-15
### Changed

- Update release workflow to reflect gem name change from ClassMetrix to DB Watcher


## [0.1.1] - 2025-06-15

### Added

- Add GitHub Actions workflow for gem release process
- Add decorators, forms, services, repositories, and value objects for user management
- Add user management features with new views, routes, and database schema
- Enhance Dbwatcher middleware: add tracking feature tests and improve error handling
- Add bundle install step to test setup and update schema version to 8.0
- Add CI workflow, security checks, and Brakeman configuration
- Add Dependabot configuration and GitHub labels for better dependency management
- Add initial implementation of Dbwatcher with configuration, storage, and tracking features
- Add initial implementation of Dbwatcher gem

### Changed

- Refactor update_post_view_counts method to use parameterized query for incrementing views count
- Enhance RuboCop configuration, implement pre-commit hook, and improve middleware testing structure
- Refactor CI workflow: update gemspec validity check and improve gem loading verification

### Removed

- Remove TestingController and associated database operation methods


### Added

- **Service Objects Architecture**: Added dedicated service objects in `lib/dbwatcher/services/`
  - `TableStatisticsCollector`: Handles table statistics aggregation
  - `DashboardDataAggregator`: Manages dashboard data collection
  - `QueryFilterProcessor`: Processes query filtering and sorting
- **Modular Helper System**: Split ApplicationHelper into focused modules
  - `FormattingHelper`: Cell value formatting and JSON handling
  - `NavigationHelper`: Path helpers with configuration-based mounting and breadcrumbs
  - `SessionHelper`: Session status badges and duration formatting
  - `TableHelper`: Table display formatting and status indicators
  - `QueryHelper`: Query filtering and display helpers
- **Centralized Logging**: Added structured logging with performance metrics
- **Configuration System**: Enhanced with configurable mount path support
- Comprehensive dummy Rails application for testing and development
- Browser-based feature testing with Cucumber and Capybara
- Improved documentation and contributing guidelines
- Better code organization and style compliance

### Changed

- **Major Refactoring**: Extracted business logic from controllers to service objects
- **Naming Conventions**: Applied Ruby community standards for method and class names
- **Rails Engine Structure**: Moved services to `lib/` directory to avoid host app conflicts
- **Code Complexity Reduction**: Simplified methods using functional pipeline patterns
- Refactored testing controller for better maintainability
- Improved README with comprehensive usage examples
- Enhanced project structure and documentation

### Fixed
- **RuboCop Compliance**: Achieved 100% compliance (121 files inspected, 0 offenses detected)
  - Fixed ApplicationHelper module length violation (115 lines → modular structure)
  - Resolved SessionAPI method complexity issues (ABC size 25.08 → compliant)
  - Refactored NavigationHelper breadcrumbs method to reduce complexity
  - Fixed string concatenation and style issues throughout codebase
- **Navigation System**: Replaced hardcoded paths with configuration-based approach
  - Implemented `configured_mount_path` helper for flexible engine mounting
  - Added robust fallback system for route generation
  - Cleaned up breadcrumb generation with single-responsibility methods
- Performance improvements through better separation of concerns
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
