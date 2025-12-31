require "ruby_llm"

module Jojo
  module ProviderHelper
    def self.available_providers
      RubyLLM.providers.map(&:slug).sort
    end

    def self.provider_env_var_name(provider_slug)
      provider = RubyLLM.providers.find { |p| p.slug == provider_slug }
      raise ArgumentError, "Unknown provider: #{provider_slug}" unless provider

      provider.configuration_requirements.first.to_s.upcase
    end

    def self.available_models(provider_slug)
      RubyLLM.models
        .filter { |m| m.provider == provider_slug }
        .map(&:id)
        .sort
    end
  end
end
