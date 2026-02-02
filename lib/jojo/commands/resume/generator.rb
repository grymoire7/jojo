# lib/jojo/commands/resume/generator.rb
require "yaml"
require_relative "curation_service"

module Jojo
  module Commands
    module Resume
      class Generator
        attr_reader :employer, :ai_client, :config, :verbose, :inputs_path, :overwrite_flag, :cli_instance

        def initialize(employer, ai_client, config:, verbose: false, inputs_path: "inputs", overwrite_flag: nil, cli_instance: nil)
          @employer = employer
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

          cache_path = File.join(employer.base_path, "resume_data_curated.yml")

          job_context = {
            job_description: File.read(employer.job_description_path)
          }

          log "Using transformation pipeline..."
          service = CurationService.new(
            ai_client: ai_client,
            config: config,
            resume_data_path: resume_data_path,
            template_path: template_path,
            cache_path: cache_path
          )

          resume = service.generate(job_context)
          resume_with_link = add_landing_page_link(resume)

          log "Saving resume to #{employer.resume_path}..."
          save_resume(resume_with_link)

          log "Resume generation complete!"
          resume_with_link
        end

        private

        def add_landing_page_link(resume_content)
          link = "**Specifically for #{employer.company_name}**: #{config.base_url}/resume/#{employer.slug}"
          "#{link}\n\n#{resume_content}"
        end

        def save_resume(content)
          if cli_instance
            cli_instance.with_overwrite_check(employer.resume_path, overwrite_flag) do
              File.write(employer.resume_path, content)
            end
          else
            File.write(employer.resume_path, content)
          end
        end

        def log(message)
          puts "  [ResumeGenerator] #{message}" if verbose
        end
      end
    end
  end
end
