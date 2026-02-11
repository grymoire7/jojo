require_relative "../test_helper"
require_relative "../../lib/jojo/config"
require "stringio"

class ConfigTest < JojoTest
  def test_loads_seeker_name
    config = Jojo::Config.new(fixture_path("valid_config.yml"))
    _(config.seeker_name).must_equal "Test User"
  end

  def test_loads_reasoning_ai_config
    config = Jojo::Config.new(fixture_path("valid_config.yml"))
    _(config.reasoning_ai_service).must_equal "anthropic"
    _(config.reasoning_ai_model).must_equal "sonnet"
  end

  def test_loads_text_generation_ai_config
    config = Jojo::Config.new(fixture_path("valid_config.yml"))
    _(config.text_generation_ai_service).must_equal "anthropic"
    _(config.text_generation_ai_model).must_equal "haiku"
  end

  def test_loads_voice_and_tone
    config = Jojo::Config.new(fixture_path("valid_config.yml"))
    _(config.voice_and_tone).must_equal "professional and friendly"
  end

  def test_aborts_when_config_file_is_missing
    _ {
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

  def test_aborts_when_ai_config_is_invalid
    _ {
      original_stderr = $stderr
      $stderr = StringIO.new
      begin
        config = Jojo::Config.new(fixture_path("invalid_config.yml"))
        config.reasoning_ai_model # trigger validation
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  def test_returns_base_url_from_config
    config = Jojo::Config.new(fixture_path("valid_config.yml"))
    _(config.base_url).must_equal "https://tracyatteberry.com"
  end

  def test_validates_base_url_is_present
    File.write("no_base_url_config.yml", <<~YAML)
      seeker_name: Test User
      reasoning_ai:
        service: anthropic
        model: sonnet
    YAML

    _ {
      original_stderr = $stderr
      $stderr = StringIO.new
      begin
        config = Jojo::Config.new("no_base_url_config.yml")
        config.base_url
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  def test_returns_search_service_from_config
    config = Jojo::Config.new(fixture_path("valid_config.yml"))
    _(config.search_service).must_equal "serper"
  end

  def test_returns_nil_when_search_not_configured
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

  def test_returns_api_key_from_env_based_on_service_name
    File.write("config.yml", "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

    original_key = ENV["TAVILY_API_KEY"]
    ENV["TAVILY_API_KEY"] = "test-tavily-key"

    config = Jojo::Config.new("config.yml")
    _(config.search_api_key).must_equal "test-tavily-key"
  ensure
    ENV["TAVILY_API_KEY"] = original_key
  end

  def test_returns_nil_search_api_key_when_service_not_configured
    File.write("config.yml", "seeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

    config = Jojo::Config.new("config.yml")
    _(config.search_api_key).must_be_nil
  end

  def test_returns_nil_search_api_key_when_env_var_not_set
    File.write("config.yml", "search: serper\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

    original_value = ENV.delete("SERPER_API_KEY")

    config = Jojo::Config.new("config.yml")
    _(config.search_api_key).must_be_nil
  ensure
    ENV["SERPER_API_KEY"] = original_value if original_value
  end

  def test_search_configured_returns_true_when_service_and_api_key_both_present
    File.write("config.yml", "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

    original_key = ENV["TAVILY_API_KEY"]
    ENV["TAVILY_API_KEY"] = "test-key"

    config = Jojo::Config.new("config.yml")
    _(config.search_configured?).must_equal true
  ensure
    ENV["TAVILY_API_KEY"] = original_key
  end

  def test_search_configured_returns_false_when_service_missing
    File.write("config.yml", "seeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

    config = Jojo::Config.new("config.yml")
    _(config.search_configured?).must_equal false
  end

  def test_search_configured_returns_false_when_api_key_missing
    File.write("config.yml", "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

    original_key = ENV["TAVILY_API_KEY"]
    ENV.delete("TAVILY_API_KEY")

    config = Jojo::Config.new("config.yml")
    _(config.search_configured?).must_equal false
  ensure
    ENV["TAVILY_API_KEY"] = original_key
  end
end
