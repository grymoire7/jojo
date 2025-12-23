require 'yaml'
require 'deepsearch'

module Jojo
  module Generators
    class ResearchGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        log "Gathering inputs for research generation..."
        inputs = gather_inputs

        log "Performing web search for #{inputs[:company_name]}..."
        web_results = perform_web_search(inputs[:company_name])

        log "Building research prompt..."
        prompt = build_research_prompt(inputs, web_results)

        log "Generating research using AI..."
        research = call_ai(prompt)

        log "Saving research to #{employer.research_path}..."
        save_research(research)

        log "Research generation complete!"
        research
      end

      private

      def gather_inputs
        # Read job description
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Extract company name from job details
        company_name = extract_company_name

        # Read generic resume if available
        resume = read_generic_resume

        {
          job_description: job_description,
          company_name: company_name,
          resume: resume
        }
      end

      def extract_company_name
        unless File.exist?(employer.job_details_path)
          return employer.name
        end

        job_details = YAML.load_file(employer.job_details_path)
        job_details['company_name'] || employer.name
      rescue => e
        log "Warning: Could not parse job details, using employer name: #{e.message}"
        employer.name
      end

      def read_generic_resume
        resume_path = 'inputs/generic_resume.md'

        unless File.exist?(resume_path)
          log "Warning: Generic resume not found at #{resume_path}, research will be less personalized"
          return nil
        end

        File.read(resume_path)
      end

      def perform_web_search(company_name)
        # Web search uses deepsearch-rb gem to query search APIs
        # Requires search_provider configuration in config.yml:
        #   search_provider:
        #     service: serper  # or tavily, searxng, duckduckgo
        #     api_key: your_api_key
        #
        # Supported services: https://github.com/alexshagov/deepsearch-rb
        #
        # If search provider is not configured, research generation continues
        # using only job description analysis (graceful degradation)

        unless config.search_provider_configured?
          log "Warning: Search provider not configured, skipping web search"
          return nil
        end

        log "Performing web search for #{company_name}..."

        # Configure deepsearch with the search provider
        search_client = DeepSearch::Client.new(
          service: config.search_provider_service,
          api_key: config.search_provider_api_key
        )

        # Search for company information
        query = "#{company_name} company information recent news"
        results = search_client.search(query, num_results: 5)

        # Combine results into a single text
        combined_results = results.map do |result|
          "#{result[:title]}\n#{result[:snippet]}\nSource: #{result[:link]}"
        end.join("\n\n---\n\n")

        log "Web search completed, found #{results.size} results"
        combined_results
      rescue => e
        log "Warning: Web search failed: #{e.message}"
        nil
      end

      def build_research_prompt(inputs, web_results)
        Prompts::Research.generate_prompt(
          job_description: inputs[:job_description],
          company_name: inputs[:company_name],
          web_results: web_results,
          resume: inputs[:resume]
        )
      end

      def call_ai(prompt)
        ai_client.reason(prompt)
      end

      def save_research(content)
        File.write(employer.research_path, content)
      end

      def log(message)
        puts "  [ResearchGenerator] #{message}" if verbose
      end
    end
  end
end
