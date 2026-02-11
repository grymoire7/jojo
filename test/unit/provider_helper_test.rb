require_relative "../test_helper"
require_relative "../../lib/jojo/provider_helper"

class ProviderHelperTest < JojoTest
  def test_returns_list_of_provider_slugs_from_rubyllm
    providers = Jojo::ProviderHelper.available_providers
    _(providers).must_be_kind_of Array
    _(providers).must_include "anthropic"
    _(providers).must_include "openai"
    _(providers.length).must_be :>, 5
  end

  def test_returns_providers_in_alphabetical_order
    providers = Jojo::ProviderHelper.available_providers
    _(providers).must_equal providers.sort
  end

  def test_returns_uppercase_env_var_name_for_provider
    _(Jojo::ProviderHelper.provider_env_var_name("anthropic")).must_equal "ANTHROPIC_API_KEY"
    _(Jojo::ProviderHelper.provider_env_var_name("openai")).must_equal "OPENAI_API_KEY"
  end

  def test_raises_error_for_unknown_provider
    error = assert_raises(ArgumentError) do
      Jojo::ProviderHelper.provider_env_var_name("unknown_provider")
    end
    _(error.message).must_include "Unknown provider"
  end

  def test_returns_models_for_specified_provider
    models = Jojo::ProviderHelper.available_models("anthropic")
    _(models).must_be_kind_of Array
    _(models).must_include "claude-sonnet-4-5"
    _(models).must_include "claude-3-5-haiku-20241022"
    _(models.all? { |m| m.is_a?(String) }).must_equal true
  end

  def test_returns_models_in_alphabetical_order
    models = Jojo::ProviderHelper.available_models("anthropic")
    _(models).must_equal models.sort
  end

  def test_returns_empty_array_for_provider_with_no_models
    models = Jojo::ProviderHelper.available_models("unknown")
    _(models).must_equal []
  end
end
