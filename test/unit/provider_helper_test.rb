require_relative "../test_helper"
require_relative "../../lib/jojo/provider_helper"

class ProviderHelperTest < JojoTest
  def test_returns_list_of_provider_slugs_from_rubyllm
    providers = Jojo::ProviderHelper.available_providers
    assert_kind_of Array, providers
    assert_includes providers, "anthropic"
    assert_includes providers, "openai"
    assert_operator providers.length, :>, 5
  end

  def test_returns_providers_in_alphabetical_order
    providers = Jojo::ProviderHelper.available_providers
    assert_equal providers.sort, providers
  end

  def test_returns_uppercase_env_var_name_for_provider
    assert_equal "ANTHROPIC_API_KEY", Jojo::ProviderHelper.provider_env_var_name("anthropic")
    assert_equal "OPENAI_API_KEY", Jojo::ProviderHelper.provider_env_var_name("openai")
  end

  def test_raises_error_for_unknown_provider
    error = assert_raises(ArgumentError) do
      Jojo::ProviderHelper.provider_env_var_name("unknown_provider")
    end
    assert_includes error.message, "Unknown provider"
  end

  def test_returns_models_for_specified_provider
    models = Jojo::ProviderHelper.available_models("anthropic")
    assert_kind_of Array, models
    assert_includes models, "claude-sonnet-4-5"
    assert_includes models, "claude-3-5-haiku-20241022"
    assert_equal true, models.all? { |m| m.is_a?(String) }
  end

  def test_returns_models_in_alphabetical_order
    models = Jojo::ProviderHelper.available_models("anthropic")
    assert_equal models.sort, models
  end

  def test_returns_empty_array_for_provider_with_no_models
    models = Jojo::ProviderHelper.available_models("unknown")
    assert_equal [], models
  end
end
