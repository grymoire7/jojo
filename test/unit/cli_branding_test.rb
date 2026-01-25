require_relative "../test_helper"
require_relative "../../lib/jojo/cli"

describe "jojo branding command" do
  it "has branding command" do
    _(Jojo::CLI.commands.key?("branding")).must_equal true
  end

  it "fails when employer does not exist" do
    employer = Jojo::Employer.new("test-branding-nonexistent")
    FileUtils.rm_rf(employer.base_path) if Dir.exist?(employer.base_path)

    # Use Open3 to capture output and status properly
    require "open3"
    stdout, stderr, status = Open3.capture3(
      "bundle exec ruby -Ilib -e \"require 'jojo'; Jojo::CLI.start(['branding', '-s', 'test-branding-nonexistent'])\""
    )
    output = stdout + stderr

    _(status.success?).must_equal false
    _(output).must_include "not found"
  end
end
