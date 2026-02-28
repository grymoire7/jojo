# lib/jojo/commands/resume/curation_service.rb
require_relative "../../resume_data_loader"
require_relative "transformer"
require_relative "../../erb_renderer"
require "yaml"
require "digest"

module Jojo
  module Commands
    module Resume
      class CurationService
        def initialize(ai_client:, config:, resume_data_path:, template_path:, cache_path: nil, overwrite: false)
          @ai_client = ai_client
          @config = config
          @resume_data_path = resume_data_path
          @template_path = template_path
          @cache_path = cache_path
          @overwrite = overwrite
        end

        def generate(job_context, template_vars: {})
          # Load base resume data
          loader = ResumeDataLoader.new(@resume_data_path)
          data = loader.load

          # Check cache
          if @cache_path && cache_valid?(job_context)
            data = YAML.load_file(@cache_path, aliases: true)
          else
            # Transform data based on permissions
            transformer = Transformer.new(
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
          renderer.render(data.merge(template_vars))
        end

        private

        def cache_valid?(job_context)
          return false if @overwrite
          return false unless File.exist?(@cache_path)

          true
        end

        def save_cache(data, job_context)
          File.write(@cache_path, data.to_yaml)
        end
      end
    end
  end
end
