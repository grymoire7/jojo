require 'yaml'
require_relative '../prompts/resume_prompt'

module Jojo
  module Generators
    class ResumeGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        log "Gathering inputs for resume generation..."
        inputs = gather_inputs

        log "Building resume prompt..."
        prompt = build_resume_prompt(inputs)

        log "Generating tailored resume using AI..."
        resume = call_ai(prompt)

        log "Adding landing page link..."
        resume_with_link = add_landing_page_link(resume, inputs)

        log "Saving resume to #{employer.resume_path}..."
        save_resume(resume_with_link)

        log "Resume generation complete!"
        resume_with_link
      end

      private

      def gather_inputs
        # Read job description (REQUIRED)
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Read generic resume (REQUIRED)
        unless File.exist?('inputs/generic_resume.md')
          raise "Generic resume not found at inputs/generic_resume.md"
        end
        generic_resume = File.read('inputs/generic_resume.md')

        # Read research (OPTIONAL)
        research = read_research

        # Read job details (OPTIONAL)
        job_details = read_job_details

        {
          job_description: job_description,
          generic_resume: generic_resume,
          research: research,
          job_details: job_details,
          company_name: employer.name,
          company_slug: employer.slug
        }
      end

      def read_research
        unless File.exist?(employer.research_path)
          log "Warning: Research not found at #{employer.research_path}, resume will be less targeted"
          return nil
        end

        File.read(employer.research_path)
      end

      def read_job_details
        unless File.exist?(employer.job_details_path)
          return nil
        end

        YAML.load_file(employer.job_details_path)
      rescue => e
        log "Warning: Could not parse job details: #{e.message}"
        nil
      end

      def build_resume_prompt(inputs)
        Prompts::Resume.generate_prompt(
          job_description: inputs[:job_description],
          generic_resume: inputs[:generic_resume],
          research: inputs[:research],
          job_details: inputs[:job_details],
          voice_and_tone: config.voice_and_tone
        )
      end

      def call_ai(prompt)
        ai_client.generate_text(prompt)
      end

      def add_landing_page_link(resume_content, inputs)
        link = "**Specifically for #{inputs[:company_name]}**: #{config.base_url}/resume/#{inputs[:company_slug]}"
        "#{link}\n\n#{resume_content}"
      end

      def save_resume(content)
        File.write(employer.resume_path, content)
      end

      def log(message)
        puts "  [ResumeGenerator] #{message}" if verbose
      end
    end
  end
end
