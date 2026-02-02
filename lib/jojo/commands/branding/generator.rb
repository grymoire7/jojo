# lib/jojo/commands/branding/generator.rb
require "yaml"
require_relative "prompt"

module Jojo
  module Commands
    module Branding
      class Generator
        attr_reader :employer, :ai_client, :config, :verbose

        def initialize(employer, ai_client, config:, verbose: false)
          @employer = employer
          @ai_client = ai_client
          @config = config
          @verbose = verbose
        end

        def generate
          log "Gathering inputs for branding statement..."
          inputs = gather_inputs

          log "Generating branding statement using AI..."
          branding_statement = generate_branding_statement(inputs)

          log "Saving branding statement to #{employer.branding_path}..."
          save_branding(branding_statement)

          log "Branding statement generation complete!"
          branding_statement
        end

        private

        def gather_inputs
          unless File.exist?(employer.job_description_path)
            raise "Job description not found at #{employer.job_description_path}"
          end
          job_description = File.read(employer.job_description_path)

          unless File.exist?(employer.resume_path)
            raise "Resume not found at #{employer.resume_path}. Run 'jojo resume' first."
          end
          resume = File.read(employer.resume_path)

          research = read_research
          job_details = read_job_details

          {
            job_description: job_description,
            resume: resume,
            research: research,
            job_details: job_details,
            company_name: employer.company_name
          }
        end

        def read_research
          return nil unless File.exist?(employer.research_path)
          log "Warning: Research not found, branding will be less targeted" unless File.exist?(employer.research_path)
          File.read(employer.research_path)
        end

        def read_job_details
          return nil unless File.exist?(employer.job_details_path)
          YAML.load_file(employer.job_details_path)
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
          File.write(employer.branding_path, branding_statement)
        end

        def log(message)
          puts "  [BrandingGenerator] #{message}" if verbose
        end
      end
    end
  end
end
