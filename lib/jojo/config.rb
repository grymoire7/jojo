require "yaml"

module Jojo
  class Config
    def initialize(config_path = "config.yml")
      @config_path = config_path
      @config = nil
    end

    def seeker_name
      config["seeker_name"]
    end

    def reasoning_ai_service
      validate_ai_config!("reasoning_ai")
      config["reasoning_ai"]["service"]
    end

    def reasoning_ai_model
      validate_ai_config!("reasoning_ai")
      config["reasoning_ai"]["model"]
    end

    def text_generation_ai_service
      validate_ai_config!("text_generation_ai")
      config["text_generation_ai"]["service"]
    end

    def text_generation_ai_model
      validate_ai_config!("text_generation_ai")
      config["text_generation_ai"]["model"]
    end

    def voice_and_tone
      config["voice_and_tone"] || "professional and friendly"
    end

    def base_url
      url = config["base_url"]
      if url.nil? || url.strip.empty?
        abort "Error: base_url is required in config.yml"
      end
      url
    end

    def search_service
      config["search"]
    end

    def search_api_key
      return nil unless search_service

      # Map service name to env var name
      # tavily → TAVILY_API_KEY, serper → SERPER_API_KEY
      env_var_name = "#{search_service.upcase}_API_KEY"
      ENV[env_var_name]
    end

    def search_configured?
      !search_service.nil? && !search_api_key.nil?
    end

    def website_cta_text
      config.dig("website", "cta_text") || "Get in Touch"
    end

    def website_cta_link
      config.dig("website", "cta_link")
    end

    def resume_template
      config["resume_template"]
    end

    def to_h
      config
    end

    private

    def config
      @config ||= load_config
    end

    def load_config
      unless File.exist?(@config_path)
        abort "Error: #{@config_path} not found. Run 'jojo setup' first."
      end

      YAML.load_file(@config_path)
    rescue => e
      abort "Error loading config: #{e.message}"
    end

    def validate_ai_config!(key)
      unless config[key] && config[key]["service"] && config[key]["model"]
        abort "Error: Invalid AI configuration for #{key} in config.yml"
      end
    end
  end
end
