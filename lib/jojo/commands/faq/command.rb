# lib/jojo/commands/faq/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Faq
      class Command < Base
        def initialize(cli, generator: nil, **rest)
          super(cli, **rest)
          @generator = generator
        end

        def execute
          require_employer!

          say "Generating FAQs for #{employer.company_name}...", :green

          # Check tailored resume exists (REQUIRED)
          unless File.exist?(employer.resume_path)
            say "Tailored resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
            exit 1
          end

          faqs = generator.generate

          log(step: :faq, tokens: ai_client.total_tokens_used, status: "complete", faq_count: faqs.length)

          say "Generated #{faqs.length} FAQs and saved to #{employer.faq_path}", :green
        rescue => e
          say "Error generating FAQs: #{e.message}", :red
          begin
            log(step: :faq, status: "failed", error: e.message)
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
            verbose: verbose?
          )
        end
      end
    end
  end
end
