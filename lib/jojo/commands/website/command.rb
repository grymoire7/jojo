# lib/jojo/commands/website/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Website
      class Command < Base
        def execute
          require_employer!

          say "Generating website for #{employer.company_name}...", :green

          # Check that resume has been generated (REQUIRED)
          unless File.exist?(employer.resume_path)
            say "Resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
            exit 1
          end

          # Warn if research missing (optional)
          unless File.exist?(employer.research_path)
            say "Warning: Research not found. Website will be less targeted.", :yellow
          end

          generator = Generator.new(
            employer,
            ai_client,
            config: config,
            template: template_name,
            verbose: verbose?,
            overwrite_flag: overwrite?,
            cli_instance: cli
          )
          generator.generate

          log(step: :website, tokens: ai_client.total_tokens_used, status: "complete", metadata: {template: template_name})

          say "Website generated and saved to #{employer.index_html_path}", :green
        rescue => e
          say "Error generating website: #{e.message}", :red
          begin
            log(step: :website, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end

        private

        def template_name
          options[:template] || "default"
        end
      end
    end
  end
end
