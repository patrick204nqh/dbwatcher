# Dbwatcher

Track and visualize database changes in your Rails application for easier debugging.

## Installation

Add to your Gemfile:

```ruby
gem 'dbwatcher'
```

Then run:

```bash
bundle install
```

### Manual Route Mounting (if automatic mounting fails)

If you encounter route helper errors, manually mount the engine in your main Rails app's `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Dbwatcher::Engine => "/dbwatcher"
  # ... your other routes
end
```

## Usage

### Basic tracking:

```ruby
Dbwatcher.track(name: "User Registration") do
  user = User.create!(name: "John", email: "john@example.com")
  user.create_profile!(bio: "Developer")
end
```

### Automatic tracking via URL:

```
GET /users/123?dbwatch=true
```

### View tracked changes:

Visit `/dbwatcher` in your Rails app to see the UI.

### Configuration:

```ruby
# config/initializers/dbwatcher.rb
Dbwatcher.configure do |config|
  config.storage_path = Rails.root.join('tmp', 'dbwatcher')
  config.enabled = Rails.env.development?
  config.max_sessions = 100
  config.auto_clean_after_days = 7
end
```

## Troubleshooting

### Route Helper Errors

If you see errors like `undefined local variable or method 'dbwatcher_sessions_path'`, it means the engine routes aren't properly mounted. Try:

1. **Manual mounting**: Add this to your main app's `config/routes.rb`:

   ```ruby
   Rails.application.routes.draw do
     mount Dbwatcher::Engine => "/dbwatcher"
     # ... your other routes
   end
   ```

2. **Restart your Rails server** after adding the gem

3. **Check your Rails version** - this gem requires Rails 6.0+

### Missing ActiveSupport Error

If you see `NameError: uninitialized constant ActiveSupport`, make sure you're using this gem in a Rails application, not a plain Ruby script.

## Features

- Track all database changes (INSERT, UPDATE, DELETE)
- File-based storage (no database required)
- Simple UI with Alpine.js (no complex JavaScript build)
- Reset button to clear all sessions
- Automatic cleanup of old sessions
- Middleware for URL-based tracking

## License

MIT

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dbwatcher.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
