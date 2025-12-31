require_relative '../test_helper'
require_relative '../../lib/jojo/config'
require 'stringio'

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
      # Capture stderr to suppress error message during test
      original_stderr = $stderr
      $stderr = StringIO.new
      begin
        config = Jojo::Config.new('nonexistent.yml')
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
        config = Jojo::Config.new('test/fixtures/invalid_config.yml')
        config.reasoning_ai_model # trigger validation
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  it "returns base_url from config" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.base_url).must_equal "https://tracyatteberry.com"
  end

  it "validates base_url is present" do
    # Create config without base_url
    File.write('test/fixtures/no_base_url_config.yml', <<~YAML
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
        config = Jojo::Config.new('test/fixtures/no_base_url_config.yml')
        config.base_url
      ensure
        $stderr = original_stderr
      end
    }.must_raise SystemExit
  end

  describe '#search_service' do
    it 'returns search service from config' do
      config = Jojo::Config.new('test/fixtures/valid_config.yml')
      _(config.search_service).must_equal 'serper'
    end

    it 'returns nil when search not configured' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', <<~YAML)
            seeker_name: Test
            base_url: https://example.com
            reasoning_ai:
              service: anthropic
              model: sonnet
            text_generation_ai:
              service: anthropic
              model: haiku
          YAML

          config = Jojo::Config.new('config.yml')
          _(config.search_service).must_be_nil
        end
      end
    end
  end
end
