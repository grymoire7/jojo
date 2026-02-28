# lib/jojo/commands/resume/generator.rb
require "yaml"
require_relative "curation_service"

module Jojo
  module Commands
    module Resume
      class Generator
        attr_reader :application, :ai_client, :config, :verbose, :inputs_path, :overwrite_flag, :cli_instance

        def initialize(application, ai_client, config:, verbose: false, inputs_path: "inputs", overwrite_flag: nil, cli_instance: nil)
          @application = application
          @ai_client = ai_client
          @config = config
          @verbose = verbose
          @inputs_path = inputs_path
          @overwrite_flag = overwrite_flag
          @cli_instance = cli_instance
        end

        def generate
          log "Generating config-based resume..."

          resume_data_path = File.join(inputs_path, "resume_data.yml")
          template_path = config.resume_template ||
            File.join(inputs_path, "templates", "default_resume.md.erb")

          cache_path = File.join(application.base_path, "resume_data_curated.yml")

          job_context = {
            job_description: File.read(application.job_description_path)
          }

          template_vars = {
            "company_name" => application.company_name,
            "landing_page_url" => "#{config.base_url}/resume/#{application.slug}"
          }

          log "Using transformation pipeline..."
          service = CurationService.new(
            ai_client: ai_client,
            config: config,
            resume_data_path: resume_data_path,
            template_path: template_path,
            cache_path: cache_path,
            overwrite: overwrite_flag || false
          )

          resume = service.generate(job_context, template_vars: template_vars)

          log "Saving resume to #{application.resume_path}..."
          save_resume(resume)

          log "Resume generation complete!"
          resume
        end

        private

        def save_resume(content)
          if cli_instance
            cli_instance.with_overwrite_check(application.resume_path, overwrite_flag) do
              File.write(application.resume_path, content)
            end
          else
            File.write(application.resume_path, content)
          end
        end

        def log(message)
          puts "  [ResumeGenerator] #{message}" if verbose
        end
      end
    end
  end
end
