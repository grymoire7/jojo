require_relative "pandoc_checker"

module Jojo
  class PdfGenerator
    class SourceFileNotFoundError < StandardError; end
    class PandocExecutionError < StandardError; end

    attr_reader :employer, :verbose, :output

    def initialize(employer, verbose: false, output: $stdout)
      @employer = employer
      @verbose = verbose
      @output = output
    end

    def generate_all
      PandocChecker.check!

      results = {generated: [], skipped: []}

      # Generate resume PDF
      if File.exist?(employer.resume_path)
        generate_resume_pdf
        results[:generated] << :resume
      else
        results[:skipped] << :resume
      end

      # Generate cover letter PDF
      if File.exist?(employer.cover_letter_path)
        generate_cover_letter_pdf
        results[:generated] << :cover_letter
      else
        results[:skipped] << :cover_letter
      end

      results
    end

    def generate_resume_pdf
      generate_pdf(
        source: employer.resume_path,
        output: employer.resume_pdf_path,
        document_type: "resume"
      )
    end

    def generate_cover_letter_pdf
      generate_pdf(
        source: employer.cover_letter_path,
        output: employer.cover_letter_pdf_path,
        document_type: "cover letter"
      )
    end

    private

    def generate_pdf(source:, output:, document_type:)
      unless File.exist?(source)
        raise SourceFileNotFoundError, "#{document_type}.md not found at #{source}"
      end

      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(output))

      # Build Pandoc command
      cmd = build_pandoc_command(source, output)

      log_verbose("Generating PDF: #{cmd}") if verbose

      success = system(cmd)

      unless success
        raise PandocExecutionError, "Pandoc failed to generate PDF for #{document_type}"
      end

      output
    end

    def build_pandoc_command(source, output)
      [
        "pandoc",
        escape_path(source),
        "-o", escape_path(output),
        "--pdf-engine=pdflatex",
        "-V", "geometry:margin=1in",
        "-V", "fontsize=11pt"
      ].join(" ")
    end

    def escape_path(path)
      # Escape spaces and special characters for shell
      "\"#{path}\""
    end

    def log_verbose(message)
      output.puts message if verbose
    end
  end
end
