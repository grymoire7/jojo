# lib/jojo/commands/version/command.rb
require_relative "../base"

module Jojo
  module Commands
    module Version
      class Command < Base
        def execute
          say "Jojo #{Jojo::VERSION}", :green
        end
      end
    end
  end
end
