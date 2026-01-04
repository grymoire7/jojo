# lib/jojo/resume_curation_service.rb
require_relative "resume_data_loader"
require_relative "resume_transformer"
require_relative "erb_renderer"
require "yaml"
require "digest"

module Jojo
  class ResumeCurationService
    def initialize(ai_client:, config:, resume_data_path:, template_path:, cache_path: nil)
      @ai_client = ai_client
      @config = config
      @resume_data_path = resume_data_path
      @template_path = template_path
      @cache_path = cache_path
    end

    def generate(job_context)
      # Load base resume data
      loader = ResumeDataLoader.new(@resume_data_path)
      data = loader.load

      # Check cache
      if @cache_path && cache_valid?(job_context)
        data = YAML.load_file(@cache_path)
      else
        # Transform data based on permissions
        transformer = ResumeTransformer.new(
          ai_client: @ai_client,
          config: @config,
          job_context: job_context
        )
        data = transformer.transform(data)

        # Cache transformed data
        save_cache(data, job_context) if @cache_path
      end

      # Render using ERB template
      renderer = ErbRenderer.new(@template_path)
      renderer.render(data)
    end

    private

    def cache_valid?(job_context)
      return false unless File.exist?(@cache_path)

      # Simple cache validation - could be enhanced with timestamp checks
      true
    end

    def save_cache(data, job_context)
      File.write(@cache_path, data.to_yaml)
    end
  end
end
