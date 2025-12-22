require 'erb'
require 'fileutils'

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
      # TODO: implement
    end

    def ensure_inputs_directory
      # TODO: implement
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
  end
end
