require 'yaml'
require_relative '../prompts/cover_letter_prompt'
require_relative '../project_loader'
require_relative '../project_selector'

module Jojo
  module Generators
    class CoverLetterGenerator
      attr_reader :employer, :ai_client, :config, :verbose, :inputs_path

      def initialize(employer, ai_client, config:, verbose: false, inputs_path: 'inputs')
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
        @inputs_path = inputs_path
      end

      def generate
        log "Gathering inputs for cover letter generation..."
        inputs = gather_inputs

        log "Loading relevant projects..."
        projects = load_projects

        log "Building cover letter prompt..."
        prompt = build_cover_letter_prompt(inputs, projects)

        log "Generating cover letter using AI..."
        cover_letter = call_ai(prompt)

        log "Adding landing page link..."
        cover_letter_with_link = add_landing_page_link(cover_letter, inputs)

        log "Saving cover letter to #{employer.cover_letter_path}..."
        save_cover_letter(cover_letter_with_link)

        log "Cover letter generation complete!"
        cover_letter_with_link
      end

      private

      def gather_inputs
        # Read job description (REQUIRED)
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Read tailored resume (REQUIRED - key difference from resume generator)
        unless File.exist?(employer.resume_path)
          raise "Tailored resume not found at #{employer.resume_path}. Run 'jojo resume' or 'jojo generate' first."
        end
        tailored_resume = File.read(employer.resume_path)

        # Read generic resume (REQUIRED)
        generic_resume_path = File.join(inputs_path, 'generic_resume.md')
        unless File.exist?(generic_resume_path)
          raise "Generic resume not found at #{generic_resume_path}"
        end
        generic_resume = File.read(generic_resume_path)

        # Read research (OPTIONAL)
        research = read_research

        # Read job details (OPTIONAL)
        job_details = read_job_details

        {
          job_description: job_description,
          tailored_resume: tailored_resume,
          generic_resume: generic_resume,
          research: research,
          job_details: job_details,
          company_name: employer.name,
          company_slug: employer.slug
        }
      end

      def read_research
        unless File.exist?(employer.research_path)
          log "Warning: Research not found at #{employer.research_path}, cover letter will be less targeted"
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

      def build_cover_letter_prompt(inputs, projects = [])
        Prompts::CoverLetter.generate_prompt(
          job_description: inputs[:job_description],
          tailored_resume: inputs[:tailored_resume],
          generic_resume: inputs[:generic_resume],
          research: inputs[:research],
          job_details: inputs[:job_details],
          voice_and_tone: config.voice_and_tone,
          company_name: inputs[:company_name],
          highlight_projects: projects
        )
      end

      def call_ai(prompt)
        ai_client.generate_text(prompt)
      end

      def add_landing_page_link(cover_letter_content, inputs)
        link = "**Specifically for #{inputs[:company_name]}**: #{config.base_url}/resume/#{inputs[:company_slug]}"
        "#{link}\n\n#{cover_letter_content}"
      end

      def save_cover_letter(content)
        File.write(employer.cover_letter_path, content)
      end

      def log(message)
        puts "  [CoverLetterGenerator] #{message}" if verbose
      end

      def load_projects
        return [] unless File.exist?('inputs/projects.yml')

        loader = ProjectLoader.new('inputs/projects.yml')
        all_projects = loader.load

        selector = ProjectSelector.new(employer, all_projects)
        selector.select_for_cover_letter(limit: 2)
      rescue ProjectLoader::ValidationError => e
        log "Warning: Projects validation failed: #{e.message}"
        []
      end
    end
  end
end
