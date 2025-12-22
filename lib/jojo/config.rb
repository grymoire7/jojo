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
  end
end
