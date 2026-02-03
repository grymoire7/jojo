# lib/jojo/commands/interactive/command.rb
require_relative "runner"

module Jojo
  module Commands
    module Interactive
      class Command
        attr_reader :options

        def initialize(_cli, options = {})
          @options = options.transform_keys(&:to_sym)
        end

        def execute
          slug = options[:slug] || ENV["JOJO_EMPLOYER_SLUG"]
          Runner.new(slug: slug).run
        end
      end
    end
  end
end
