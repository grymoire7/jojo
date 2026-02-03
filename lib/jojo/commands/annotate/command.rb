# lib/jojo/commands/annotate/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Annotate
      class Command < Base
        def initialize(cli, generator: nil, **rest)
          super(cli, **rest)
          @generator = generator
        end

        def execute
          require_employer!

          say "Generating annotations for #{employer.company_name}...", :green

          annotations = generator.generate

          log(step: :annotate, tokens: ai_client.total_tokens_used, status: "complete")

          say "Generated #{annotations.length} annotations", :green
          say "  Saved to: #{employer.job_description_annotations_path}", :green
        rescue => e
          say "Error generating annotations: #{e.message}", :red
          begin
            log(step: :annotate, status: "failed", error: e.message)
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
            verbose: verbose?,
            overwrite_flag: overwrite?,
            cli_instance: cli
          )
        end
      end
    end
  end
end
