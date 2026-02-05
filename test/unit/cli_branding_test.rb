require_relative "../test_helper"
require_relative "../../lib/jojo/cli"

describe "jojo branding command" do
  it "has branding command" do
    _(Jojo::CLI.commands.key?("branding")).must_equal true
  end

  it "fails when application does not exist" do
    app = Jojo::Application.new("test-branding-nonexistent")
    FileUtils.rm_rf(app.base_path) if Dir.exist?(app.base_path)

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
