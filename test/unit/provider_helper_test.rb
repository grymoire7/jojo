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
end
