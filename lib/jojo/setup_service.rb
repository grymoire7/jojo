require 'fileutils'
require 'erb'

module Jojo
  class SetupService
    def initialize(cli_instance:, force: false)
      @cli = cli_instance
      @force = force
      @created_files = []
      @skipped_files = []
    end

    def run
      @cli.say "Setting up Jojo...", :green
      @cli.say ""

      warn_if_force_mode
      setup_api_configuration
      setup_personal_configuration
      setup_input_files
      show_summary
    end

    private

    def warn_if_force_mode
      return unless @force

      @cli.say "⚠ WARNING: --force will overwrite existing configuration files!", :yellow
      @cli.say "  This will replace: .env, config.yml, and all inputs/ files", :yellow

      unless @cli.yes?("Continue?")
        exit 1
      end
    end

    def setup_api_configuration
      if File.exist?('.env') && !@force
        @cli.say "✓ .env already exists (skipped)", :green
        @skipped_files << '.env'
        return
      end

      if @force && File.exist?('.env')
        @cli.say "⚠ Recreating .env (--force mode)", :yellow
      else
        @cli.say "Let's configure your API access.", :green
      end

      api_key = @cli.ask("Anthropic API key:")

      if api_key.strip.empty?
        @cli.say "✗ API key is required", :red
        exit 1
      end

      # Optional: Validate API key format
      if !api_key.start_with?('sk-ant-')
        @cli.say "⚠ Warning: This doesn't look like a valid Anthropic API key (should start with 'sk-ant-')", :yellow
        unless @cli.yes?("Continue anyway?")
          exit 1
        end
      end

      File.write('.env', "ANTHROPIC_API_KEY=#{api_key}\n")
      @cli.say "✓ Created .env", :green
      @created_files << '.env'
    end

    def setup_personal_configuration
      if File.exist?('config.yml') && !@force
        @cli.say "✓ config.yml already exists (skipped)", :green
        @skipped_files << 'config.yml'
        return
      end

      seeker_name = @cli.ask("Your name:")
      if seeker_name.strip.empty?
        @cli.say "✗ Name is required", :red
        exit 1
      end

      base_url = @cli.ask("Your website base URL (e.g., https://yourname.com):")
      if base_url.strip.empty?
        @cli.say "✗ Base URL is required", :red
        exit 1
      end

      begin
        template = ERB.new(File.read('templates/config.yml.erb'))
        File.write('config.yml', template.result(binding))
        @cli.say "✓ Created config.yml", :green
        @created_files << 'config.yml'
      rescue => e
        @cli.say "✗ Failed to create config.yml: #{e.message}", :red
        exit 1
      end
    end

    def setup_input_files
      FileUtils.mkdir_p('inputs') unless Dir.exist?('inputs')
      @cli.say "✓ inputs/ directory ready", :green
      @cli.say ""
      @cli.say "Setting up your profile templates...", :green

      input_files = {
        'generic_resume.md' => '(customize this file)',
        'recommendations.md' => '(optional - customize or delete)',
        'projects.yml' => '(optional - customize or delete)'
      }

      input_files.each do |filename, description|
        target_path = File.join('inputs', filename)
        source_path = File.join('templates', filename)

        if File.exist?(target_path) && !@force
          @cli.say "✓ inputs/#{filename} already exists (skipped)", :green
          @skipped_files << "inputs/#{filename}"
          next
        end

        unless File.exist?(source_path)
          @cli.say "✗ Template file #{source_path} not found", :red
          @cli.say "  This may indicate a corrupted installation.", :yellow
          exit 1
        end

        FileUtils.cp(source_path, target_path)
        @cli.say "✓ Created inputs/#{filename} #{description}", :green
        @created_files << "inputs/#{filename}"
      end
    end

    def show_summary
      @cli.say ""
      @cli.say "Setup complete!", :green
      @cli.say ""

      if @created_files.any?
        @cli.say "Created:"
        file_descriptions = {
          '.env' => 'API configuration',
          'config.yml' => 'Personal preferences',
          'inputs/generic_resume.md' => 'Your work history template',
          'inputs/recommendations.md' => 'Optional recommendations',
          'inputs/projects.yml' => 'Optional portfolio projects'
        }

        @created_files.each do |file|
          desc = file_descriptions[file] || 'Configuration file'
          @cli.say "  • #{file} - #{desc}"
        end
        @cli.say ""
      end

      @cli.say "Next steps:", :cyan
      @cli.say "  1. Customize inputs/generic_resume.md with your actual experience"
      @cli.say "  2. Edit or delete inputs/recommendations.md and inputs/projects.yml if not needed"
      @cli.say "  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"
      @cli.say ""
      @cli.say "💡 Tip: Delete the first comment line in each file after customizing."
    end
  end
end
