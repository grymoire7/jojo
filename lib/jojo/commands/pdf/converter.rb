# lib/jojo/commands/pdf/converter.rb
require_relative "pandoc_checker"
require_relative "wkhtmltopdf_checker"

module Jojo
  module Commands
    module Pdf
      class Converter
        class SourceFileNotFoundError < StandardError; end
        class PandocExecutionError < StandardError; end
        class WkhtmltopdfExecutionError < StandardError; end

        CSS_PATH = File.expand_path("../../../../templates/pdf-stylesheet.css", __dir__)

        attr_reader :application, :verbose, :output

        def initialize(application, verbose: false, output: $stdout)
          @application = application
          @verbose = verbose
          @output = output
        end

        def generate_all
          PandocChecker.check!
          WkhtmltopdfChecker.check!

          results = {generated: [], skipped: []}

          if File.exist?(application.resume_path)
            generate_resume_pdf
            results[:generated] << :resume
          else
            results[:skipped] << :resume
          end

          if File.exist?(application.cover_letter_path)
            generate_cover_letter_pdf
            results[:generated] << :cover_letter
          else
            results[:skipped] << :cover_letter
          end

          results
        end

        def generate_resume_pdf
          generate_html_and_pdf(
            source: application.resume_path,
            html_output: application.resume_html_path,
            pdf_output: application.resume_pdf_path,
            document_type: "resume"
          )
        end

        def generate_cover_letter_pdf
          generate_html_and_pdf(
            source: application.cover_letter_path,
            html_output: application.cover_letter_html_path,
            pdf_output: application.cover_letter_pdf_path,
            document_type: "cover letter"
          )
        end

        private

        def generate_html_and_pdf(source:, html_output:, pdf_output:, document_type:)
          unless File.exist?(source)
            raise SourceFileNotFoundError, "#{document_type}.md not found at #{source}"
          end

          FileUtils.mkdir_p(File.dirname(pdf_output))

          html_cmd = build_pandoc_html_command(source, html_output)
          log_verbose("Generating HTML: #{html_cmd}")

          unless system(html_cmd)
            raise PandocExecutionError, "Pandoc failed to generate HTML for #{document_type}"
          end

          pdf_cmd = build_wkhtmltopdf_command(html_output, pdf_output)
          log_verbose("Generating PDF: #{pdf_cmd}")

          unless system(pdf_cmd)
            raise WkhtmltopdfExecutionError, "wkhtmltopdf failed to generate PDF for #{document_type}"
          end

          pdf_output
        end

        def build_pandoc_html_command(source, html_output)
          [
            "pandoc",
            escape_path(source),
            "-f", "markdown",
            "-t", "html",
            "--embed-resources",
            "--standalone",
            "-c", escape_path(CSS_PATH),
            "-o", escape_path(html_output)
          ].join(" ")
        end

        def build_wkhtmltopdf_command(html_input, pdf_output)
          [
            "wkhtmltopdf",
            escape_path(html_input),
            escape_path(pdf_output)
          ].join(" ")
        end

        def escape_path(path)
          "\"#{path}\""
        end

        def log_verbose(message)
          output.puts message if verbose
        end
      end
    end
  end
end
