require 'erb'
require 'fileutils'
require_relative 'status_logger'
require_relative 'generators/research_generator'
require_relative 'generators/resume_generator'

module Jojo
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Run verbosely'
    class_option :quiet, type: :boolean, aliases: '-q', desc: 'Suppress output, rely on exit code'
    class_option :employer, type: :string, aliases: '-e', desc: 'Employer name'
    class_option :job, type: :string, aliases: '-j', desc: 'Job description (file path or URL)'

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

    desc "generate", "Generate everything: research, resume, cover letter, and website"
    def generate
      validate_generate_options!

      config = Jojo::Config.new
      employer = Jojo::Employer.new(options[:employer])
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating application materials for #{employer.name}...", :green

      employer.create_directory!
      say "✓ Created directory: #{employer.base_path}", :green

      # Process job description
      begin
        processor = Jojo::JobDescriptionProcessor.new(employer, ai_client, verbose: options[:verbose])
        result = processor.process(options[:job])

        say "✓ Job description processed and saved", :green
        status_logger.log_step("Job Description Processing",
          tokens: ai_client.total_tokens_used,
          status: "complete"
        )
      rescue => e
        say "✗ Error processing job description: #{e.message}", :red
        status_logger.log_step("Job Description Processing", status: "failed", error: e.message)
        exit 1
      end

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

      say "\n✓ Phase 3 complete. Resume generation coming in Phase 4.", :yellow
    end

    desc "research", "Generate company/role research only"
    def research
      validate_generate_options!

      config = Jojo::Config.new
      employer = Jojo::Employer.new(options[:employer])
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating research for #{employer.name}...", :green

      # Ensure employer directory exists
      employer.create_directory! unless Dir.exist?(employer.base_path)

      # Check that job description has been processed
      unless File.exist?(employer.job_description_path)
        say "✗ Job description not found. Run 'generate' first or provide job description.", :red
        exit 1
      end

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
    def resume
      validate_generate_options!

      config = Jojo::Config.new
      employer = Jojo::Employer.new(options[:employer])
      ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
      status_logger = Jojo::StatusLogger.new(employer)

      say "Generating resume for #{employer.name}...", :green

      # Ensure employer directory exists
      employer.create_directory! unless Dir.exist?(employer.base_path)

      # Check that job description has been processed
      unless File.exist?(employer.job_description_path)
        say "✗ Job description not found. Run 'generate' first or provide job description.", :red
        exit 1
      end

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
    def cover_letter
      validate_generate_options!
      say "Cover letter generation coming in Phase 5", :yellow
    end

    desc "website", "Generate website only"
    def website
      validate_generate_options!
      say "Website generation coming in Phase 6", :yellow
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
      say "4. Run 'jojo generate -e \"Company Name\" -j job_description.txt' to generate materials"
    end

    def validate_generate_options!
      errors = []
      errors << "--employer is required" unless options[:employer]
      errors << "--job is required" unless options[:job]

      if errors.any?
        say "Error:", :red
        errors.each { |e| say "  #{e}", :red }
        exit 1
      end
    end
  end
end
