# DB Watcher 🔍

Track and visualize database changes in your Rails application for easier debugging and development.

DB Watcher is a powerful Rails gem that captures, stores, and visualizes all database operations in your application. Perfect for debugging complex data flows, understanding application behavior, and optimizing database performance.

## ✨ Features

- **📊 Real-time Database Tracking**: Monitor all SQL operations (INSERT, UPDATE, DELETE, SELECT)
- **🎯 Selective Tracking**: Track specific code blocks or entire requests
- **📱 Web Dashboard**: Beautiful, responsive interface built with Alpine.js and Tailwind CSS
- **💾 File-based Storage**: No additional database setup required
- **🔗 URL-based Activation**: Simple `?dbwatch=true` parameter enables tracking
- **🧹 Automatic Cleanup**: Configurable session cleanup and storage management
- **⚡ Zero Dependencies**: Works with any Rails application without complex setup
- **🔒 Development-focused**: Designed for development and testing environments

## 🚀 Installation

Add to your Gemfile:

```ruby
gem 'dbwatcher', group: :development
```

Then run:

```bash
bundle install
```

The engine will automatically mount at `/dbwatcher` in your Rails application.

### Manual Route Mounting (Optional)

If you need custom mounting, add to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Dbwatcher::Engine => "/dbwatcher" if Rails.env.development?
  # ... your other routes
end
```

## 📖 Usage

### 🎯 Targeted Tracking

Track specific code blocks with detailed context:

```ruby
Dbwatcher.track(name: "User Registration Flow") do
  user = User.create!(
    name: "John Doe", 
    email: "john@example.com"
  )
  
  user.create_profile!(
    bio: "Software Developer",
    location: "San Francisco"
  )
  
  user.posts.create!(
    title: "Welcome Post",
    content: "Hello World!"
  )
end
```

### 🌐 URL-based Tracking

Enable tracking for any request by adding `?dbwatch=true`:

```
# Track a user show page
GET /users/123?dbwatch=true

# Track a form submission
POST /users?dbwatch=true

# Track API endpoints
GET /api/posts?dbwatch=true
```

### 📊 View Tracking Results

Visit `/dbwatcher` in your Rails application to access the dashboard where you can:
- Browse all tracking sessions
- View detailed SQL queries and timing
- Analyze database operation patterns
- Monitor application performance

## ⚙️ Configuration

Create an initializer for custom configuration:

```ruby
# config/initializers/dbwatcher.rb
Dbwatcher.configure do |config|
  # Storage location for tracking data
  config.storage_path = Rails.root.join('tmp', 'dbwatcher')
  
  # Enable/disable tracking (default: development only)
  config.enabled = Rails.env.development?
  
  # Maximum number of sessions to keep
  config.max_sessions = 100
  
  # Automatic cleanup after N days
  config.auto_clean_after_days = 7
  
  # Include query parameters in tracking
  config.include_params = true
  
  # Exclude certain SQL patterns
  config.excluded_patterns = [
    /SHOW TABLES/,
    /DESCRIBE/
  ]
end
```

## 🏗️ Development & Testing

This project includes a comprehensive dummy Rails application for testing and development.

### Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test suites
bundle exec rake unit          # Unit tests
bundle exec rake acceptance    # Feature tests
bundle exec cucumber -p chrome # Browser tests
```

### Development Server

```bash
# Start the dummy application
cd spec/dummy
bundle exec rails server -p 3001

# Visit the test interface
open http://localhost:3001

# Visit DBWatcher dashboard
open http://localhost:3001/dbwatcher
```

### Code Quality

```bash
# Run linter
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop --autocorrect

# Security analysis
bundle exec brakeman
```

## 🛠️ Troubleshooting

### Route Helper Errors

If you encounter `undefined method 'dbwatcher_sessions_path'`:

1. **Restart your Rails server** after installing the gem
2. **Check Rails version** - requires Rails 6.0+
3. **Manual mounting** - add the mount line to your routes file

### Performance Considerations

- DBWatcher is designed for development environments
- Disable in production using `config.enabled = false`
- Use targeted tracking for performance-sensitive operations
- Regular cleanup prevents storage bloat

### Storage Location

- Default: `Rails.root/tmp/dbwatcher/`
- Files are JSON formatted for easy inspection
- Sessions auto-expire based on configuration

## 🔧 Advanced Usage

### Custom Metadata

Add context to your tracking sessions:

```ruby
Dbwatcher.track(
  name: "Complex Business Logic",
  metadata: {
    user_id: current_user.id,
    feature_flag: "new_checkout",
    version: "2.1.0"
  }
) do
  # Your database operations
end
```

### Conditional Tracking

```ruby
Dbwatcher.track(name: "Admin Operations") do
  # This will only track if DBWatcher is enabled
  User.where(admin: true).update_all(last_seen: Time.current)
end if Dbwatcher.enabled?
```

### Integration with Testing

```ruby
# In your test suite
RSpec.describe "User Registration" do
  it "creates user with proper associations" do
    session_data = nil
    
    Dbwatcher.track(name: "Test User Creation") do
      user = create(:user)
      expect(user.profile).to be_present
    end
    
    # Analyze the tracked operations
    expect(Dbwatcher::Storage.last_session).to include_sql(/INSERT INTO users/)
  end
end
```

## 📁 Project Structure

```
dbwatcher/
├── app/
│   ├── controllers/dbwatcher/    # Web interface controllers
│   └── views/dbwatcher/          # Dashboard templates
├── config/
│   └── routes.rb                 # Engine routes
├── lib/dbwatcher/
│   ├── configuration.rb         # Configuration management
│   ├── engine.rb                # Rails engine
│   ├── middleware.rb            # Rack middleware
│   ├── storage.rb               # File-based storage
│   └── tracker.rb               # Core tracking logic
└── spec/
    ├── dummy/                    # Test Rails application
    ├── acceptance/               # Feature tests
    └── unit/                     # Unit tests
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `bundle exec rake test`
5. Run the linter: `bundle exec rubocop`
6. Commit your changes: `git commit -am 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

## 📝 License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🙏 Acknowledgments

- Built with Rails Engine architecture
- UI powered by Alpine.js and Tailwind CSS
- Inspired by debugging needs in complex Rails applications

---

**Happy Debugging!** 🐛✨
