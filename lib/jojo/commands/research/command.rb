# lib/jojo/commands/research/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Research
      class Command < Base
        def initialize(cli, generator: nil, **rest)
          super(cli, **rest)
          @generator = generator
        end

        def execute
          require_employer!

          say "Generating research for #{employer.company_name}...", :green

          generator.generate

          log(step: :research, tokens: ai_client.total_tokens_used, status: "complete")

          say "Research generated and saved to #{employer.research_path}", :green
        rescue => e
          say "Error generating research: #{e.message}", :red
          begin
            log(step: :research, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end

        private

        def generator
          @generator ||= Generator.new(
            employer,
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
