require 'yaml'

module Jojo
  class Config
    def initialize(config_path = 'config.yml')
      @config_path = config_path
      @config = nil
    end

    def seeker_name
      config['seeker_name']
    end

    def reasoning_ai_service
      validate_ai_config!('reasoning_ai')
      config['reasoning_ai']['service']
    end

    def reasoning_ai_model
      validate_ai_config!('reasoning_ai')
      config['reasoning_ai']['model']
    end

    def text_generation_ai_service
      validate_ai_config!('text_generation_ai')
      config['text_generation_ai']['service']
    end

    def text_generation_ai_model
      validate_ai_config!('text_generation_ai')
      config['text_generation_ai']['model']
    end

    def voice_and_tone
      config['voice_and_tone'] || 'professional and friendly'
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
      unless config[key] && config[key]['service'] && config[key]['model']
        abort "Error: Invalid AI configuration for #{key} in config.yml"
      end
    end
  end
end
