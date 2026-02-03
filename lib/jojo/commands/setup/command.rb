# lib/jojo/commands/setup/command.rb
require_relative "../base"
require_relative "service"

module Jojo
  module Commands
    module Setup
      class Command < Base
        def initialize(cli, service: nil, **rest)
          super(cli, **rest)
          @service = service
        end

        def execute
          service.run
        rescue SystemExit
          # Allow clean exit from service
          raise
        rescue => e
          say "Setup failed: #{e.message}", :red
          exit 1
        end

        private

        def service
          @service ||= Service.new(
            cli_instance: cli,
            overwrite: overwrite?
          )
        end
      end
    end
  end
end
