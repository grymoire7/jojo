# lib/jojo/commands/interactive/command.rb
require_relative "../../interactive"

module Jojo
  module Commands
    module Interactive
      class Command
        attr_reader :options

        def initialize(_cli, options = {})
          @options = options
        end

        def execute
          slug = options[:slug] || ENV["JOJO_EMPLOYER_SLUG"]
          Jojo::Interactive.new(slug: slug).run
        end
      end
    end
  end
end
