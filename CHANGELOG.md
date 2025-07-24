# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.6] - 2025-07-24

### Added

- Improve auto-merge logic for Dependabot PRs with enhanced safety checks
- Add repository checkout step for CI notification on pull requests
- Update PR status reporting to include all checks results
- Update bot setup guide and improve CI notification formatting
- Enhance CI notification with app token generation and detailed PR quality report
- Add setup guide for dbwatcher-ci GitHub App and integrate app token generation in auto-merge workflow
- Enhance Slack notifications with detailed context and improved formatting for CI and release workflows
- Add SVG icon for DBWatcher with detailed vector paths


### Changed

- Bump the production-dependencies group with 8 updates (#45)
- Update README.md


### Fixed

- Clean up CI notification formatting and remove unnecessary comments


### CI/CD

- Bump slackapi/slack-github-action from 2.0.0 to 2.1.1 (#43)
- Bump lewagon/wait-on-check-action from 1.3.4 to 1.4.0 (#44)


## [1.1.5] - 2025-07-20

### Added

- Implement base class for diagram data objects and refactor related classes
- Add GitHub Personal Access Token configuration to environment files and update MCP server settings
- Add DevContainer setup and update MCP server configurations
- Add ActiveRecord introspection and association analysis utilities
- Enhance record ID extraction to support changes in hash and array formats
- Enhance record ID extraction to handle nested changes and arrays
- Update logo size and text styling in application layout
- Implement attachments, categories, and skills models with associations and validations
- Update Node.js version to 22 and add example for GITHUB_TOKEN in .envrc
- Add devcontainer and setup scripts for development environment
- Add rulesets for main branch and release tag protection
- Add auto-merge workflow for Dependabot pull requests
- Add stale label and workflow for managing inactive issues and PRs
- Update README and views to enhance branding with DBWatcher logo and favicon
- Add web app manifest and icons for dbwatcher


### Changed

- Enhance sticky column and scrollbar styles with improved opacity and transition effects
- Enhance auto-merge workflow with improved variable handling and safety checks
- Improve layout and styling of sessions index page
- Update configuration methods for clarity and consistency
- Simplify configuration options and update related code references
- Consolidate and rename testing operations for clarity and consistency
- Standardize quotes and formatting in model and migration files
- Deps-dev(deps-dev): bump cucumber-html-formatter from 21.12.0 to 21.13.0


### Fixed

- Ensure proper newline at end of file in multiple Ruby modules

### Documentation

- Add a blank line for improved readability in README
- Update screenshots in README and screenshots.md for improved clarity and version accuracy
- Update README to enhance clarity and add resource links
- Enhance README configuration section for clarity and detail
- Update README to include RubyGems downloads and license badge
- Update README with configuration options and usage examples


### CI/CD

- Update Slack integration to use chat.postMessage method for notifications feat: add .gitignore for Qlty configuration files feat: add .yamllint.yaml configuration for YAML linting feat: add qlty.toml configuration for Qlty CLI and Cloud docs: update Slack integration README to reflect new method usage
- Update Slack notification integration to use bot token and improve message structure
- Update Slack notification integration to use new Slack API and improve message formatting
- Bump crazy-max/ghaction-github-labeler


## [1.1.4] - 2025-07-12
### Added

- Refactor diagram strategies to inherit from StandardDiagramStrategy and enhance logging in DiagramSystem
- Add debug logging configuration and enhance logging in diagram generation services
- Refactor diagram generation strategies with helper methods for content generation
- Refactor release workflow to improve dry run handling and version extraction
- Enhance release workflow with dry run flag handling and validation
- Update release workflow to use gemspec version and improve dry run handling


### Changed

- Rename pattern checking methods for clarity and consistency
- Enhance self-referential column detection logic and streamline pattern checks
- Remove quotes from color values in GitHub labels configuration
- Update GitHub labels for DBWatcher configuration and enhance component categorization
- Remove obsolete diagram visualization integration tests


### Fixed

- Function with many returns (count = 8): self_referential_column?
- Set default permissions as read-only for workflow
- Update DiagramGenerator initialization to use keyword arguments and improve error messages in specs
- Improve logger debug message formatting in render_diagram method


## [1.1.3] - 2025-07-12
### Added

- Refactor TimelineDataService with modular enhancements and entry building utilities
- Implement timeline and tables views in DBWatcher

### Fixed

- Fix formatting in labels.yml for consistency in branch and path definitions


## [1.1.2] - 2025-07-09
### Added

- Add Slack notification to CI workflow and update README with maintainability and coverage badges
- Add SimpleCov for test coverage and update CI configuration for coverage uploads
- Add debug logging to SessionsController#show and implement to_param method in Session model; remove unused components and views
- Add Tabulator component styles and vendor overrides; enhance changes tab UI
- Enhance dashboard UI and add gem info section
- Refactor dashboard system info handling and add dedicated system info page
- Add system information collection and storage services


### Changed

- Refactor Slack notification step in CI workflow to use a custom payload format and remove unnecessary steps
- Update README images and configure SimpleCov with JSON formatter for test coverage
- Update screenshots.md
- Refactor tables index page: enhance filtering functionality, update tab structure, and improve UI elements
- Refactor session views and implement new tab structure
- Refactor session index page with filtering functionality and enhanced styling
- Update changesTableHybrid to use 'rowId' instead of 'id' for Tabulator row identifiers
- Refactor dashboard system info handling
- Refactor system information collection and storage
- Update README.md


## [1.1.1] - 2025-07-08
### Added

- Enhance Mermaid syntax handling for class names and add display name method
- Add GitHub Actions workflow for syncing labels


### Changed

- Update section headers and formatting in class diagram output
- Disable RuboCop Naming/PredicateMethod for remove_relationship and process methods
- Bump the production-dependencies group with 5 updates


### Fixed

- Improve error logging for eager loading engines and ensure newline at end of file in tests
- Correct description formatting for 'needs-triage' label in labels.yml
- Update GitHub Actions workflow to support master branch and improve label syncing


## [1.1.0] - 2025-07-04
### Added

- Add sassc gem for improved CSS processing
- Add code view functionality and styling for diagrams component
- Add unit tests and helper files for diagram services
- Add Mermaid syntax builders and cardinality mapping
- Enhance session display with improved ID formatting and add Tabulator CSS
- Enhance table and diagram styles for improved readability and usability
- Add DBWatcher styles and enhance timestamp formatting
- Enhance caching mechanism in BaseApiService and add .keep file for asset directory
- Add dbwatcher_manifest.js and configure asset paths in engine
- Implement DBWatcher component architecture with Alpine.js integration and optimized Mermaid service
- Streamline component configuration and improve layout
- Introduce Dbwatcher component helper methods for configuration generation
- Implement new changes and summary views with API support
- Add CODEOWNERS file and update dependabot.yml to remove reviewers
- Revise README for clarity and consistency, updating project description, features, and usage instructions
- Enhance Mermaid diagram rendering with responsive settings and improved loading logic
- Add show_legend option and update layout direction for flowchart diagrams
- Add methods to build ERD and flowchart diagrams from standardized datasets
- Add native SVG interactions and enhance Mermaid.js diagram functionality
- Add Mermaid.js integration and diagram rendering enhancements
- Add analyzers and services for session data processing and schema relationships
- Add detailed architecture diagrams for DBWatcher components and UI functionality
- Enhance table analysis by ensuring consistent column ordering in sample records and add comprehensive tests for mixed operations
- Add clear all functionality and enhance testing interface


### Changed

- Simplify button class generation and improve code readability
- Streamline relationship creation by introducing RelationshipParams class
- Enhance class diagram and ERD builders with formatting helpers
- Refactor and enhance diagram analyzers and configuration
- Revert "refactor: improve configuration initialization and method naming for clarity"
- Improve configuration initialization and method naming for clarity
- Implement Hybrid Tabulator for Changes Tab with Enhanced UI and Sticky Columns
- Update diagram content expectations to reflect has_many relationships for users
- Update diagram content expectations to reflect belongs_to relationships for comments
- Update diagram content expectations for user associations in tests
- Remove unused files from .gitignore for cleaner project structure
- Enhance readability and structure of diagram and summary services
- Update method names and improve logging for clarity and consistency
- Simplify DBWatcher setup by removing production environment check and unused query tracking configuration
- Refactor DBWatcher components for API-first architecture
- Remove redundant value labels for clarity in change display
- Remove date-fns.min.js and update to date-fns-browser; enhance Alpine.js initialization with improved error handling and plugin verification
- Consolidate asset serving initializer for clarity
- Improve layout and styling for diagram controls and states
- Refactor API endpoints and improve diagram handling
- Update diagram_type_options to use dynamic registry data
- Refactor Mermaid Syntax Builder and Session API
- Deps-dev(deps-dev): bump cucumber-html-formatter from 21.10.1 to 21.12.0
- Update README to include images for dashboard and session views
- Update screenshots.md
- Update readme
- Remove export diagram functionality and related UI elements
- Enhance diagram generation and session view functionality
- Enhance summary tab and table summary builder with operation filtering and improved logging
- Refactor session view to support tab navigation and modularize content
- Refactor table analyzer and specs for consistent symbol usage and improved error handling


### Fixed

- Fix failing specs by updating specs to match current implementation
- Prevent infinite redirect in error handling and correct stylesheet link tag
- Set track_queries to false for disabled SQL logging
- Fix comments table not showing in database tables diagram


### Build

- Implement diagram generation strategies and syntax builder


## [1.0.0] - 2025-06-16

### Added

- Refactor sessions index page and remove outdated components for improved clarity and maintainability
- Add new sessions index page and refactor shared components
- Enhance session and query management with improved clear functionality and file counting
- Implement clear functionality for sessions and queries, enhancing data management
- Refactor controllers to utilize service objects for improved data handling and separation of concerns feat: Introduce logging capabilities across services for better traceability feat: Implement dashboard data aggregation service for enhanced performance metrics feat: Add query filtering service to streamline query management feat: Create table statistics collector service for organized table data feat: Enhance session API with refined filtering methods for session retrieval refactor: Modularize helper methods into dedicated files for better maintainability
- Refactor storage system by introducing Base, SessionStorage, QueryStorage, and TableStorage classes
- Improve table layout and expand/collapse functionality in session view
- Enhance session and table views with improved navigation and data handling
- Add detailed table view for DB changes and enhance UI

### Changed

- Refactor stats icon generation to use dedicated methods for better maintainability and readability
- Refactor storage module: Enhance error handling, improve file management, and streamline session operations
- Refactor Dbwatcher storage system to improve API and data handling

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
