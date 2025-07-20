<div align="center">
  <img src="https://raw.githubusercontent.com/patrick204nqh/dbwatcher/master/app/assets/images/dbwatcher/dbwatcher_512x512.png" alt="dbwatcher Logo" width="120" height="120">

# dbwatcher
##### 🔍 Track, visualize, and debug database operations in your Rails applications

</div>

[![CI](https://github.com/patrick204nqh/dbwatcher/actions/workflows/ci.yml/badge.svg)](https://github.com/patrick204nqh/dbwatcher/actions/workflows/ci.yml)
[![Release Gem](https://github.com/patrick204nqh/dbwatcher/actions/workflows/release.yml/badge.svg)](https://github.com/patrick204nqh/dbwatcher/actions/workflows/release.yml)
[![Gem Version](https://badge.fury.io/rb/dbwatcher.svg)](https://badge.fury.io/rb/dbwatcher)
[![RubyGems Downloads](https://img.shields.io/gem/dt/dbwatcher?color=blue)](https://rubygems.org/gems/dbwatcher)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintainability](https://qlty.sh/gh/patrick204nqh/projects/dbwatcher/maintainability.svg)](https://qlty.sh/gh/patrick204nqh/projects/dbwatcher)
[![Code Coverage](https://qlty.sh/gh/patrick204nqh/projects/dbwatcher/coverage.svg)](https://qlty.sh/gh/patrick204nqh/projects/dbwatcher)

A Rails gem that tracks and visualizes database operations in your application. Built for developers who need to understand complex data flows and debug database interactions.

## Why dbwatcher?

When developing Rails applications, understanding what database operations occur during code execution can be challenging. **dbwatcher** provides a simple way to:

- Track database changes within specific code blocks
- Monitor SQL operations during HTTP requests
- Visualize database relationships and model associations
- Debug complex data flows with an intuitive web interface

## Key Features

- **Database Operation Tracking** - Capture SQL operations (INSERT, UPDATE, DELETE)
- **Targeted Monitoring** - Track specific code blocks or entire HTTP requests
- **Interactive Dashboard** - Clean web interface for exploring captured data
- **Relationship Diagrams** - Visualize database relationships and model associations
- **Simple Setup** - File-based storage with zero additional database requirements
- **Development Ready** - Designed specifically for development environments

## Screenshots

### Dashboard Interface

![image](https://github.com/user-attachments/assets/92c94bdc-06fd-463e-a11f-f931a8ff5346)

### Session View

![image](https://github.com/user-attachments/assets/cae4c820-d7d9-4d16-b8fa-5978e0578ff8)

[View more screenshots in here →](docs/screenshots.md)

## Installation

Add to your Gemfile:

```ruby
gem 'dbwatcher', group: :development
```

Install the gem:

```bash
bundle install
```

The dashboard automatically becomes available at `/dbwatcher` in your Rails application.

## Usage

### Track Code Blocks

Monitor specific operations:

```ruby
Dbwatcher.track(name: "User Registration") do
  user = User.create!(name: "John", email: "john@example.com")
  user.create_profile!(bio: "Developer")
  user.posts.create!(title: "Hello World")
end
```

### Track HTTP Requests

Add `?dbwatch=true` to any URL:

```
GET /users/123?dbwatch=true
POST /api/users?dbwatch=true
```

### View Results

Visit `/dbwatcher` in your browser to explore tracked operations.

## Configuration

**dbwatcher** works out of the box with zero configuration - simply install the gem and visit `/dbwatcher` in your Rails application.

### Configuration Options

<details>
<summary>View All Configuration Settings</summary>

| Setting                       | Type    | Default           | Description                                         |
| ----------------------------- | ------- | ----------------- | --------------------------------------------------- |
| **Core Settings**             |
| `enabled`                     | Boolean | `true`            | Enable or disable DBWatcher                         |
| `storage_path`                | String  | `"tmp/dbwatcher"` | Directory for session data storage                  |
| **Session Management**        |
| `max_sessions`                | Integer | `50`              | Maximum number of sessions to retain                |
| `auto_clean_days`             | Integer | `7`               | Automatically delete sessions older than N days     |
| **Query Tracking**            |
| `track_queries`               | Boolean | `false`           | Enable full SQL query tracking (resource intensive) |
| **System Information**        |
| `system_info`                 | Boolean | `true`            | Collect system information for debugging            |
| `debug_mode`                  | Boolean | `false`           | Enable detailed debug logging                       |
| **Database Diagram Options**  |
| `diagram_show_attributes`     | Boolean | `true`            | Display model attributes in diagrams                |
| `diagram_show_cardinality`    | Boolean | `true`            | Show relationship cardinality indicators            |
| `diagram_show_methods`        | Boolean | `false`           | Include model methods in diagrams                   |
| `diagram_max_attributes`      | Integer | `10`              | Maximum attributes displayed per model              |
| `diagram_attribute_types`     | Boolean | `true`            | Show data types for attributes                      |
| `diagram_relationship_labels` | Boolean | `true`            | Display labels on relationship lines                |

### Configuration Example

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.dbwatcher.enabled = true
  config.dbwatcher.max_sessions = 100
  config.dbwatcher.track_queries = true
end
```

</details>

## Advanced Features

### Custom Metadata

Add context to your tracking:

```ruby
Dbwatcher.track(
  name: "Order Processing",
  metadata: { user_id: current_user.id, order_type: "premium" }
) do
  # Database operations here
end
```

### Access Current Session

Access the current tracking session:

```ruby
session = Dbwatcher.current_session
puts "Session ID: #{session.id}"
puts "Total changes: #{session.changes.count}"
```

### Clear All Data

Remove all stored sessions and queries:

```ruby
Dbwatcher.clear_all
```

## Development

### Running Tests

```bash
bundle exec rake test        # All tests
bundle exec rake unit        # Unit tests only
bundle exec rake acceptance  # Feature tests only
```

### Code Coverage

The project uses SimpleCov for code coverage and uploads results to Qlty. To run tests with coverage locally:

```bash
COVERAGE=true bundle exec rake test
```

Coverage reports will be generated in the `coverage/` directory.

### Local Development

```bash
cd spec/dummy
bundle exec rails server -p 3001
open http://localhost:3001/dbwatcher
```

### Code Quality

```bash
bundle exec rubocop    # Linting
bundle exec brakeman   # Security analysis
```

[Changelog →](CHANGELOG.md)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b my-feature`
3. Make changes and add tests
4. Run tests: `bundle exec rake test`
5. Run linter: `bundle exec rubocop`
6. Commit changes: `git commit -am 'Add feature'`
7. Push branch: `git push origin my-feature`
8. Open a Pull Request

[Contributing guidelines →](CONTRIBUTING.md)

## Resources

- [Documentation](https://rubydoc.info/gems/dbwatcher)
- [Changelog](CHANGELOG.md)
- [Report Bug](https://github.com/patrick204nqh/dbwatcher/issues/new)
- [Request Feature](https://github.com/patrick204nqh/dbwatcher/issues/new)

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).
