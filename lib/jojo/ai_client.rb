require 'ruby_llm'

module Jojo
  class AIClient
    attr_reader :config, :verbose

    def initialize(config, verbose: false)
      @config = config
      @verbose = verbose
      @total_tokens = 0
      configure_ruby_llm
    end

    # Use reasoning model (Sonnet) for complex tasks
    def reason(prompt, max_retries: 3)
      call_ai(
        prompt: prompt,
        service: config.reasoning_ai_service,
        model: config.reasoning_ai_model,
        max_retries: max_retries,
        task_type: 'reasoning'
      )
    end

    # Use text generation model (Haiku) for simpler tasks
    def generate_text(prompt, max_retries: 3)
      call_ai(
        prompt: prompt,
        service: config.text_generation_ai_service,
        model: config.text_generation_ai_model,
        max_retries: max_retries,
        task_type: 'text generation'
      )
    end

    def total_tokens_used
      @total_tokens
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      end
    end

    def call_ai(prompt:, service:, model:, max_retries:, task_type:)
      retries = 0

      begin
        log_verbose "Starting #{task_type} with #{model}..."

        # Create a chat with the specified model
        chat = RubyLLM.chat(model: resolve_model_name(model))

        # Send the prompt and get response
        response = chat.ask(prompt)

        # Extract text content
        response_text = response.content

        tokens = estimate_tokens(prompt, response_text)
        @total_tokens += tokens

        log_verbose "#{task_type.capitalize} complete. Estimated tokens: #{tokens}"

        response_text
      rescue => e
        retries += 1
        if retries <= max_retries
          log_verbose "Error during #{task_type}, retrying (#{retries}/#{max_retries}): #{e.message}"
          sleep(2 ** retries) # Exponential backoff
          retry
        else
          raise "AI #{task_type} failed after #{max_retries} retries: #{e.message}"
        end
      end
    end

    def resolve_model_name(model_shortname)
      # Map config shortnames to full model IDs
      case model_shortname.to_s.downcase
      when 'sonnet'
        'claude-sonnet-4'
      when 'haiku'
        'claude-3-5-haiku-20241022'
      when 'opus'
        'claude-opus-4'
      else
        model_shortname # Return as-is if not a known shortname
      end
    end

    def estimate_tokens(prompt, response)
      # Rough estimation: 1 token ≈ 4 characters
      # This is approximate; real token counting would require the tokenizer
      (prompt.length + response.length) / 4
    end

    def log_verbose(message)
      puts "  [AI] #{message}" if verbose
    end
  end
end
