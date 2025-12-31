require "erb"
require "fileutils"
require_relative "status_logger"
require_relative "setup_service"
require_relative "template_validator"
require_relative "generators/research_generator"
require_relative "generators/resume_generator"
require_relative "generators/cover_letter_generator"
require_relative "generators/website_generator"
require_relative "generators/annotation_generator"
require_relative "pdf_generator"

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

    desc "version", "Show version"
    def version
      say "Jojo #{Jojo::VERSION}", :green
    end

    desc "setup", "Setup configuration"
    method_option :force, type: :boolean, desc: "Overwrite existing files"
    def setup
      Jojo::SetupService.new(
        cli_instance: self,
        force: options[:force]
      ).run
    rescue SystemExit
      # Allow clean exit from service
      raise
    rescue => e
      say "✗ Setup failed: #{e.message}", :red
      exit 1
    end

    desc "new", "Create employer workspace with job description"
    long_desc <<~DESC, wrap: false
      Create a new employer workspace and process the job description.
      This command initializes all artifacts needed for generating application materials.

      Examples:
        jojo new -s acme-corp-senior-dev -j job_description.txt
        jojo new -s bigco-principal -j https://careers.bigco.com/jobs/123
        jojo new -s acme-corp-senior-dev -j job.txt --overwrite
    DESC
    method_option :slug, type: :string, aliases: "-s", required: true, desc: "Unique employer identifier"
    method_option :job, type: :string, aliases: "-j", required: true, desc: "Job description (file path or URL)"
    def new
      # Validate required inputs exist before creating employer
      begin
        Jojo::TemplateValidator.validate_required_file!(
          "inputs/generic_resume.md",
          "generic resume"
        )
      rescue Jojo::TemplateValidator::MissingInputError => e
        say e.message, :red
        exit 1
      end

      # Warn if generic resume hasn't been customized
      result = Jojo::TemplateValidator.warn_if_unchanged(
        "inputs/generic_resume.md",
        "generic resume",
        cli_instance: self
      )

      if result == :abort
        say "Setup your inputs first, then run this command again.", :yellow
        exit 1
      end

      config = Jojo::Config.new
      employer = Jojo::Employer.new(options[:slug])
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])

      say "Creating employer workspace: #{options[:slug]}", :green

      # Create artifacts
      begin
        employer.create_artifacts(options[:job], ai_client, overwrite_flag: options[:overwrite], cli_instance: self, verbose: options[:verbose])

        say "✓ Created employer directory: #{employer.base_path}", :green
        say "✓ Job description processed and saved", :green
        say "✓ Job details extracted and saved", :green
        say "\nNext steps:", :cyan
        say "  jojo research -s #{options[:slug]}", :white
        say "  jojo resume -s #{options[:slug]}", :white
        say "  jojo cover_letter -s #{options[:slug]}", :white
      rescue => e
        say "✗ Error creating employer workspace: #{e.message}", :red
        exit 1
      end
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
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])

      say "Generating annotations for #{employer.company_name}...", :green

      begin
        generator = Jojo::Generators::AnnotationGenerator.new(employer, ai_client, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
        annotations = generator.generate

        say "✓ Generated #{annotations.length} annotations", :green
        say "  Saved to: #{employer.job_description_annotations_path}", :green
      rescue => e
        say "✗ Error generating annotations: #{e.message}", :red
        exit 1
      end
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
          "inputs/generic_resume.md",
          "generic resume"
        )
      rescue Jojo::TemplateValidator::MissingInputError => e
        say e.message, :red
        exit 1
      end

      # Warn about unchanged templates
      ["inputs/generic_resume.md", "inputs/recommendations.md", "inputs/projects.yml"].each do |file|
        next unless File.exist?(file)

        result = Jojo::TemplateValidator.warn_if_unchanged(
          file,
          File.basename(file),
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
        if File.exist?("inputs/generic_resume.md")
          generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
          generator.generate

          say "✓ Resume generated and saved", :green
          status_logger.log_step("Resume Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete")
        else
          say "⚠ Warning: Generic resume not found, skipping resume generation", :yellow
          say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
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
        generator = Jojo::PdfGenerator.new(employer, verbose: options[:verbose])
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
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating research for #{employer.company_name}...", :green

      begin
        generator = Jojo::Generators::ResearchGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
        generator.generate

        say "✓ Research generated and saved to #{employer.research_path}", :green

        status_logger.log_step("Research Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete")

        say "\n✓ Research complete!", :green
      rescue => e
        say "✗ Error generating research: #{e.message}", :red
        status_logger.log_step("Research Generation", status: "failed", error: e.message)
        exit 1
      end
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
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating resume for #{employer.company_name}...", :green

      # Check that research has been generated
      unless File.exist?(employer.research_path)
        say "⚠ Warning: Research not found. Resume will be less targeted.", :yellow
      end

      # Check that generic resume exists
      unless File.exist?("inputs/generic_resume.md")
        say "✗ Generic resume not found at inputs/generic_resume.md", :red
        say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
        exit 1
      end

      begin
        generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
        generator.generate

        say "✓ Resume generated and saved to #{employer.resume_path}", :green

        status_logger.log_step("Resume Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete")

        say "\n✓ Resume complete!", :green
      rescue => e
        say "✗ Error generating resume: #{e.message}", :red
        status_logger.log_step("Resume Generation", status: "failed", error: e.message)
        exit 1
      end
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
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating cover letter for #{employer.company_name}...", :green

      # Check tailored resume exists (REQUIRED)
      unless File.exist?(employer.resume_path)
        say "✗ Tailored resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
        exit 1
      end

      # Check generic resume exists (REQUIRED)
      unless File.exist?("inputs/generic_resume.md")
        say "✗ Generic resume not found at inputs/generic_resume.md", :red
        say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
        exit 1
      end

      # Warn if research missing (optional)
      unless File.exist?(employer.research_path)
        say "⚠ Warning: Research not found. Cover letter will be less targeted.", :yellow
      end

      begin
        generator = Jojo::Generators::CoverLetterGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
        generator.generate

        say "✓ Cover letter generated and saved to #{employer.cover_letter_path}", :green

        status_logger.log_step("Cover Letter Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete")

        say "\n✓ Cover letter complete!", :green
      rescue => e
        say "✗ Error generating cover letter: #{e.message}", :red
        status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
        exit 1
      end
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
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating website for #{employer.company_name}...", :green

      # Check that resume has been generated (REQUIRED)
      unless File.exist?(employer.resume_path)
        say "✗ Resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
        exit 1
      end

      # Warn if research missing (optional)
      unless File.exist?(employer.research_path)
        say "⚠ Warning: Research not found. Website will be less targeted.", :yellow
      end

      begin
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

        say "✓ Website generated and saved to #{employer.index_html_path}", :green

        status_logger.log_step("Website Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete",
          metadata: {template: options[:template]})

        say "\n✓ Website complete!", :green
      rescue => e
        say "✗ Error generating website: #{e.message}", :red
        status_logger.log_step("Website Generation", status: "failed", error: e.message)
        exit 1
      end
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
      slug = resolve_slug
      employer = Jojo::Employer.new(slug)

      unless employer.artifacts_exist?
        say "✗ Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
        exit 1
      end

      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating PDFs for #{employer.company_name}...", :green

      begin
        generator = Jojo::PdfGenerator.new(employer, verbose: options[:verbose])
        results = generator.generate_all

        # Report what was generated
        results[:generated].each do |doc_type|
          say "✓ #{doc_type.to_s.capitalize} PDF generated", :green
        end

        # Report what was skipped
        results[:skipped].each do |doc_type|
          say "⚠ Skipped #{doc_type}: markdown file not found", :yellow
        end

        if results[:generated].any?
          status_logger.log_step("PDF Generation",
            status: "complete",
            generated: results[:generated].length)
          say "\n✓ PDF generation complete!", :green
        else
          say "\n⚠ No PDFs generated. Generate resume and cover letter first.", :yellow
          exit 1
        end
      rescue Jojo::PandocChecker::PandocNotFoundError => e
        say "✗ #{e.message}", :red
        status_logger.log_step("PDF Generation", status: "failed", error: "Pandoc not installed")
        exit 1
      rescue => e
        say "✗ Error generating PDFs: #{e.message}", :red
        status_logger.log_step("PDF Generation", status: "failed", error: e.message)
        exit 1
      end
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
      # Validate unsupported Thor auto-generated flags
      unsupported_flags = []
      unsupported_flags << "--no-unit or --skip-unit" if options[:unit] == false
      unsupported_flags << "--no-integration or --skip-integration" if options[:integration] == false
      unsupported_flags << "--no-all or --skip-all" if options[:all] == false
      unsupported_flags << "--no-standard or --skip-standard" if options[:standard] == false

      if unsupported_flags.any?
        say "✗ Unsupported option(s): #{unsupported_flags.join(", ")}", :red
        say "  Only --no-service (to exclude service tests from --all) is supported.", :yellow
        exit 1
      end

      # Handle --standard flag specially (runs before tests)
      run_standard = options[:standard] || options[:all]

      if run_standard
        say "Running Standard Ruby style checks...", :cyan
        system("bundle exec standardrb")
        standard_exit_code = $?.exitstatus

        if standard_exit_code != 0
          say "✗ Standard Ruby style checks failed", :red
          exit standard_exit_code
        end
        say "✓ Standard Ruby style checks passed", :green
      end

      # If only --standard was specified, exit after running it
      if options[:standard] && !options[:all] && !options[:unit] && !options[:integration] && !options[:service]
        exit 0
      end

      # Determine which test categories to run
      categories = []

      if options[:all]
        categories = ["unit", "integration", "service"]
      else
        # Collect specified categories
        categories << "unit" if options[:unit]
        categories << "integration" if options[:integration]
        categories << "service" if options[:service]

        # Default to unit tests if no flags specified (and --standard wasn't the only thing)
        categories = ["unit"] if categories.empty?
      end

      # Exclude service tests if --no-service is specified (Thor's auto-generated flag)
      categories.delete("service") if options[:service] == false

      # Safety confirmation for service tests
      if categories.include?("service") && !ENV["SKIP_SERVICE_CONFIRMATION"]
        unless yes?("⚠️  Run service tests? These may cost money and require API keys. Continue? (y/n)")
          # Remove service from categories if user declines
          categories.delete("service")
          # Exit if service was the only category requested
          if categories.empty?
            say "No tests to run.", :yellow
            exit 0
          end
        end
      end

      # Build test file patterns
      patterns = categories.map { |cat| "test/#{cat}/**/*_test.rb" }

      # Build and execute test command
      pattern_glob = patterns.join(",")
      test_cmd = "ruby -Ilib:test -e 'Dir.glob(\"{#{pattern_glob}}\").each { |f| require f.sub(/^test\\//, \"\") }'"

      if options[:quiet]
        exec "#{test_cmd} > /dev/null 2>&1"
      else
        exec test_cmd
      end
    end

    private

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
