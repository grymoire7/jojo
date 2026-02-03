require "dotenv/load"  # Load .env file for service tests
require "minitest/autorun"
require "minitest/spec"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "../lib/jojo"
require_relative "support/command_test_helper"
