# DBWatcher Dummy Rails Application

This is a comprehensive dummy Rails application designed for testing the [DBWatcher gem](../../README.md). It provides a realistic testing environment with multiple models, relationships, and complex database operations to thoroughly exercise DBWatcher's database tracking capabilities.

## Purpose

This dummy app serves as:
- **Testing Environment**: Comprehensive test suite for DBWatcher functionality
- **Development Playground**: Interactive environment for testing database operations
- **Demo Application**: Showcase of DBWatcher capabilities
- **Integration Testing**: Real-world scenarios with complex ActiveRecord operations

## Features

### Models & Relationships
- **Users**: Core user management with profiles, roles, and activity tracking
- **Posts**: Content management with tags, comments, and publishing workflow
- **Comments**: Threaded comments with approval system
- **Tags**: Content categorization system
- **Roles**: User permission management
- **Profiles**: Extended user information

### Database Operations
The app includes comprehensive testing controllers for:
- Complex transactions with multiple models
- Bulk operations (insert, update, delete)
- Cascade delete operations
- Nested attribute creation
- Concurrent update simulations
- Error handling scenarios
- Mass data updates

### Key Files
- `app/controllers/testing/testing_controller.rb` - Advanced database operation testing
- `app/controllers/users_controller.rb` - User management with bulk operations
- `app/controllers/posts_controller.rb` - Content management
- `config/routes.rb` - Comprehensive routing for testing scenarios
- `db/seeds.rb` - Sample data generation

## Getting Started

### Prerequisites
- Ruby 3.1+
- Rails 7.2+
- SQLite3 (for development/testing)

### Setup
```bash
# Install dependencies
bundle install

# Setup database
rails db:setup

# Start the server
rails server -p 3001
```

### Running Tests
```bash
# Run all tests
bundle exec rake test

# Run specific test suites
bundle exec rake unit          # Unit tests only
bundle exec rake acceptance    # Acceptance tests only
bundle exec cucumber -p chrome # Browser tests
```

## Testing DBWatcher

### Manual Testing
1. Start the dummy app: `rails server -p 3001`
2. Visit `http://localhost:3001` for the main interface
3. Visit `http://localhost:3001/dbwatcher` for DBWatcher dashboard
4. Use the testing buttons to trigger various database operations
5. Monitor the DBWatcher interface for tracking results

### Automated Testing
The app includes comprehensive test suites:
- **Unit Tests**: Model and library testing
- **Integration Tests**: Controller and routing testing
- **Feature Tests**: Full browser automation with Cucumber
- **Performance Tests**: Database operation benchmarking

### Testing Routes
Key testing endpoints (append `?dbwatch=true` to enable tracking):
- `/testing/complex_transaction` - Multi-model transactions
- `/testing/bulk_operations` - Bulk database operations
- `/testing/cascade_deletes` - Relationship cascade testing
- `/testing/nested_operations` - Complex nested operations
- `/testing/concurrent_updates` - Race condition simulation

## Development

### Code Quality
The codebase follows Ruby/Rails best practices:
- RuboCop compliance for style consistency
- Comprehensive test coverage
- Clear separation of concerns
- Descriptive naming conventions

### Database Schema
See `db/schema.rb` for the complete database structure. The schema includes:
- Comprehensive relationships (1:1, 1:many, many:many)
- Proper indexing for performance
- Validation constraints
- Audit fields (created_at, updated_at)

### Configuration
- Development: SQLite3 database
- Test: Isolated SQLite3 database
- Production: Configurable (intended for testing only)

## Contributing

This dummy app is part of the DBWatcher gem testing infrastructure. When contributing:

1. Maintain test coverage for new features
2. Follow existing code style and patterns
3. Update this README for significant changes
4. Test with both unit and integration test suites

## Architecture

### MVC Structure
- **Models**: ActiveRecord models with proper validations and relationships
- **Views**: ERB templates with responsive design (Tailwind CSS)
- **Controllers**: RESTful controllers with comprehensive testing actions

### Testing Philosophy
- **Realistic Scenarios**: Real-world database operations
- **Edge Cases**: Error conditions and boundary testing
- **Performance**: Bulk operations and optimization testing
- **Reliability**: Transaction handling and data integrity

## License

This dummy application is part of the DBWatcher gem and shares the same license. See the main project LICENSE for details.
