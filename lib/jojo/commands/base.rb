# lib/jojo/commands/base.rb
require_relative "../application"
require_relative "../config"
require_relative "../ai_client"
require_relative "../status_logger"

module Jojo
  module Commands
    class Base
      attr_reader :cli, :options

      def initialize(cli, ai_client: nil, application: nil, **options)
        @cli = cli
        @options = options.transform_keys(&:to_sym)
        @ai_client = ai_client
        @application = application
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
      def application
        @application ||= Jojo::Application.new(slug)
      end

      def config
        @config ||= Jojo::Config.new
      end

      def ai_client
        @ai_client ||= Jojo::AIClient.new(config, verbose: verbose?)
      end

      def log(**args)
        status_logger.log(**args)
      end

      # Common validations
      def require_application!
        if slug.nil? || slug.strip.empty?
          say "No application slug specified. Use --slug=COMPANY_SLUG (e.g., --slug=acme-corp)", :red
          exit 1
        end

        return if application.artifacts_exist?

        say "Application '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug}' to create it.", :yellow
        exit 1
      end

      def require_file!(path, description, suggestion: nil)
        return if File.exist?(path)

        say "#{description} not found at #{path}", :red
        say "  #{suggestion}", :yellow if suggestion
        exit 1
      end

      private

      def status_logger
        @status_logger ||= application.status_logger
      end
    end
  end
end
