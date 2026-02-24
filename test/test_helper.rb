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

# Ensure API keys are set so RubyLLM passes config validation
# before making HTTP requests that VCR can intercept
ENV["ANTHROPIC_API_KEY"] ||= "test-key-for-vcr"
ENV["OPENAI_API_KEY"] ||= "test-key-for-vcr"

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

# Stub Tailwind CSS builds by default in all tests to avoid the ~150ms CLI
# invocation in tests that don't need to verify CSS output. Call
# enable_tailwind_build(generator) in the rare test that does need it.
class Jojo::Commands::Website::Generator
  alias_method :build_tailwind_css_real, :build_tailwind_css
  private def build_tailwind_css
  end
end

class JojoTest < Minitest::Test
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
    require "find"
    src = File.join(@original_dir, "templates")
    dst = "templates"

    # Copy template files, skipping node_modules (21MB — symlinked below instead)
    Find.find(src) do |path|
      Find.prune if File.basename(path) == "node_modules" && File.directory?(path)
      rel = path[src.length + 1..]
      target = rel ? File.join(dst, rel) : dst
      if File.directory?(path)
        FileUtils.mkdir_p(target)
      else
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(path, target)
      end
    end

    # Symlink node_modules so Tailwind/DaisyUI bins resolve without copying 21MB per test
    nm_src = File.join(src, "website", "node_modules")
    nm_dst = File.join(dst, "website", "node_modules")
    FileUtils.ln_s(nm_src, nm_dst) if Dir.exist?(nm_src) && !File.exist?(nm_dst)
  end

  def enable_tailwind_build(generator)
    generator.define_singleton_method(:build_tailwind_css) { build_tailwind_css_real }
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
