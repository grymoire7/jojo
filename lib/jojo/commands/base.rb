# lib/jojo/commands/base.rb
require_relative "../employer"
require_relative "../config"
require_relative "../ai_client"
require_relative "../status_logger"

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

      # Shared setup (lazy-loaded)
      def employer
        @employer ||= Jojo::Employer.new(slug)
      end

      def config
        @config ||= Jojo::Config.new
      end

      def ai_client
        @ai_client ||= Jojo::AIClient.new(config, verbose: verbose?)
      end

      def status_logger
        @status_logger ||= Jojo::StatusLogger.new(employer)
      end
    end
  end
end
