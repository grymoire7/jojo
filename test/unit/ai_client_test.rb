require_relative "../test_helper"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/config"
require "stringio"

class AIClientTest < JojoTest
  def setup
    super
    write_test_config(
      "reasoning_ai" => {"service" => "anthropic", "model" => "sonnet"},
      "text_generation_ai" => {"service" => "anthropic", "model" => "haiku"}
    )
    @config = Jojo::Config.new("config.yml")
  end

  def test_initializes_successfully_with_anthropic_provider
    File.write("config.yml", <<~YAML)
      seeker_name: Test User
      base_url: https://example.com
      reasoning_ai:
        service: anthropic
        model: claude-sonnet-4-5
      text_generation_ai:
        service: anthropic
        model: claude-3-5-haiku-20241022
    YAML

    original_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"

    config = Jojo::Config.new("config.yml")
    client = Jojo::AIClient.new(config)

    assert_instance_of Jojo::AIClient, client
    assert_equal config, client.config
  ensure
    ENV["ANTHROPIC_API_KEY"] = original_key
  end

  def test_initializes_successfully_with_openai_provider
    File.write("config.yml", <<~YAML)
      seeker_name: Test User
      base_url: https://example.com
      reasoning_ai:
        service: openai
        model: gpt-4o
      text_generation_ai:
        service: openai
        model: gpt-4o-mini
    YAML

    original_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-openai-key"

    config = Jojo::Config.new("config.yml")
    client = Jojo::AIClient.new(config)

    assert_instance_of Jojo::AIClient, client
    assert_equal config, client.config
  ensure
    ENV["OPENAI_API_KEY"] = original_key
  end

  def test_reason_calls_ai_with_reasoning_model
    client = Jojo::AIClient.new(@config)

    mock_response = Minitest::Mock.new
    mock_response.expect(:content, "AI reasoning response")

    mock_chat = Minitest::Mock.new
    mock_chat.expect(:ask, mock_response, ["Test prompt"])

    RubyLLM.stub :chat, ->(**kwargs) {
      assert_equal "claude-sonnet-4", kwargs[:model]
      mock_chat
    } do
      result = client.reason("Test prompt")
      assert_equal "AI reasoning response", result
    end

    mock_chat.verify
  end

  def test_generate_text_calls_ai_with_text_model
    client = Jojo::AIClient.new(@config)

    mock_response = Minitest::Mock.new
    mock_response.expect(:content, "Generated text")

    mock_chat = Minitest::Mock.new
    mock_chat.expect(:ask, mock_response, ["Generate something"])

    RubyLLM.stub :chat, ->(**kwargs) {
      assert_equal "claude-3-5-haiku-20241022", kwargs[:model]
      mock_chat
    } do
      result = client.generate_text("Generate something")
      assert_equal "Generated text", result
    end

    mock_chat.verify
  end

  def test_retries_on_failure_with_exponential_backoff
    client = Jojo::AIClient.new(@config)

    call_count = 0
    mock_response = Minitest::Mock.new
    mock_response.expect(:content, "Success after retries")

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) do |_prompt|
      call_count += 1
      raise "Temporary error" if call_count < 3
      mock_response
    end

    client.stub :sleep, nil do
      RubyLLM.stub :chat, ->(**_kwargs) { mock_chat } do
        result = client.reason("Test prompt")
        assert_equal "Success after retries", result
        assert_equal 3, call_count
      end
    end
  end

  def test_raises_ai_error_after_max_retries
    client = Jojo::AIClient.new(@config)

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) { |_prompt| raise "Persistent error" }

    client.stub :sleep, nil do
      RubyLLM.stub :chat, ->(**_kwargs) { mock_chat } do
        error = assert_raises(Jojo::AIClient::AIError) do
          client.reason("Test prompt", max_retries: 2)
        end

        assert_includes error.message, "failed after 2 retries"
        assert_includes error.message, "Persistent error"
      end
    end
  end

  def test_total_tokens_used_accumulates
    client = Jojo::AIClient.new(@config)

    assert_equal 0, client.total_tokens_used

    mock_response = Minitest::Mock.new
    mock_response.expect(:content, "Short response")

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) { |_prompt| mock_response }

    RubyLLM.stub :chat, ->(**_kwargs) { mock_chat } do
      client.reason("First prompt")
    end

    assert_operator client.total_tokens_used, :>, 0
    first_tokens = client.total_tokens_used

    mock_response2 = Minitest::Mock.new
    mock_response2.expect(:content, "Another response")

    mock_chat2 = Object.new
    mock_chat2.define_singleton_method(:ask) { |_prompt| mock_response2 }

    RubyLLM.stub :chat, ->(**_kwargs) { mock_chat2 } do
      client.reason("Second prompt")
    end

    assert_operator client.total_tokens_used, :>, first_tokens
  end

  def test_resolve_model_name_maps_shortnames
    assert_equal "claude-sonnet-4", Jojo::AIClient.resolve_model_name("sonnet")
    assert_equal "claude-3-5-haiku-20241022", Jojo::AIClient.resolve_model_name("haiku")
    assert_equal "claude-opus-4", Jojo::AIClient.resolve_model_name("opus")
  end

  def test_resolve_model_name_passes_through_unknown
    assert_equal "gpt-4o", Jojo::AIClient.resolve_model_name("gpt-4o")
    assert_equal "custom-model", Jojo::AIClient.resolve_model_name("custom-model")
  end

  def test_estimate_tokens_returns_rough_count
    prompt = "a" * 100
    response = "b" * 200
    tokens = Jojo::AIClient.estimate_tokens(prompt, response)

    assert_equal 75, tokens  # (100 + 200) / 4
  end

  def test_build_error_message_includes_suggestions
    error = StandardError.new("Connection refused")
    message = Jojo::AIClient.build_error_message("reasoning", error, 3)

    assert_includes message, "reasoning failed after 3 retries"
    assert_includes message, "Connection refused"
    assert_includes message, "Possible causes"
    assert_includes message, "Invalid API key"
    assert_includes message, "Network connection issues"
    assert_includes message, "Rate limiting"
  end

  def test_verbose_mode_outputs_messages
    client = Jojo::AIClient.new(@config, verbose: true)

    mock_response = Minitest::Mock.new
    mock_response.expect(:content, "Response")

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) { |_prompt| mock_response }

    output = StringIO.new
    $stdout = output

    RubyLLM.stub :chat, ->(**_kwargs) { mock_chat } do
      client.reason("Test")
    end
  ensure
    $stdout = STDOUT
    assert_includes output.string, "[AI]"
  end

  def test_non_verbose_mode_suppresses_output
    client = Jojo::AIClient.new(@config, verbose: false)

    mock_response = Minitest::Mock.new
    mock_response.expect(:content, "Response")

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) { |_prompt| mock_response }

    output = StringIO.new
    $stdout = output

    RubyLLM.stub :chat, ->(**_kwargs) { mock_chat } do
      client.reason("Test")
    end
  ensure
    $stdout = STDOUT
    refute_includes output.string, "[AI]"
  end
end
