require_relative 'test_helper'
require_relative '../lib/jojo/config'

describe Jojo::Config do
  it "loads seeker name" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.seeker_name).must_equal 'Test User'
  end

  it "loads reasoning AI config" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.reasoning_ai_service).must_equal 'anthropic'
    _(config.reasoning_ai_model).must_equal 'sonnet'
  end

  it "loads text generation AI config" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.text_generation_ai_service).must_equal 'anthropic'
    _(config.text_generation_ai_model).must_equal 'haiku'
  end

  it "loads voice and tone" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.voice_and_tone).must_equal 'professional and friendly'
  end

  it "loads search provider config" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.search_provider_service).must_equal 'serper'
    _(config.search_provider_api_key).must_equal 'test_api_key'
    _(config.search_provider_configured?).must_equal true
  end

  it "handles missing search provider config" do
    config = Jojo::Config.new('test/fixtures/invalid_config.yml')
    _(config.search_provider_service).must_be_nil
    _(config.search_provider_api_key).must_be_nil
    _(config.search_provider_configured?).must_equal false
  end

  it "aborts when config file is missing" do
    _ {
      config = Jojo::Config.new('nonexistent.yml')
      config.seeker_name # trigger lazy load
    }.must_raise SystemExit
  end

  it "aborts when AI config is invalid" do
    _ {
      config = Jojo::Config.new('test/fixtures/invalid_config.yml')
      config.reasoning_ai_model # trigger validation
    }.must_raise SystemExit
  end
end
