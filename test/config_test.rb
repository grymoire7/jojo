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
end
