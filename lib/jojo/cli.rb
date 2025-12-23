require 'erb'
require 'fileutils'
require_relative 'status_logger'
require_relative 'generators/research_generator'

module Jojo
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Run verbosely'
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

      say "Generating application materials for #{employer.name}...", :green

      employer.create_directory!
      say "✓ Created directory: #{employer.base_path}", :green

      # Process job description
      begin
        processor = Jojo::JobDescriptionProcessor.new(employer, ai_client, verbose: options[:verbose])
        result = processor.process(options[:job])

        say "✓ Job description processed and saved", :green

        # Log to status log
        log_to_status(employer, "Job description processed from: #{options[:job]}")
        log_to_status(employer, "Tokens used: #{ai_client.total_tokens_used}")

        say "\n✓ Phase 2 complete. Research generation coming in Phase 3.", :yellow
      rescue => e
        say "✗ Error processing job description: #{e.message}", :red
        exit 1
      end
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
      say "Resume generation coming in Phase 4", :yellow
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

    desc "test", "Run tests"
    def test
      exec 'ruby -Ilib:test -e \'Dir.glob("test/**/*_test.rb").each { |f| require f.sub(/^test\//, "") }\''
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

    def log_to_status(employer, message)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      log_entry = "**#{timestamp}**: #{message}\n\n"

      # Create or append to status log
      File.open(employer.status_log_path, 'a') do |f|
        f.write(log_entry)
      end
    end
  end
end
