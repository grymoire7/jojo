require "fileutils"
require "erb"
require "tty-prompt"
require_relative "provider_helper"

module Jojo
  class SetupService
    def initialize(cli_instance:, prompt: nil, force: false)
      @cli = cli_instance
      @prompt = prompt || TTY::Prompt.new
      @force = force
      @created_files = []
      @skipped_files = []
    end

    def run
      @cli.say "Setting up Jojo...", :green
      @cli.say ""

      warn_if_force_mode
      validate_configuration_completeness
      setup_api_configuration
      setup_search_configuration
      write_env_file
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

    def validate_configuration_completeness
      return if @force  # Force mode bypasses validation

      env_exists = File.exist?(".env")
      config_exists = File.exist?("config.yml")

      # XOR check: fail if exactly one exists
      if env_exists && !config_exists
        @cli.say "✗ Partial configuration detected", :red
        @cli.say "  Found: .env", :yellow
        @cli.say "  Missing: config.yml", :yellow
        @cli.say "", :yellow
        @cli.say "Options:", :yellow
        @cli.say "  • Run 'jojo setup --force' to recreate all configuration", :yellow
        @cli.say "  • Manually create config.yml to match your existing .env setup", :yellow
        exit 1
      elsif config_exists && !env_exists
        @cli.say "✗ Partial configuration detected", :red
        @cli.say "  Found: config.yml", :yellow
        @cli.say "  Missing: .env", :yellow
        @cli.say "", :yellow
        @cli.say "Options:", :yellow
        @cli.say "  • Run 'jojo setup --force' to recreate all configuration", :yellow
        @cli.say "  • Manually create .env with your API keys", :yellow
        exit 1
      end

      # Both exist or neither exists - normal flow
    end

    def setup_api_configuration
      if File.exist?(".env") && !@force
        @cli.say "✓ .env already exists (skipped)", :green
        @skipped_files << ".env"

        # Extract provider from existing .env file
        env_content = File.read(".env")
        env_content.each_line do |line|
          # Match provider-specific API key pattern (e.g., ANTHROPIC_API_KEY=...)
          if line =~ /^([A-Z_]+)_API_KEY=/
            env_var_name = $1
            # Convert env var to provider slug (e.g., ANTHROPIC → anthropic)
            provider_slug = env_var_name.downcase

            # Verify this is a valid provider
            if ProviderHelper.available_providers.include?(provider_slug)
              @provider_slug = provider_slug
              break
            end
          end
        end

        return
      end

      if @force && File.exist?(".env")
        @cli.say "⚠ Recreating .env (--force mode)", :yellow
      else
        @cli.say "Let's configure your API access.", :green
      end

      # Prompt for provider
      providers = ProviderHelper.available_providers
      @cli.say ""
      provider_slug = @prompt.select("Which LLM provider?", providers, {per_page: 15})

      # Get dynamic env var name
      @llm_env_var_name = ProviderHelper.provider_env_var_name(provider_slug)
      provider_display_name = provider_slug.capitalize

      # Prompt for API key
      @llm_api_key = @cli.ask("#{provider_display_name} API key:")

      if @llm_api_key.strip.empty?
        @cli.say "✗ API key is required", :red
        exit 1
      end

      # Store provider for use in setup_personal_configuration
      @provider_slug = provider_slug
      @llm_provider_slug = provider_slug
    end

    def setup_search_configuration
      @cli.say ""
      configure_search = @prompt.yes?("Configure web search for company research? (requires Tavily or Serper API)")

      unless configure_search
        @search_provider_slug = nil
        return
      end

      # Select provider
      @search_provider_slug = @prompt.select(
        "Which search provider?",
        ["tavily", "serper"],
        {per_page: 5}
      )

      # Get env var name
      @search_env_var_name = "#{@search_provider_slug.upcase}_API_KEY"
      provider_display_name = @search_provider_slug.capitalize

      # Prompt for API key with loop for empty validation
      loop do
        @search_api_key = @cli.ask("#{provider_display_name} API key:")
        break unless @search_api_key.strip.empty?
        @cli.say "⚠ API key cannot be empty. Please try again.", :yellow
      end
    end

    def write_env_file
      # Skip if .env was already handled
      return if @skipped_files.include?(".env")

      # Set local variables for template binding
      llm_env_var_name = @llm_env_var_name
      llm_api_key = @llm_api_key
      search_provider_slug = @search_provider_slug
      search_env_var_name = @search_env_var_name
      search_api_key = @search_api_key

      # Render .env from template
      begin
        template = ERB.new(File.read("templates/.env.erb"))
        File.write(".env", template.result(binding))
        @cli.say "✓ Created .env", :green
        @created_files << ".env"
      rescue => e
        @cli.say "✗ Failed to create .env: #{e.message}", :red
        exit 1
      end
    end

    def setup_personal_configuration
      if File.exist?("config.yml") && !@force
        @cli.say "✓ config.yml already exists (skipped)", :green
        @skipped_files << "config.yml"
        return
      end

      # Basic info
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

      # Model selection
      available_models = ProviderHelper.available_models(@provider_slug)

      if available_models.empty?
        @cli.say "✗ No models found for provider: #{@provider_slug}", :red
        exit 1
      end

      @cli.say ""
      reasoning_model = @prompt.select(
        "Which model for reasoning tasks (company research, resume tailoring)?",
        available_models,
        {per_page: 15}
      )

      @cli.say ""
      text_generation_model = @prompt.select(
        "Which model for text generation tasks (faster, simpler)?",
        available_models,
        {per_page: 15}
      )

      # Set provider variables for config template
      reasoning_provider = @provider_slug
      text_generation_provider = @provider_slug
      search_provider_slug = @search_provider_slug

      begin
        template = ERB.new(File.read("templates/config.yml.erb"))
        File.write("config.yml", template.result(binding))
        @cli.say "✓ Created config.yml", :green
        @created_files << "config.yml"
      rescue => e
        @cli.say "✗ Failed to create config.yml: #{e.message}", :red
        exit 1
      end
    end

    def setup_input_files
      FileUtils.mkdir_p("inputs") unless Dir.exist?("inputs")
      FileUtils.mkdir_p("inputs/templates") unless Dir.exist?("inputs/templates")
      @cli.say "✓ inputs/ directory ready", :green
      @cli.say ""
      @cli.say "Setting up your profile templates...", :green

      input_files = {
        "resume_data.yml" => "(customize with your experience)",
        "recommendations.md" => "(optional - customize or delete)"
      }

      input_files.each do |filename, description|
        target_path = File.join("inputs", filename)
        source_path = File.join("templates", filename)

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

      # Copy resume template to inputs/templates/
      template_file = "default_resume.md.erb"
      target_template_path = File.join("inputs", "templates", template_file)
      source_template_path = File.join("templates", template_file)

      if File.exist?(target_template_path) && !@force
        @cli.say "✓ inputs/templates/#{template_file} already exists (skipped)", :green
        @skipped_files << "inputs/templates/#{template_file}"
      else
        unless File.exist?(source_template_path)
          @cli.say "✗ Template file #{source_template_path} not found", :red
          @cli.say "  This may indicate a corrupted installation.", :yellow
          exit 1
        end

        FileUtils.cp(source_template_path, target_template_path)
        @cli.say "✓ Created inputs/templates/#{template_file} (resume ERB template)", :green
        @created_files << "inputs/templates/#{template_file}"
      end
    end

    def show_summary
      @cli.say ""
      @cli.say "Setup complete!", :green
      @cli.say ""

      if @created_files.any?
        @cli.say "Created:"
        file_descriptions = {
          ".env" => "API configuration",
          "config.yml" => "Personal preferences and permissions",
          "inputs/resume_data.yml" => "Structured resume data (recommended)",
          "inputs/recommendations.md" => "Optional recommendations",
          "inputs/templates/default_resume.md.erb" => "Resume rendering template"
        }

        @created_files.each do |file|
          desc = file_descriptions[file] || "Configuration file"
          @cli.say "  • #{file} - #{desc}"
        end
        @cli.say ""
      end

      @cli.say "Next steps:", :cyan
      @cli.say "  1. Customize inputs/resume_data.yml with your experience (structured format)"
      @cli.say "  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"
      @cli.say "  3. Edit or delete inputs/recommendations.md if not needed"
      @cli.say "  4. Run 'jojo new -s <slug> -j <job-file>' to start your first application"
      @cli.say ""
      @cli.say "💡 Tip: The config.yml file contains resume_data.permissions to control curation."
    end
  end
end
