require "erb"
require "fileutils"
require_relative "commands/version/command"
require_relative "commands/annotate/command"
require_relative "commands/research/command"
require_relative "commands/resume/command"
require_relative "commands/cover_letter/command"
require_relative "commands/faq/command"
require_relative "commands/branding/command"
require_relative "commands/website/command"
require_relative "commands/pdf/command"
require_relative "commands/setup/command"
require_relative "commands/new/command"
require_relative "commands/job_description/command"
require_relative "commands/test/command"
require_relative "commands/interactive/command"
require_relative "status_logger"
require_relative "setup_service"
require_relative "template_validator"
require_relative "generators/research_generator"
require_relative "generators/resume_generator"
require_relative "generators/cover_letter_generator"
require_relative "generators/website_generator"
require_relative "generators/annotation_generator"
require_relative "generators/faq_generator"
require_relative "pdf_converter"

module Jojo
  class CLI < Thor
    include OverwriteHelper

    class_option :verbose, type: :boolean, aliases: "-v", desc: "Run verbosely"
    class_option :quiet, type: :boolean, aliases: "-q", desc: "Suppress output, rely on exit code"
    class_option :slug, type: :string, aliases: "-s", desc: "Employer slug (unique identifier)"
    class_option :template, type: :string, aliases: "-t", desc: "Website template name (default: default)", default: "default"
    class_option :overwrite, type: :boolean, banner: "Overwrite existing files without prompting"

    def self.exit_on_failure?
      true
    end

    default_task :interactive

    desc "version", "Show version"
    def version
      Commands::Version::Command.new(self, command_options).execute
    end

    desc "setup", "Setup configuration"
    def setup
      Commands::Setup::Command.new(self, command_options).execute
    end

    desc "new", "Create a new job application workspace"
    long_desc <<~DESC, wrap: false
      Create a new employer workspace directory.
      After creating, use 'jojo job_description' to process the job description.

      Examples:
        jojo new -s acme-corp-senior-dev
        jojo new -s bigco-principal
    DESC
    method_option :slug, type: :string, aliases: "-s", required: true, desc: "Unique employer identifier"
    def new
      Commands::New::Command.new(self, command_options).execute
    end

    desc "job_description", "Process job description for an application"
    long_desc <<~DESC, wrap: false
      Process a job description for an existing employer workspace.
      This extracts and saves the job description and key details.

      Examples:
        jojo job_description -s acme-corp-senior-dev -j job.txt
        jojo job_description -s bigco-principal -j https://careers.bigco.com/jobs/123
        jojo job_description -j job.txt  # Uses current application from state
    DESC
    method_option :slug, type: :string, aliases: "-s", desc: "Application slug (uses current if omitted)"
    method_option :job, type: :string, aliases: "-j", required: true, desc: "Job description (file path or URL)"
    def job_description
      Commands::JobDescription::Command.new(self, command_options).execute
    end

    desc "annotate", "Generate job description annotations"
    long_desc <<~DESC, wrap: false
      Generate annotations for the job description showing how your experience matches.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo annotate -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo annotate
    DESC
    def annotate
      Commands::Annotate::Command.new(self, command_options).execute
    end

    desc "generate", "Generate everything: research, resume, cover letter, and website"
    long_desc <<~DESC, wrap: false
      Generate all application materials for an employer.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo generate -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo generate
    DESC
    def generate
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      # Validate required inputs
      begin
        Jojo::TemplateValidator.validate_required_file!(
          "inputs/resume_data.yml",
          "resume data"
        )
      rescue Jojo::TemplateValidator::MissingInputError => e
        say e.message, :red
        exit 1
      end

      # Warn about unchanged templates
      ["inputs/resume_data.yml"].each do |file|
        next unless File.exist?(file)

        result = Jojo::TemplateValidator.warn_if_unchanged(
          file,
          File.basename(file, ".*"),
          cli_instance: self
        )

        if result == :abort
          say "Customize your templates first, then run this command again.", :yellow
          exit 1
        end
      end

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating application materials for #{employer.company_name}...", :green

      # Generate research
      begin
        generator = Jojo::Generators::ResearchGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
        generator.generate

        say "✓ Research generated and saved", :green
        status_logger.log_step("Research Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete")
      rescue => e
        say "✗ Error generating research: #{e.message}", :red
        status_logger.log_step("Research Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate resume
      begin
        if File.exist?("inputs/resume_data.yml")
          generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
          generator.generate

          say "✓ Resume generated and saved", :green
          status_logger.log_step("Resume Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete")
        else
          say "⚠ Warning: Resume data not found, skipping resume generation", :yellow
          say "  Run 'jojo setup' or copy templates/resume_data.yml to inputs/ and customize it.", :yellow
        end
      rescue => e
        say "✗ Error generating resume: #{e.message}", :red
        status_logger.log_step("Resume Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate cover letter
      begin
        if File.exist?(employer.resume_path)
          generator = Jojo::Generators::CoverLetterGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
          generator.generate

          say "✓ Cover letter generated and saved", :green
          status_logger.log_step("Cover Letter Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete")
        else
          say "⚠ Warning: Resume not found, skipping cover letter generation", :yellow
        end
      rescue => e
        say "✗ Error generating cover letter: #{e.message}", :red
        status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate annotations
      begin
        generator = Jojo::Generators::AnnotationGenerator.new(employer, ai_client, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
        annotations = generator.generate

        say "✓ Generated #{annotations.length} job description annotations", :green
        status_logger.log_step("Annotation Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete",
          annotations_count: annotations.length)
      rescue => e
        say "✗ Error generating annotations: #{e.message}", :red
        status_logger.log_step("Annotation Generation", status: "failed", error: e.message)
        # Don't exit - annotations are optional, continue with website generation
      end

      # Generate FAQs
      begin
        if File.exist?(employer.resume_path)
          generator = Jojo::Generators::FaqGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
          faqs = generator.generate

          say "✓ Generated #{faqs.length} FAQs", :green
          status_logger.log_step("FAQ Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete",
            faq_count: faqs.length)
        else
          say "⚠ Warning: Resume not found, skipping FAQ generation", :yellow
        end
      rescue => e
        say "✗ Error generating FAQs: #{e.message}", :red
        status_logger.log_step("FAQ Generation", status: "failed", error: e.message)
        # Don't exit - FAQs are optional, continue with website generation
      end

      # Generate branding statement
      begin
        require_relative "generators/branding_generator"

        # Skip if branding exists and --overwrite not set
        if File.exist?(employer.branding_path) && !options[:overwrite]
          say "✓ Using existing branding statement", :green
        else
          generator = Jojo::Generators::BrandingGenerator.new(
            employer,
            ai_client,
            config: config,
            verbose: options[:verbose]
          )
          generator.generate

          say "✓ Branding statement generated and saved", :green
          status_logger.log_step("Branding Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete")
        end
      rescue => e
        say "✗ Error generating branding statement: #{e.message}", :red
        status_logger.log_step("Branding Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate website
      begin
        if File.exist?(employer.resume_path)
          generator = Jojo::Generators::WebsiteGenerator.new(
            employer,
            ai_client,
            config: config,
            template: options[:template],
            verbose: options[:verbose],
            overwrite_flag: options[:overwrite],
            cli_instance: self
          )
          generator.generate

          say "✓ Website generated and saved", :green
          status_logger.log_step("Website Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete",
            metadata: {template: options[:template]})
        else
          say "⚠ Warning: Resume not found, skipping website generation", :yellow
        end
      rescue => e
        say "✗ Error generating website: #{e.message}", :red
        status_logger.log_step("Website Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate PDFs
      begin
        generator = Jojo::PdfConverter.new(employer, verbose: options[:verbose])
        results = generator.generate_all

        if results[:generated].any?
          results[:generated].each do |doc_type|
            say "✓ #{doc_type.to_s.capitalize} PDF generated", :green
          end

          status_logger.log_step("PDF Generation",
            status: "complete",
            generated: results[:generated].length)
        else
          say "⚠ Warning: No PDFs generated (markdown files not found)", :yellow
        end
      rescue Jojo::PandocChecker::PandocNotFoundError => e
        say "⚠ Warning: Skipping PDF generation - #{e.message.lines.first.strip}", :yellow
        status_logger.log_step("PDF Generation", status: "skipped", reason: "Pandoc not installed")
      rescue => e
        say "⚠ Warning: PDF generation failed - #{e.message}", :yellow
        status_logger.log_step("PDF Generation", status: "failed", error: e.message)
        # Don't exit - PDFs are optional
      end

      say "\n✓ Generation complete!", :green
    end

    desc "research", "Generate company/role research only"
    long_desc <<~DESC, wrap: false
      Generate company and role research.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo research -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo research
    DESC
    def research
      Commands::Research::Command.new(self, command_options).execute
    end

    desc "resume", "Generate tailored resume only"
    long_desc <<~DESC, wrap: false
      Generate a tailored resume for a specific employer.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo resume -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo resume
    DESC
    def resume
      Commands::Resume::Command.new(self, command_options).execute
    end

    desc "cover_letter", "Generate cover letter only"
    long_desc <<~DESC, wrap: false
      Generate a cover letter for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo cover_letter -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo cover_letter
    DESC
    def cover_letter
      Commands::CoverLetter::Command.new(self, command_options).execute
    end

    desc "faq", "Generate FAQs only"
    long_desc <<~DESC, wrap: false
      Generate FAQs for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo faq -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo faq
    DESC
    def faq
      Commands::Faq::Command.new(self, command_options).execute
    end

    desc "branding", "Generate branding statement only"
    long_desc <<~DESC, wrap: false
      Generate a branding statement for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo branding -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo branding
    DESC
    def branding
      Commands::Branding::Command.new(self, command_options).execute
    end

    desc "website", "Generate website only"
    long_desc <<~DESC, wrap: false
      Generate a landing page website for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo website -s acme-corp-senior-dev
        jojo website -s acme-corp-senior-dev -t modern
        JOJO_EMPLOYER_SLUG=acme-corp jojo website
    DESC
    def website
      Commands::Website::Command.new(self, command_options).execute
    end

    desc "pdf", "Generate PDF versions of resume and cover letter"
    long_desc <<~DESC, wrap: false
      Generate PDF files from markdown resume and cover letter.
      Requires Pandoc to be installed.

      Examples:
        jojo pdf -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo pdf
    DESC
    def pdf
      Commands::Pdf::Command.new(self, command_options).execute
    end

    desc "test", "Run tests (default: --unit for fast feedback)"
    long_desc <<~DESC, wrap: false
      Run test suite with optional category filtering.

      CATEGORIES:
      --unit: Unit tests (fast, no external dependencies) [default]
      --integration: Integration tests (mocked external services)
      --service: Service tests (real API calls, may cost money)
      --standard: Standard Ruby style checks
      --all: All tests and checks (includes --standard)
      --no-service: Exclude service tests

      EXAMPLES:
      jojo test                      # Run unit tests only (fast)
      jojo test --standard           # Run Standard Ruby style checks
      jojo test --all                # Run all tests and style checks
      jojo test --all --no-service   # Run all tests/checks except service tests
      jojo test --standard --unit    # Run style checks then unit tests
      jojo test --service            # Run service tests (with confirmation)
    DESC
    method_option :unit, type: :boolean, desc: "Run unit tests (default)"
    method_option :integration, type: :boolean, desc: "Run integration tests"
    method_option :service, type: :boolean, desc: "Run service tests (may use real APIs)"
    method_option :standard, type: :boolean, desc: "Run Standard Ruby style checks"
    method_option :all, type: :boolean, desc: "Run all tests and checks"
    def test
      test_options = {
        unit: options[:unit],
        integration: options[:integration],
        service: options[:service],
        standard: options[:standard],
        all: options[:all],
        quiet: options[:quiet]
      }
      Commands::Test::Command.new(self, test_options).execute
    end

    desc "interactive", "Launch interactive dashboard mode"
    method_option :slug, type: :string, aliases: "-s", desc: "Application slug to start with"
    map "i" => :interactive
    def interactive
      Commands::Interactive::Command.new(self, command_options).execute
    end

    private

    def command_options
      {
        slug: options[:slug] || ENV["JOJO_EMPLOYER_SLUG"],
        verbose: options[:verbose],
        overwrite: options[:overwrite],
        quiet: options[:quiet]
      }
    end

    def resolve_slug
      slug = options[:slug] || ENV["JOJO_EMPLOYER_SLUG"]

      unless slug
        say "Error: No employer specified.", :red
        say "Provide --slug or set JOJO_EMPLOYER_SLUG environment variable.", :yellow
        say "\nExample:", :cyan
        say "  jojo #{invoked_command} --slug acme-corp-senior", :white
        say "  export JOJO_EMPLOYER_SLUG=acme-corp-senior && jojo #{invoked_command}", :white
        exit 1
      end

      slug
    end

    def invoked_command
      # Get the current command name for error messages

      @_invocations.keys.last.to_s
    rescue
      "command"
    end
  end
end
