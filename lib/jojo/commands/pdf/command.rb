# lib/jojo/commands/pdf/command.rb
require_relative "../base"
require_relative "converter"
require_relative "pandoc_checker"

module Jojo
  module Commands
    module Pdf
      class Command < Base
        def initialize(cli, converter: nil, **rest)
          super(cli, **rest)
          @converter = converter
        end

        def execute
          require_employer!

          say "Generating PDFs for #{employer.company_name}...", :green

          results = converter.generate_all

          # Report what was generated
          results[:generated].each do |doc_type|
            say "#{doc_type.to_s.capitalize} PDF generated", :green
          end

          # Report what was skipped
          results[:skipped].each do |doc_type|
            say "Skipped #{doc_type}: markdown file not found", :yellow
          end

          if results[:generated].any?
            log(step: :pdf, status: "complete", generated: results[:generated].length)
            say "PDF generation complete!", :green
          else
            say "No PDFs generated. Generate resume and cover letter first.", :yellow
            exit 1
          end
        rescue PandocChecker::PandocNotFoundError => e
          say e.message, :red
          begin
            log(step: :pdf, status: "failed", error: "Pandoc not installed")
          rescue
            # Ignore logging errors
          end
          exit 1
        rescue => e
          say "Error generating PDFs: #{e.message}", :red
          begin
            log(step: :pdf, status: "failed", error: e.message)
          rescue
            # Ignore logging errors
          end
          exit 1
        end

        private

        def converter
          @converter ||= Converter.new(employer, verbose: verbose?)
        end
      end
    end
  end
end
