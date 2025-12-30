require 'ruby_llm'

module Jojo
  module ProviderHelper
    def self.available_providers
      RubyLLM.providers.map(&:slug).sort
    end
  end
end
