# lib/jojo/commands/console_output.rb
require_relative "../overwrite_helper"

module Jojo
  module Commands
    class ConsoleOutput
      include Jojo::OverwriteHelper

      def initialize(quiet: false)
        @quiet = quiet
      end

      def say(message, _color = nil)
        puts message unless @quiet
      end

      def yes?(prompt)
        print "#{prompt} "
        response = $stdin.gets&.chomp&.downcase || ""
        response.start_with?("y")
      end
    end
  end
end
