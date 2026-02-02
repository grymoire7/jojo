# lib/jojo/commands/base.rb
module Jojo
  module Commands
    class Base
      attr_reader :cli, :options

      def initialize(cli, options = {})
        @cli = cli
        @options = options
      end

      def execute
        raise NotImplementedError, "Subclasses must implement #execute"
      end

      protected

      # Common options
      def slug = options[:slug]
      def verbose? = options[:verbose] || false
      def overwrite? = options[:overwrite] || false
      def quiet? = options[:quiet] || false

      # Output helpers (delegate to injected CLI)
      def say(message, color = nil) = cli.say(message, color)
      def yes?(prompt) = cli.yes?(prompt)
    end
  end
end
