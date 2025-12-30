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

      setup_api_configuration
      setup_personal_configuration
      setup_input_files
      show_summary
    end

    private

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
      # Placeholder
    end

    def setup_input_files
      # Placeholder
    end

    def show_summary
      # Placeholder
    end
  end
end
