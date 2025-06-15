# frozen_string_literal: true

require_relative "lib/dbwatcher/version"

Gem::Specification.new do |spec|
  spec.name = "dbwatcher"
  spec.version = Dbwatcher::VERSION
  spec.authors = ["Huy Nguyen"]
  spec.email = ["patrick204nqh@gmail.com"]

  spec.summary = "Track and visualize database changes in Rails applications"
  spec.description = "DB Watcher helps developers debug Rails applications by tracking all database changes"
  spec.homepage = "https://github.com/patrick204nqh/dbwatcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/patrick204nqh/dbwatcher"
  spec.metadata["changelog_uri"] = "https://github.com/patrick204nqh/dbwatcher/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://github.com/patrick204nqh/dbwatcher/blob/main/README.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/patrick204nqh/dbwatcher/issues"

  spec.files = Dir["{app,config,lib,bin}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.0"

  # Testing dependencies
  spec.add_development_dependency "capybara", "~> 3.0"
  spec.add_development_dependency "cucumber-rails", "~> 3.1"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "selenium-webdriver", "~> 4.0"
  spec.add_development_dependency "sprockets-rails", "~> 3.4"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "webrick", "~> 1.8"

  spec.metadata["rubygems_mfa_required"] = "true"
end
