require 'yaml'

module Jojo
  class ProjectLoader
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      return [] unless File.exist?(file_path)

      projects = YAML.load_file(file_path)
      projects.map { |p| symbolize_keys(p) }
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
