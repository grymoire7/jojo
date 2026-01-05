require_relative "../test_helper"
require_relative "../../lib/jojo/config"
require "stringio"

describe Jojo::Config do
  it "loads seeker name" do
    config = Jojo::Config.new("test/fixtures/valid_config.yml")
    _(config.seeker_name).must_equal "Test User"
  end

  it "loads reasoning AI config" do
    config = Jojo::Config.new("test/fixtures/valid_config.yml")
    _(config.reasoning_ai_service).must_equal "anthropic"
    _(config.reasoning_ai_model).must_equal "sonnet"
  end

  it "loads text generation AI config" do
    config = Jojo::Config.new("test/fixtures/valid_config.yml")
    _(config.text_generation_ai_service).must_equal "anthropic"
    _(config.text_generation_ai_model).must_equal "haiku"
  end

  it "loads voice and tone" do
    config = Jojo::Config.new("test/fixtures/valid_config.yml")
    _(config.voice_and_tone).must_equal "professional and friendly"
  end

  it "aborts when config file is missing" do
    _ {
      # Capture stderr to suppress error message during test
      original_stderr = $stderr
      $stderr = StringIO.new
      begin
        config = Jojo::Config.new("nonexistent.yml")
        config.seeker_name # trigger lazy load
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  it "aborts when AI config is invalid" do
    _ {
      # Capture stderr to suppress error message during test
      original_stderr = $stderr
      $stderr = StringIO.new
      begin
        config = Jojo::Config.new("test/fixtures/invalid_config.yml")
        config.reasoning_ai_model # trigger validation
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  it "returns base_url from config" do
    config = Jojo::Config.new("test/fixtures/valid_config.yml")
    _(config.base_url).must_equal "https://tracyatteberry.com"
  end

  it "validates base_url is present" do
    # Create config without base_url
    File.write("test/fixtures/no_base_url_config.yml", <<~YAML
      seeker_name: Test User
      reasoning_ai:
        service: anthropic
        model: sonnet
    YAML
    )

    _ {
      # Capture stderr to suppress error message during test
      original_stderr = $stderr
      $stderr = StringIO.new
      begin
        config = Jojo::Config.new("test/fixtures/no_base_url_config.yml")
        config.base_url
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  describe "#search_service" do
    it "returns search service from config" do
      config = Jojo::Config.new("test/fixtures/valid_config.yml")
      _(config.search_service).must_equal "serper"
    end

    it "returns nil when search not configured" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", <<~YAML)
            seeker_name: Test
            base_url: https://example.com
            reasoning_ai:
              service: anthropic
              model: sonnet
            text_generation_ai:
              service: anthropic
              model: haiku
          YAML

          config = Jojo::Config.new("config.yml")
          _(config.search_service).must_be_nil
        end
      end
    end
  end

  describe "#search_api_key" do
    it "returns API key from ENV based on service name" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          original_key = ENV["TAVILY_API_KEY"]
          ENV["TAVILY_API_KEY"] = "test-tavily-key"

          config = Jojo::Config.new("config.yml")
          _(config.search_api_key).must_equal "test-tavily-key"
        ensure
          ENV["TAVILY_API_KEY"] = original_key
        end
      end
    end

    it "returns nil when service not configured" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "seeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          config = Jojo::Config.new("config.yml")
          _(config.search_api_key).must_be_nil
        end
      end
    end

    it "returns nil when ENV var not set" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "search: serper\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          # Ensure env var is not set
          original_value = ENV.delete("SERPER_API_KEY")

          config = Jojo::Config.new("config.yml")
          _(config.search_api_key).must_be_nil
        ensure
          ENV["SERPER_API_KEY"] = original_value if original_value
        end
      end
    end
  end

  describe "#search_configured?" do
    it "returns true when service and API key both present" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          original_key = ENV["TAVILY_API_KEY"]
          ENV["TAVILY_API_KEY"] = "test-key"

          config = Jojo::Config.new("config.yml")
          _(config.search_configured?).must_equal true
        ensure
          ENV["TAVILY_API_KEY"] = original_key
        end
      end
    end

    it "returns false when service missing" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "seeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          config = Jojo::Config.new("config.yml")
          _(config.search_configured?).must_equal false
        end
      end
    end

    it "returns false when API key missing" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          original_key = ENV["TAVILY_API_KEY"]
          ENV.delete("TAVILY_API_KEY")

          config = Jojo::Config.new("config.yml")
          _(config.search_configured?).must_equal false
        ensure
          ENV["TAVILY_API_KEY"] = original_key
        end
      end
    end
  end
end
