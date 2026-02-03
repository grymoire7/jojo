# lib/jojo/commands/job_description/command.rb
require_relative "../base"
require_relative "../../state_persistence"

module Jojo
  module Commands
    module JobDescription
      class Command < Base
        def execute
          resolved_slug = slug || StatePersistence.load_slug
          unless resolved_slug
            say "No application specified. Use -s or select one in interactive mode.", :red
            exit 1
          end

          @employer ||= Jojo::Employer.new(resolved_slug)
          unless File.exist?(employer.base_path)
            say "Application '#{resolved_slug}' does not exist. Run 'jojo new -s #{resolved_slug}' first.", :red
            exit 1
          end

          say "Processing job description for: #{resolved_slug}", :green

          employer.create_artifacts(
            job_source,
            ai_client,
            overwrite_flag: overwrite?,
            cli_instance: cli,
            verbose: verbose?
          )

          log(step: :job_description, tokens: ai_client.total_tokens_used, status: "complete")

          say "-> Job description processed and saved", :green
          say "-> Job details extracted and saved", :green
        rescue => e
          say "Error processing job description: #{e.message}", :red
          begin
            log(step: :job_description, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end

        private

        def job_source
          options[:job]
        end
      end
    end
  end
end
