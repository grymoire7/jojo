# lib/jojo/commands/faq/generator.rb
require "json"
require "yaml"
require_relative "prompt"

module Jojo
  module Commands
    module Faq
      class Generator
        attr_reader :application, :ai_client, :config, :verbose

        def initialize(application, ai_client, config:, verbose: false)
          @application = application
          @ai_client = ai_client
          @config = config
          @verbose = verbose
        end

        def generate
          log "Gathering inputs for FAQ generation..."
          inputs = gather_inputs

          log "Building FAQ prompt..."
          prompt = build_prompt(inputs)

          log "Generating FAQs using AI (reasoning model)..."
          faqs_json = ai_client.reason(prompt)

          log "Parsing JSON response..."
          faqs = parse_faqs(faqs_json)

          log "Saving FAQs to #{application.faq_path}..."
          save_faqs(faqs)

          log "FAQ generation complete! Generated #{faqs.length} FAQs."
          faqs
        end

        private

        def gather_inputs
          unless File.exist?(application.job_description_path)
            raise "Job description not found at #{application.job_description_path}"
          end
          job_description = File.read(application.job_description_path)

          unless File.exist?(application.resume_path)
            raise "Resume not found at #{application.resume_path}"
          end
          resume = File.read(application.resume_path)

          research = read_research
          job_details = read_job_details

          {
            job_description: job_description,
            resume: resume,
            research: research,
            job_details: job_details
          }
        end

        def read_research
          return nil unless File.exist?(application.research_path)
          File.read(application.research_path)
        rescue => e
          log "Warning: Could not read research: #{e.message}"
          nil
        end

        def read_job_details
          return nil unless File.exist?(application.job_details_path)
          YAML.load_file(application.job_details_path)
        rescue => e
          log "Warning: Could not read job details: #{e.message}"
          nil
        end

        def build_prompt(inputs)
          Prompt.generate_prompt(
            job_description: inputs[:job_description],
            resume: inputs[:resume],
            research: inputs[:research],
            job_details: inputs[:job_details] || {},
            base_url: config.base_url,
            seeker_name: config.seeker_name,
            voice_and_tone: config.voice_and_tone
          )
        end

        def parse_faqs(json_string)
          # Strip markdown code fences if present (e.g., ```json ... ```)
          cleaned_json = json_string.strip.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "")

          faqs = JSON.parse(cleaned_json, symbolize_names: true)

          # Filter out invalid FAQs (missing question or answer)
          valid_faqs = faqs.select do |faq|
            faq[:question] && faq[:answer] && !faq[:question].empty? && !faq[:answer].empty?
          end

          if valid_faqs.length < faqs.length
            log "Warning: Filtered out #{faqs.length - valid_faqs.length} invalid FAQ(s)"
          end

          valid_faqs
        rescue JSON::ParserError => e
          log "Error: Failed to parse AI response as JSON: #{e.message}"
          []
        end

        def save_faqs(faqs)
          json_output = JSON.pretty_generate(faqs)
          File.write(application.faq_path, json_output)
        end

        def log(message)
          puts "  [FaqGenerator] #{message}" if verbose
        end
      end
    end
  end
end
