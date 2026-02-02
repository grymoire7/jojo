# lib/jojo/commands/branding/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Branding
      class Command < Base
        def execute
          require_employer!

          # Check for existing branding.md and --overwrite flag
          if File.exist?(employer.branding_path) && !overwrite?
            say "Branding statement already exists at #{employer.branding_path}", :red
            say "Use --overwrite to regenerate.", :yellow
            exit 1
          end

          say "Generating branding statement for #{employer.company_name}...", :green

          # Check that resume has been generated (REQUIRED)
          unless File.exist?(employer.resume_path)
            say "Resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
            exit 1
          end

          generator = Generator.new(
            employer,
            ai_client,
            config: config,
            verbose: verbose?
          )
          generator.generate

          log(step: :branding, tokens: ai_client.total_tokens_used, status: "complete")

          say "Branding statement generated and saved to #{employer.branding_path}", :green
        rescue => e
          say "Error generating branding statement: #{e.message}", :red
          begin
            log(step: :branding, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end
      end
    end
  end
end
