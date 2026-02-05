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
  add_group "Generators" do |src|
    src.filename.include?("lib/jojo/commands") && src.filename.end_with?("generator.rb")
  end
  add_group "Prompts" do |src|
    src.filename.include?("lib/jojo/commands") && src.filename.end_with?("prompt.rb")
  end
  add_group "Commands" do |src|
    src.filename.include?("lib/jojo/commands") &&
      !src.filename.end_with?("generator.rb") &&
      !src.filename.end_with?("prompt.rb")
  end
  add_group "Core" do |src|
    src.filename.include?("lib/jojo") && !src.filename.include?("lib/jojo/commands")
  end
end

require "dotenv/load"  # Load .env file for service tests
require "minitest/autorun"
require "minitest/spec"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "../lib/jojo"
require_relative "support/command_test_helper"
