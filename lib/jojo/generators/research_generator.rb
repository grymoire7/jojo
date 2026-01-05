require "yaml"
require "deepsearch"
require_relative "../prompts/research_prompt"
require_relative "../resume_data_loader"

module Jojo
  module Generators
    class ResearchGenerator
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
        job_details["company_name"] || employer.name
      rescue => e
        log "Warning: Could not parse job details, using employer name: #{e.message}"
        employer.name
      end

      def read_generic_resume
        resume_data_path = File.join(inputs_path, "resume_data.yml")

        unless File.exist?(resume_data_path)
          log "Warning: Resume data not found at #{resume_data_path}, research will be less personalized"
          return nil
        end

        loader = ResumeDataLoader.new(resume_data_path)
        resume_data = loader.load

        # Format resume data as text for the prompt
        format_resume_data(resume_data)
      rescue ResumeDataLoader::LoadError, ResumeDataLoader::ValidationError => e
        log "Warning: Could not load resume data: #{e.message}"
        nil
      end

      def format_resume_data(data)
        # Convert structured resume_data to readable text format
        output = []
        output << "# #{data["name"]}"
        output << "#{data["email"]} | #{data["location"]}"
        output << ""
        output << "## Summary"
        output << data["summary"]
        output << ""
        output << "## Skills"
        output << data["skills"].join(", ")
        output << ""
        output << "## Experience"
        data["experience"].each do |exp|
          output << "### #{exp["title"]} at #{exp["company"]}"
          output << exp["description"]
          if exp["technologies"]
            output << "Technologies: #{exp["technologies"].join(", ")}"
          end
          output << ""
        end

        output.join("\n")
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

        unless config.search_configured?
          log "Warning: Search provider not configured, skipping web search"
          return nil
        end

        log "Performing web search for #{company_name}..."

        # Configure deepsearch with the search provider
        search_client = DeepSearch::Client.new(
          service: config.search_service,
          api_key: config.search_api_key
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
        if cli_instance
          cli_instance.with_overwrite_check(employer.research_path, overwrite_flag) do
            File.write(employer.research_path, content)
          end
        else
          File.write(employer.research_path, content)
        end
      end

      def log(message)
        puts "  [ResearchGenerator] #{message}" if verbose
      end
    end
  end
end
