require "simplecov"
require "simplecov_json_formatter"

SimpleCov.start do
  # Output formats
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

  # Track only lib/ code
  track_files "lib/**/*.rb"

  # Standard exclusions
  add_filter "/test/"
  add_filter "/bin/"
  add_filter "/vendor/"

  # Group by component for easier analysis
  add_group "Commands", "lib/jojo/commands"
  add_group "Generators", "lib/jojo/generators"
  add_group "Prompts", "lib/jojo/prompts"
  add_group "Core", "lib/jojo"
end

require "dotenv/load"  # Load .env file for service tests
require "minitest/autorun"
require "minitest/spec"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "../lib/jojo"
require_relative "support/command_test_helper"
