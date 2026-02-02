# lib/jojo/commands/setup/command.rb
require_relative "../base"
require_relative "../../setup_service"

module Jojo
  module Commands
    module Setup
      class Command < Base
        def execute
          SetupService.new(
            cli_instance: cli,
            overwrite: overwrite?
          ).run
        rescue SystemExit
          # Allow clean exit from service
          raise
        rescue => e
          say "Setup failed: #{e.message}", :red
          exit 1
        end
      end
    end
  end
end
