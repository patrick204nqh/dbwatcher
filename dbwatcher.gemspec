# frozen_string_literal: true

require_relative "lib/dbwatcher/version"

Gem::Specification.new do |spec|
  spec.name = "dbwatcher"
  spec.version = Dbwatcher::VERSION
  spec.authors = ["Huy Nguyen"]
  spec.email = ["patrick204nqh@gmail.com"]

  spec.summary = "A gem for tracking database changes in Ruby applications."
  spec.description = "DB Watcher is a Ruby gem that provides an easy way to track changes in your database schema and data. It helps you monitor and manage database changes effectively."
  spec.homepage = "https://github.com/patrick204nqh/dbwatcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/patrick204nqh/dbwatcher"
  spec.metadata["changelog_uri"] = "https://github.com/patrick204nqh/dbwatcher/blob/main/CHANGELOG.md"

  spec.summary = "Track and visualize database changes in Rails applications"
  spec.description = "DB Watcher helps developers debug Rails applications by tracking all database changes"
  spec.homepage = "https://github.com/patrick204nqh/db-watcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 6.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
