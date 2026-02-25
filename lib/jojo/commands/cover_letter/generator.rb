# lib/jojo/commands/cover_letter/generator.rb
require "yaml"
require_relative "prompt"
require_relative "../../resume_data_loader"
require_relative "../../resume_data_formatter"
require_relative "../../erb_renderer"

module Jojo
  module Commands
    module CoverLetter
      class Generator
        TEMPLATE_PATH = File.expand_path("cover_letter.md.erb", __dir__)

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
          log "Gathering inputs for cover letter generation..."
          inputs = gather_inputs

          log "Loading relevant projects from resume_data.yml..."
          projects = load_projects

          log "Building cover letter prompt..."
          prompt = build_cover_letter_prompt(inputs, projects)

          log "Generating cover letter using AI..."
          cover_letter = call_ai(prompt)

          log "Rendering cover letter template..."
          rendered = render_template(cover_letter, inputs)

          log "Saving cover letter to #{application.cover_letter_path}..."
          save_cover_letter(rendered)

          log "Cover letter generation complete!"
          rendered
        end

        private

        def gather_inputs
          # Read job description (REQUIRED)
          unless File.exist?(application.job_description_path)
            raise "Job description not found at #{application.job_description_path}"
          end
          job_description = File.read(application.job_description_path)

          # Read tailored resume (REQUIRED - key difference from resume generator)
          unless File.exist?(application.resume_path)
            raise "Tailored resume not found at #{application.resume_path}. Run 'jojo resume' or 'jojo generate' first."
          end
          tailored_resume = File.read(application.resume_path)

          # Read resume data (REQUIRED)
          resume_data_path = File.join(inputs_path, "resume_data.yml")
          unless File.exist?(resume_data_path)
            raise "Resume data not found at #{resume_data_path}"
          end
          loader = ResumeDataLoader.new(resume_data_path)
          resume_data = loader.load
          generic_resume = Jojo::ResumeDataFormatter.format(resume_data)

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
            company_name: application.company_name,
            company_slug: application.slug,
            resume_data: resume_data
          }
        end

        def read_research
          unless File.exist?(application.research_path)
            log "Warning: Research not found at #{application.research_path}, cover letter will be less targeted"
            return nil
          end

          File.read(application.research_path)
        end

        def read_job_details
          unless File.exist?(application.job_details_path)
            return nil
          end

          YAML.load_file(application.job_details_path)
        rescue => e
          log "Warning: Could not parse job details: #{e.message}"
          nil
        end

        def build_cover_letter_prompt(inputs, projects = [])
          Prompt.generate_prompt(
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

        def render_template(body, inputs)
          resume_data = inputs[:resume_data]
          renderer = ErbRenderer.new(TEMPLATE_PATH)
          renderer.render(
            "name" => resume_data["name"],
            "email" => resume_data["email"],
            "website" => resume_data["website"],
            "date" => Time.now.strftime("%B, %Y"),
            "body" => body,
            "company_name" => inputs[:company_name],
            "landing_page_url" => "#{config.base_url}/#{inputs[:company_slug]}"
          )
        end

        def save_cover_letter(content)
          if cli_instance
            cli_instance.with_overwrite_check(application.cover_letter_path, overwrite_flag) do
              File.write(application.cover_letter_path, content)
            end
          else
            File.write(application.cover_letter_path, content)
          end
        end

        def log(message)
          puts "  [CoverLetterGenerator] #{message}" if verbose
        end

        def load_projects
          resume_data_path = File.join(inputs_path, "resume_data.yml")
          return [] unless File.exist?(resume_data_path)

          loader = ResumeDataLoader.new(resume_data_path)
          resume_data = loader.load

          projects = resume_data["projects"] || []

          # Convert to symbol keys for consistency
          projects.map { |p| p.transform_keys(&:to_sym) }
        rescue ResumeDataLoader::LoadError, ResumeDataLoader::ValidationError => e
          log "Warning: Could not load projects from resume_data.yml: #{e.message}"
          []
        end
      end
    end
  end
end
