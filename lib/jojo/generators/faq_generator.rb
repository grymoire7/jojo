require 'json'
require 'fileutils'
require_relative '../prompts/faq_prompt'

module Jojo
  module Generators
    class FaqGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        []
      end

      private

      def log(message)
        puts "  [FaqGenerator] #{message}" if verbose
      end
    end
  end
end
