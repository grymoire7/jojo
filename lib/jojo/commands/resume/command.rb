# lib/jojo/commands/resume/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Resume
      class Command < Base
        def execute
          require_employer!

          say "Generating resume for #{employer.company_name}...", :green

          # Check that research has been generated (optional warning)
          unless File.exist?(employer.research_path)
            say "Warning: Research not found. Resume will be less targeted.", :yellow
          end

          # Check that resume data exists (required)
          unless File.exist?("inputs/resume_data.yml")
            say "Resume data not found at inputs/resume_data.yml", :red
            say "  Run 'jojo setup' or copy templates/resume_data.yml to inputs/ and customize it.", :yellow
            exit 1
          end

          generator = Generator.new(
            employer,
            ai_client,
            config: config,
            verbose: verbose?,
            overwrite_flag: overwrite?,
            cli_instance: cli
          )
          generator.generate

          log(step: :resume, tokens: ai_client.total_tokens_used, status: "complete")

          say "Resume generated and saved to #{employer.resume_path}", :green
        rescue => e
          say "Error generating resume: #{e.message}", :red
          begin
            log(step: :resume, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end
      end
    end
  end
end
