# lib/jojo/commands/new/command.rb
require_relative "../base"
require_relative "../../template_validator"

module Jojo
  module Commands
    module New
      class Command < Base
        def execute
          validate_inputs!

          if File.exist?(application.base_path)
            say "Application '#{slug}' already exists.", :yellow
            exit 1
          end

          FileUtils.mkdir_p(application.base_path)
          say "Created application workspace: #{application.base_path}", :green
          say "\nNext step:", :cyan
          say "  jojo job_description -s #{slug} -j <job_file_or_url>", :white
        end

        private

        def validate_inputs!
          begin
            Jojo::TemplateValidator.validate_required_file!(
              "inputs/resume_data.yml",
              "resume data"
            )
          rescue Jojo::TemplateValidator::MissingInputError => e
            say e.message, :red
            exit 1
          end

          # Warn if resume data hasn't been customized
          result = Jojo::TemplateValidator.warn_if_unchanged(
            "inputs/resume_data.yml",
            "resume data",
            cli_instance: cli
          )

          if result == :abort
            say "Setup your inputs first, then run this command again.", :yellow
            exit 1
          end
        end
      end
    end
  end
end
