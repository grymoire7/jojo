# lib/jojo/resume_data_loader.rb
require "yaml"

module Jojo
  class ResumeDataLoader
    class LoadError < StandardError; end
    class ValidationError < StandardError; end

    REQUIRED_FIELDS = %w[name email summary skills experience].freeze

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      raise LoadError, "Resume data file not found: #{@file_path}" unless File.exist?(@file_path)

      data = YAML.load_file(@file_path, aliases: true)
      validate!(data)
      data
    rescue Psych::SyntaxError => e
      raise LoadError, "Invalid YAML syntax: #{e.message}"
    end

    private

    def validate!(data)
      missing_fields = REQUIRED_FIELDS - data.keys

      unless missing_fields.empty?
        raise ValidationError, "Missing required fields: #{missing_fields.join(", ")}"
      end

      # Validate field types
      raise ValidationError, "skills must be an array" unless data["skills"].is_a?(Array)
      raise ValidationError, "experience must be an array" unless data["experience"].is_a?(Array)
    end
  end
end
