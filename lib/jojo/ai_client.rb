require "ruby_llm"

module Jojo
  class AIClient
    class AIError < StandardError; end

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
        task_type: "reasoning"
      )
    end

    # Use text generation model (Haiku) for simpler tasks
    def generate_text(prompt, max_retries: 3)
      call_ai(
        prompt: prompt,
        service: config.text_generation_ai_service,
        model: config.text_generation_ai_model,
        max_retries: max_retries,
        task_type: "text generation"
      )
    end

    def total_tokens_used
      @total_tokens
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |ruby_llm_config|
        # Dynamically configure all providers based on their configuration requirements
        RubyLLM.providers.each do |provider|
          # Get the configuration requirements for this provider
          config_requirements = provider.configuration_requirements

          # For each requirement, check if there's a corresponding ENV var
          config_requirements.each do |requirement|
            env_var_name = requirement.to_s.upcase
            env_value = ENV[env_var_name]

            # Set the configuration if the ENV var exists
            if env_value
              setter_method = "#{requirement}="
              ruby_llm_config.send(setter_method, env_value) if ruby_llm_config.respond_to?(setter_method)
            end
          end
        end
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
          sleep(2**retries) # Exponential backoff
          retry
        else
          raise AIError, build_error_message(task_type, e, max_retries)
        end
      end
    end

    def build_error_message(task_type, error, max_retries)
      base_message = "AI #{task_type} failed after #{max_retries} retries: #{error.message}"

      suggestions = [
        "\nPossible causes:",
        "- Invalid API key (check your ANTHROPIC_API_KEY environment variable)",
        "- Network connection issues",
        "- Rate limiting (try again in a few minutes)",
        "- Model unavailability or service outage"
      ]

      base_message + suggestions.join("\n")
    end

    def resolve_model_name(model_shortname)
      # Map config shortnames to full model IDs
      case model_shortname.to_s.downcase
      when "sonnet"
        "claude-sonnet-4"
      when "haiku"
        "claude-3-5-haiku-20241022"
      when "opus"
        "claude-opus-4"
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
