# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Unit tests
RSpec::Core::RakeTask.new(:unit) do |task|
  task.pattern = "spec/unit/**/*_spec.rb"
end

# Acceptance tests (Cucumber)
begin
  require "cucumber/rake/task"

  Cucumber::Rake::Task.new(:acceptance) do |task|
    task.cucumber_opts = ["spec/acceptance/features", "--require", "spec/acceptance"]
  end
rescue LoadError
  desc "Cucumber not available"
  task :acceptance do
    puts "Cucumber not available. Install cucumber-rails gem to run acceptance tests."
  end
end

# All tests
task spec: [:unit]
task test: %i[spec acceptance]

require "rubocop/rake_task"
RuboCop::RakeTask.new

# Default task
task default: %i[test rubocop]

# Setup tasks
desc "Set up test database and environment"
task :test_setup do
  Dir.chdir("spec/dummy") do
    system("bundle exec rails db:drop db:create db:migrate RAILS_ENV=test")
  end
end

desc "Start test server for manual testing"
task :test_server do
  Dir.chdir("spec/dummy") do
    ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", Dir.pwd)
    system("bundle exec rails server -e test -p 3001")
  end
end
