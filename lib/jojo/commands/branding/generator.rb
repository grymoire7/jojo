# lib/jojo/commands/branding/generator.rb
require "yaml"
require_relative "prompt"

module Jojo
  module Commands
    module Branding
      class Generator
        attr_reader :application, :ai_client, :config, :verbose

        def initialize(application, ai_client, config:, verbose: false)
          @application = application
          @ai_client = ai_client
          @config = config
          @verbose = verbose
        end

        def generate
          log "Gathering inputs for branding statement..."
          inputs = gather_inputs

          log "Generating branding statement using AI..."
          branding_statement = generate_branding_statement(inputs)

          log "Saving branding statement to #{application.branding_path}..."
          save_branding(branding_statement)

          log "Branding statement generation complete!"
          branding_statement
        end

        private

        def gather_inputs
          unless File.exist?(application.job_description_path)
            raise "Job description not found at #{application.job_description_path}"
          end
          job_description = File.read(application.job_description_path)

          unless File.exist?(application.resume_path)
            raise "Resume not found at #{application.resume_path}. Run 'jojo resume' first."
          end
          resume = File.read(application.resume_path)

          research = read_research
          job_details = read_job_details

          {
            job_description: job_description,
            resume: resume,
            research: research,
            job_details: job_details,
            company_name: application.company_name
          }
        end

        def read_research
          unless File.exist?(application.research_path)
            log "Warning: Research not found, branding will be less targeted"
            return nil
          end

          File.read(application.research_path)
        end

        def read_job_details
          return nil unless File.exist?(application.job_details_path)

          YAML.load_file(application.job_details_path)
        rescue => e
          log "Warning: Could not parse job details: #{e.message}"
          nil
        end

        def generate_branding_statement(inputs)
          prompt = Prompt.generate_prompt(
            job_description: inputs[:job_description],
            resume: inputs[:resume],
            company_name: inputs[:company_name],
            seeker_name: config.seeker_name,
            voice_and_tone: config.voice_and_tone,
            research: inputs[:research],
            job_details: inputs[:job_details]
          )

          ai_client.generate_text(prompt)
        end

        def save_branding(branding_statement)
          File.write(application.branding_path, branding_statement)
        end

        def log(message)
          puts "  [BrandingGenerator] #{message}" if verbose
        end
      end
    end
  end
end
