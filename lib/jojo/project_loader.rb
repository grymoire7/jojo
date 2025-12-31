require "yaml"

module Jojo
  class ProjectLoader
    class ValidationError < StandardError; end

    REQUIRED_FIELDS = %w[title description skills]

    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      return [] unless File.exist?(file_path)
      projects = YAML.load_file(file_path, permitted_classes: [Date])
      validate_projects!(projects)
      projects.map { |p| symbolize_keys(p) }
    end

    private

    def validate_projects!(projects)
      errors = []

      projects.each_with_index do |project, index|
        REQUIRED_FIELDS.each do |field|
          unless project[field]
            errors << "Project #{index + 1}: missing '#{field}'"
          end
        end

        if project["skills"] && !project["skills"].is_a?(Array)
          errors << "Project #{index + 1}: 'skills' must be an array"
        end
      end

      raise ValidationError, errors.join("; ") unless errors.empty?
    end

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
