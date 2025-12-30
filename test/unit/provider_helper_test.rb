require_relative '../test_helper'
require_relative '../../lib/jojo/provider_helper'

describe Jojo::ProviderHelper do
  describe '.available_providers' do
    it 'returns list of provider slugs from RubyLLM' do
      providers = Jojo::ProviderHelper.available_providers
      _(providers).must_be_kind_of Array
      _(providers).must_include 'anthropic'
      _(providers).must_include 'openai'
      _(providers.length).must_be :>, 5
    end

    it 'returns providers in alphabetical order' do
      providers = Jojo::ProviderHelper.available_providers
      _(providers).must_equal providers.sort
    end
  end

  describe '.provider_env_var_name' do
    it 'returns uppercase env var name for provider' do
      _(Jojo::ProviderHelper.provider_env_var_name('anthropic')).must_equal 'ANTHROPIC_API_KEY'
      _(Jojo::ProviderHelper.provider_env_var_name('openai')).must_equal 'OPENAI_API_KEY'
    end

    it 'raises error for unknown provider' do
      error = assert_raises(ArgumentError) do
        Jojo::ProviderHelper.provider_env_var_name('unknown_provider')
      end
      _(error.message).must_include 'Unknown provider'
    end
  end
end
