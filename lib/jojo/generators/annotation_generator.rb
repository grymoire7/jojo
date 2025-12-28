require 'json'
require_relative '../prompts/annotation_prompt'

module Jojo
  module Generators
    class AnnotationGenerator
      attr_reader :employer, :ai_client, :verbose

      def initialize(employer, ai_client, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @verbose = verbose
      end
    end
  end
end
