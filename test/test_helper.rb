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

require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("cassettes", __dir__)
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV["ANTHROPIC_API_KEY"] }
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }
  config.ignore_localhost = true
end

require_relative "../lib/jojo"

class JojoTest < Minitest::Test
  # Provide _() expectation wrapper (normally only available in Minitest::Spec)
  def _(value = nil, &block)
    Minitest::Expectation.new(block || value, self)
  end

  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def fixture_path(relative = "")
    if relative.empty?
      File.join(@original_dir, "test", "fixtures")
    else
      File.join(@original_dir, "test", "fixtures", relative)
    end
  end

  def copy_templates
    FileUtils.cp_r(File.join(@original_dir, "templates"), "templates")
  end

  def with_vcr(cassette_name, &block)
    VCR.use_cassette(cassette_name, &block)
  end

  def write_test_config(overrides = {})
    defaults = {
      "seeker_name" => "Test User",
      "base_url" => "https://example.com",
      "reasoning_ai" => {"service" => "openai", "model" => "gpt-4"},
      "text_generation_ai" => {"service" => "openai", "model" => "gpt-4"}
    }
    File.write("config.yml", defaults.merge(overrides).to_yaml)
  end

  def create_application_fixture(slug, files: {})
    FileUtils.mkdir_p("applications/#{slug}")
    files.each { |name, content| File.write("applications/#{slug}/#{name}", content) }
  end

  def create_inputs_fixture(files: {})
    FileUtils.mkdir_p("inputs")
    files.each { |name, content| File.write("inputs/#{name}", content) }
  end
end
