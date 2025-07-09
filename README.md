# DBWatcher

[![CI](https://github.com/patrick204nqh/dbwatcher/actions/workflows/ci.yml/badge.svg)](https://github.com/patrick204nqh/dbwatcher/actions/workflows/ci.yml)
[![Release Gem](https://github.com/patrick204nqh/dbwatcher/actions/workflows/release.yml/badge.svg)](https://github.com/patrick204nqh/dbwatcher/actions/workflows/release.yml)
[![Gem Version](https://badge.fury.io/rb/dbwatcher.svg)](https://badge.fury.io/rb/dbwatcher)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Rails gem that tracks and visualizes database operations in your application. Built for developers who need to understand complex data flows and debug database interactions.

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

Optional configuration in `config/initializers/dbwatcher.rb`:

```ruby
Dbwatcher.configure do |config|
  config.storage_path = Rails.root.join('tmp', 'dbwatcher')
  config.enabled = Rails.env.development?
  config.max_sessions = 100
  config.auto_clean_after_days = 7
end
```

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

### Testing Integration

Use in your test suite:

```ruby
it "creates user with associations" do
  Dbwatcher.track(name: "User Creation Test") do
    user = create(:user)
    expect(user.profile).to be_present
  end
end
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

### CI Coverage Setup

To enable coverage uploads to Qlty in CI:

1. Create an account at [Qlty.sh](https://qlty.sh)
2. Create a new project and get your coverage token
3. Add the token as a GitHub repository secret named `QLTY_COVERAGE_TOKEN`

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

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).
