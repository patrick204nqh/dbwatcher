#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple Git hooks installer
# Usage:
#   ruby scripts/install-hooks.rb           # Install hooks
#   ruby scripts/install-hooks.rb uninstall # Remove hooks

require "fileutils"

class HookInstaller
  def self.run(args = ARGV)
    case args.first
    when "uninstall", "remove"
      new.uninstall
    when "install", nil
      new.install
    else
      puts "Usage: ruby scripts/install-hooks.rb [install|uninstall]"
    end
  end

  def install
    puts "🔧 Installing pre-commit hook..."

    unless git_repo?
      puts "❌ Not a Git repository"
      exit 1
    end

    create_hook
    puts "✅ Pre-commit hook installed!"
    puts "💡 The hook will run RuboCop and RSpec before each commit"
    puts "💡 To uninstall: ruby scripts/install-hooks.rb uninstall"
  end

  def uninstall
    puts "🗑️  Removing pre-commit hook..."

    hook_path = ".git/hooks/pre-commit"

    if File.exist?(hook_path)
      File.delete(hook_path)
      puts "✅ Pre-commit hook removed!"
    else
      puts "ℹ️  No pre-commit hook found"
    end
  end

  private

  def git_repo?
    File.directory?(".git")
  end

  def create_hook
    FileUtils.mkdir_p(".git/hooks")

    # Create symlink to our pre-commit script
    hook_path = ".git/hooks/pre-commit"
    script_path = "../../scripts/pre-commit"

    File.delete(hook_path) if File.exist?(hook_path)
    File.symlink(script_path, hook_path)
    File.chmod(0o755, hook_path)
  end
end

HookInstaller.run if $PROGRAM_NAME == __FILE__
