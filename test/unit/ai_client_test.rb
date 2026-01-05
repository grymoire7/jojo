require_relative "../test_helper"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/config"

describe Jojo::AIClient do
  describe "#initialize" do
    it "initializes successfully with anthropic provider" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
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

          # Verify client initialized successfully
          _(client).must_be_instance_of Jojo::AIClient
          _(client.config).must_equal config
        ensure
          ENV["ANTHROPIC_API_KEY"] = original_key
        end
      end
    end

    it "initializes successfully with openai provider" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
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

          # Verify client initialized successfully
          _(client).must_be_instance_of Jojo::AIClient
          _(client.config).must_equal config
        ensure
          ENV["OPENAI_API_KEY"] = original_key
        end
      end
    end
  end
end
