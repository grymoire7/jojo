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
          require_application!

          say "Generating FAQs for #{application.company_name}...", :green

          # Check tailored resume exists (REQUIRED)
          unless File.exist?(application.resume_path)
            say "Tailored resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
            exit 1
          end

          faqs = generator.generate

          log(step: :faq, tokens: ai_client.total_tokens_used, status: "complete", faq_count: faqs.length)

          say "Generated #{faqs.length} FAQs and saved to #{application.faq_path}", :green
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
            application,
            ai_client,
            config: config,
            verbose: verbose?
          )
        end
      end
    end
  end
end
