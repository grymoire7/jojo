# lib/jojo/commands/cover_letter/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module CoverLetter
      class Command < Base
        def initialize(cli, generator: nil, **rest)
          super(cli, **rest)
          @generator = generator
        end

        def execute
          require_application!

          say "Generating cover letter for #{application.company_name}...", :green

          # Check tailored resume exists (REQUIRED)
          unless File.exist?(application.resume_path)
            say "Tailored resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
            exit 1
          end

          # Check resume data exists (REQUIRED)
          unless File.exist?("inputs/resume_data.yml")
            say "Resume data not found at inputs/resume_data.yml", :red
            say "  Run 'jojo setup' or copy templates/resume_data.yml to inputs/ and customize it.", :yellow
            exit 1
          end

          # Warn if research missing (optional)
          unless File.exist?(application.research_path)
            say "Warning: Research not found. Cover letter will be less targeted.", :yellow
          end

          generator.generate

          log(step: :cover_letter, tokens: ai_client.total_tokens_used, status: "complete")

          say "Cover letter generated and saved to #{application.cover_letter_path}", :green
        rescue => e
          say "Error generating cover letter: #{e.message}", :red
          begin
            log(step: :cover_letter, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end

        private

        def generator
          @generator ||= Generator.new(
            application,
            ai_client,
            config: config,
            verbose: verbose?,
            overwrite_flag: overwrite?,
            cli_instance: cli
          )
        end
      end
    end
  end
end
