# lib/jojo/commands/research/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Research
      class Command < Base
        def execute
          require_employer!

          say "Generating research for #{employer.company_name}...", :green

          # Warn if research file missing (optional dependency)
          unless File.exist?(employer.research_path)
            # This is expected - we're generating it
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

          status_logger.log_step(:research, tokens: ai_client.total_tokens_used, status: "complete")

          say "Research generated and saved to #{employer.research_path}", :green
        rescue => e
          say "Error generating research: #{e.message}", :red
          begin
            status_logger.log_step(:research, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end
      end
    end
  end
end
