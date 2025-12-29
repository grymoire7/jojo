require 'erb'
require 'fileutils'
require_relative 'status_logger'
require_relative 'generators/research_generator'
require_relative 'generators/resume_generator'
require_relative 'generators/cover_letter_generator'
require_relative 'generators/website_generator'
require_relative 'generators/annotation_generator'

module Jojo
  class CLI < Thor
    include OverwriteHelper

    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Run verbosely'
    class_option :quiet, type: :boolean, aliases: '-q', desc: 'Suppress output, rely on exit code'
    class_option :slug, type: :string, aliases: '-s', desc: 'Employer slug (unique identifier)'
    class_option :template, type: :string, aliases: '-t', desc: 'Website template name (default: default)', default: 'default'
    class_option :overwrite, type: :boolean, banner: 'Overwrite existing files without prompting'
    
    def self.exit_on_failure?
      true
    end
    
    desc "version", "Show version"
    def version
      say "Jojo #{Jojo::VERSION}", :green
    end

    desc "setup", "Setup configuration"
    def setup
      errors = []

      say "Setting up Jojo...", :green

      # Steps will be added in next tasks
      handle_config_yml(errors)
      handle_env_file(errors)
      ensure_inputs_directory

      report_results(errors)
    end

    desc "new", "Create employer workspace with job description"
    long_desc <<~DESC
      Create a new employer workspace and process the job description.
      This command initializes all artifacts needed for generating application materials.

      Examples:
        jojo new -s acme-corp-senior-dev -j job_description.txt
        jojo new -s bigco-principal -j https://careers.bigco.com/jobs/123
        jojo new -s acme-corp-senior-dev -j job.txt --overwrite
    DESC
    method_option :slug, type: :string, aliases: '-s', required: true, desc: 'Unique employer identifier'
    method_option :job, type: :string, aliases: '-j', required: true, desc: 'Job description (file path or URL)'
    def new
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
    long_desc <<~DESC
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
        generator = Jojo::Generators::AnnotationGenerator.new(employer, ai_client, verbose: options[:verbose])
        annotations = generator.generate

        say "✓ Generated #{annotations.length} annotations", :green
        say "  Saved to: #{employer.job_description_annotations_path}", :green
      rescue => e
        say "✗ Error generating annotations: #{e.message}", :red
        exit 1
      end
    end

    desc "generate", "Generate everything: research, resume, cover letter, and website"
    long_desc <<~DESC
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

      config = Jojo::Config.new
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating application materials for #{employer.company_name}...", :green

      # Generate research
      begin
        generator = Jojo::Generators::ResearchGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
        generator.generate

        say "✓ Research generated and saved", :green
        status_logger.log_step("Research Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete"
        )
      rescue => e
        say "✗ Error generating research: #{e.message}", :red
        status_logger.log_step("Research Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate resume
      begin
        unless File.exist?('inputs/generic_resume.md')
          say "⚠ Warning: Generic resume not found, skipping resume generation", :yellow
          say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
        else
          generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
          generator.generate

          say "✓ Resume generated and saved", :green
          status_logger.log_step("Resume Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete"
          )
        end
      rescue => e
        say "✗ Error generating resume: #{e.message}", :red
        status_logger.log_step("Resume Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate cover letter
      begin
        unless File.exist?(employer.resume_path)
          say "⚠ Warning: Resume not found, skipping cover letter generation", :yellow
        else
          generator = Jojo::Generators::CoverLetterGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
          generator.generate

          say "✓ Cover letter generated and saved", :green
          status_logger.log_step("Cover Letter Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete"
          )
        end
      rescue => e
        say "✗ Error generating cover letter: #{e.message}", :red
        status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
        exit 1
      end

      # Generate annotations
      begin
        generator = Jojo::Generators::AnnotationGenerator.new(employer, ai_client, verbose: options[:verbose])
        annotations = generator.generate

        say "✓ Generated #{annotations.length} job description annotations", :green
        status_logger.log_step("Annotation Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete",
          annotations_count: annotations.length
        )
      rescue => e
        say "✗ Error generating annotations: #{e.message}", :red
        status_logger.log_step("Annotation Generation", status: "failed", error: e.message)
        # Don't exit - annotations are optional, continue with website generation
      end

      # Generate website
      begin
        unless File.exist?(employer.resume_path)
          say "⚠ Warning: Resume not found, skipping website generation", :yellow
        else
          generator = Jojo::Generators::WebsiteGenerator.new(
            employer,
            ai_client,
            config: config,
            template: options[:template],
            verbose: options[:verbose]
          )
          generator.generate

          say "✓ Website generated and saved", :green
          status_logger.log_step("Website Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete",
            metadata: { template: options[:template] }
          )
        end
      rescue => e
        say "✗ Error generating website: #{e.message}", :red
        status_logger.log_step("Website Generation", status: "failed", error: e.message)
        exit 1
      end

      say "\n✓ Generation complete!", :green
    end

    desc "research", "Generate company/role research only"
    long_desc <<~DESC
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
        generator = Jojo::Generators::ResearchGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
        research = generator.generate

        say "✓ Research generated and saved to #{employer.research_path}", :green

        status_logger.log_step("Research Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete"
        )

        say "\n✓ Research complete!", :green
      rescue => e
        say "✗ Error generating research: #{e.message}", :red
        status_logger.log_step("Research Generation", status: "failed", error: e.message)
        exit 1
      end
    end

    desc "resume", "Generate tailored resume only"
    long_desc <<~DESC
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
      unless File.exist?('inputs/generic_resume.md')
        say "✗ Generic resume not found at inputs/generic_resume.md", :red
        say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
        exit 1
      end

      begin
        generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
        resume = generator.generate

        say "✓ Resume generated and saved to #{employer.resume_path}", :green

        status_logger.log_step("Resume Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete"
        )

        say "\n✓ Resume complete!", :green
      rescue => e
        say "✗ Error generating resume: #{e.message}", :red
        status_logger.log_step("Resume Generation", status: "failed", error: e.message)
        exit 1
      end
    end

    desc "cover_letter", "Generate cover letter only"
    long_desc <<~DESC
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
      unless File.exist?('inputs/generic_resume.md')
        say "✗ Generic resume not found at inputs/generic_resume.md", :red
        say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
        exit 1
      end

      # Warn if research missing (optional)
      unless File.exist?(employer.research_path)
        say "⚠ Warning: Research not found. Cover letter will be less targeted.", :yellow
      end

      begin
        generator = Jojo::Generators::CoverLetterGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
        cover_letter = generator.generate

        say "✓ Cover letter generated and saved to #{employer.cover_letter_path}", :green

        status_logger.log_step("Cover Letter Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete"
        )

        say "\n✓ Cover letter complete!", :green
      rescue => e
        say "✗ Error generating cover letter: #{e.message}", :red
        status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
        exit 1
      end
    end

    desc "website", "Generate website only"
    long_desc <<~DESC
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
          verbose: options[:verbose]
        )
        website = generator.generate

        say "✓ Website generated and saved to #{employer.index_html_path}", :green

        status_logger.log_step("Website Generation",
          tokens: ai_client.total_tokens_used,
          status: "complete",
          metadata: { template: options[:template] }
        )

        say "\n✓ Website complete!", :green
      rescue => e
        say "✗ Error generating website: #{e.message}", :red
        status_logger.log_step("Website Generation", status: "failed", error: e.message)
        exit 1
      end
    end

    desc "test", "Run tests (default: --unit for fast feedback)"
    long_desc <<~DESC
      Run test suite with optional category filtering.

      Categories:
        --unit         Unit tests (fast, no external dependencies) [default]
        --integration  Integration tests (mocked external services)
        --service      Service tests (real API calls, may cost money)
        --all          All test categories

      Examples:
        jojo test                        # Run unit tests only (fast)
        jojo test --all                  # Run all tests
        jojo test --unit --integration   # Run unit and integration tests
        jojo test --service              # Run service tests (with confirmation)
        jojo test -q                     # Quiet mode, check exit code
    DESC
    method_option :unit, type: :boolean, desc: 'Run unit tests (default)'
    method_option :integration, type: :boolean, desc: 'Run integration tests'
    method_option :service, type: :boolean, desc: 'Run service tests (may use real APIs)'
    method_option :all, type: :boolean, desc: 'Run all tests'
    def test
      # Determine which test categories to run
      categories = []

      if options[:all]
        categories = ['unit', 'integration', 'service']
      else
        # Collect specified categories
        categories << 'unit' if options[:unit]
        categories << 'integration' if options[:integration]
        categories << 'service' if options[:service]

        # Default to unit tests if no flags specified
        categories = ['unit'] if categories.empty?
      end

      # Safety confirmation for service tests
      if categories.include?('service') && !ENV['SKIP_SERVICE_CONFIRMATION']
        unless yes?("⚠️  Run service tests? These may cost money and require API keys. Continue? (y/n)")
          # Remove service from categories if user declines
          categories.delete('service')
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
      pattern_glob = patterns.join(',')
      test_cmd = "ruby -Ilib:test -e 'Dir.glob(\"{#{pattern_glob}}\").each { |f| require f.sub(/^test\\//, \"\") }'"

      if options[:quiet]
        exec "#{test_cmd} > /dev/null 2>&1"
      else
        exec test_cmd
      end
    end

    private

    def resolve_slug
      slug = options[:slug] || ENV['JOJO_EMPLOYER_SLUG']

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
      @_invocations.keys.last.to_s rescue 'command'
    end

    def handle_config_yml(errors)
      if File.exist?('config.yml')
        if yes?("config.yml already exists. Overwrite?")
          create_config_yml(errors)
        else
          say "⊘ Skipped config.yml", :yellow
        end
      else
        create_config_yml(errors)
      end
    end

    def create_config_yml(errors)
      seeker_name = ask("Your name:")

      if seeker_name.strip.empty?
        errors << "Name is required for config.yml"
        return
      end

      base_url = ask("Your website base URL (e.g., https://yourname.com):")

      if base_url.strip.empty?
        errors << "Base URL is required for config.yml"
        return
      end

      begin
        template = ERB.new(File.read('templates/config.yml.erb'))
        File.write('config.yml', template.result(binding))
        say "✓ Created config.yml", :green
      rescue => e
        errors << "Failed to create config.yml: #{e.message}"
      end
    end

    def handle_env_file(errors)
      if File.exist?('.env')
        say "✓ .env already exists", :green
      else
        create_env_file(errors)
      end
    end

    def create_env_file(errors)
      api_key = ask("Anthropic API key:")

      if api_key.strip.empty?
        errors << "API key is required for .env"
        return
      end

      begin
        File.write('.env', "ANTHROPIC_API_KEY=#{api_key}\n")
        say "✓ Created .env", :green
      rescue => e
        errors << "Failed to create .env: #{e.message}"
      end
    end

    def ensure_inputs_directory
      FileUtils.mkdir_p('inputs') unless Dir.exist?('inputs')
      say "✓ inputs/ directory ready", :green
    end

    def report_results(errors)
      if errors.any?
        say "\nSetup completed with errors:", :red
        errors.each { |e| say "  - #{e}", :red }
      end

      display_next_steps

      exit 1 if errors.any?
    end

    def display_next_steps
      say "\nNext steps:", :cyan
      say "1. Copy templates/generic_resume.md to inputs/generic_resume.md"
      say "2. Edit inputs/generic_resume.md with your actual work history"
      say "3. (Optional) Copy templates/recommendations.md to inputs/recommendations.md"
      say "4. Run 'jojo new -s employer-slug -j job_description.txt' to create workspace"
      say "5. Run 'jojo generate -s employer-slug' to generate materials"
    end
  end
end
