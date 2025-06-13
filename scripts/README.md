# Scripts

Simple utility scripts for ClassMetrix development.

## 🔧 Git Hooks

### Quick Setup
```bash
# Install pre-commit hook
ruby scripts/install-hooks.rb

# Remove pre-commit hook
ruby scripts/install-hooks.rb uninstall
```

### What the pre-commit hook does
When you try to commit Ruby files, it automatically runs enabled checks:
1. **RuboCop** ✅ - Checks code style
2. **RSpec** ✅ - Runs your tests  
3. **Brakeman** ✅ - Security vulnerability scan
4. **RBS** ❌ - Type validation (disabled for speed)
5. **Steep** ❌ - Type checking (disabled for speed)

If any enabled check fails, the commit is blocked until you fix the issues.

## 📁 Files

- **`install-hooks.rb`** - Install/uninstall the pre-commit hook
- **`pre-commit`** - The actual hook script with hash-based configuration

## 🎛️ Easy Configuration

To enable/disable checks, just edit the `CHECKS` hash in `scripts/pre-commit`:

```ruby
CHECKS = {
  rubocop: {
    enabled: true,    # ✅ Always run
    # ... other config
  },
  rspec: {
    enabled: true,    # ✅ Always run
    # ... other config
  },
  brakeman: {
    enabled: true,    # ✅ Security scan
    # ... other config
  },
  rbs: {
    enabled: false,   # ❌ Disabled for speed
    # ... other config
  },
  steep: {
    enabled: false,   # ❌ Disabled for speed
    # ... other config
  }
}
```

### Enable type checking:
```ruby
rbs: { enabled: true, ... },
steep: { enabled: true, ... }
```

### Disable security scanning:
```ruby
brakeman: { enabled: false, ... }
```

## 🚀 Usage

### Normal workflow:
```bash
# Make your changes
git add .
git commit -m "your message"

# The hook automatically runs enabled checks
# If any fail, you'll see clear instructions on how to fix them
```

### Skip hooks in emergencies:
```bash
git commit --no-verify -m "emergency fix"
```

## ✨ Benefits

- **Hash-based config** - Super easy to enable/disable checks
- **Clear feedback** - Each check shows helpful fix commands
- **Extensible** - Easy to add new checks to the hash
- **Fast by default** - Type checking disabled for quick commits
- **Comprehensive** - Covers style, tests, and security

That's it! Simple, configurable, and powerful. 🎉