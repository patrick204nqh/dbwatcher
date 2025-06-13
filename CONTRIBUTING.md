# Contributing to DBWatcher

We love your input! We want to make contributing to DBWatcher as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

### Pull Requests

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

### Development Setup

```bash
# Clone the repository
git clone https://github.com/patrick204nqh/dbwatcher.git
cd dbwatcher

# Install dependencies
bundle install

# Run the test suite
bundle exec rake test

# Run linting
bundle exec rubocop

# Start the dummy app for manual testing
cd spec/dummy
bundle exec rails server -p 3001
```

### Testing

DBWatcher includes comprehensive testing:

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test Rails integration and engine mounting
- **Feature Tests**: Browser-based testing with Cucumber and Capybara
- **Manual Testing**: Interactive dummy Rails application

```bash
# Run all tests
bundle exec rake test

# Run specific test types
bundle exec rake unit
bundle exec rake acceptance
bundle exec cucumber -p chrome

# Test the dummy application
cd spec/dummy
bundle exec rails server -p 3001
# Visit http://localhost:3001 and http://localhost:3001/dbwatcher
```

### Code Style

We use RuboCop to maintain consistent code style:

```bash
# Check for style issues
bundle exec rubocop

# Auto-fix issues where possible
bundle exec rubocop --autocorrect

# Check security issues
bundle exec brakeman
```

### Dummy Application

The `spec/dummy` directory contains a comprehensive Rails application for testing. This app includes:

- Multiple ActiveRecord models with complex relationships
- Controllers with various database operation patterns
- Test scenarios for edge cases and performance testing
- Interactive web interface for manual testing

When contributing, ensure your changes work with the dummy application.

### Architecture Guidelines

**Core Principles:**
- Keep the gem lightweight and dependency-free
- Focus on development/debugging use cases
- Maintain backward compatibility
- Follow Rails conventions and patterns

**File Organization:**
- `lib/dbwatcher/` - Core gem functionality
- `app/` - Rails engine views and controllers
- `spec/unit/` - Unit tests for individual components
- `spec/acceptance/` - Feature tests and browser automation
- `spec/dummy/` - Test Rails application

### Documentation

When contributing:

1. Update README.md for user-facing changes
2. Add inline documentation for complex methods
3. Update CHANGELOG.md following Keep a Changelog format
4. Include examples in documentation

### Reporting Bugs

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/patrick204nqh/dbwatcher/issues).

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

### Feature Requests

We welcome feature requests! Please:

1. Check existing issues to avoid duplicates
2. Describe the problem you're trying to solve
3. Explain why this feature would be useful
4. Consider how it fits with the project's goals

### License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

### Code of Conduct

This project adheres to a code of conduct. By participating, you're expected to uphold this code.

## Questions?

Feel free to open an issue with the "question" label or reach out to the maintainers.

Thank you for contributing to DBWatcher! 🎉
