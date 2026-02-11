# test/unit/commands/setup/service_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/setup/service"
require_relative "../../../../lib/jojo/provider_helper"
require "thor"

class Jojo::Commands::Setup::ServiceTest < JojoTest
  # -- initialize --

  def test_stores_cli_instance_and_overwrite_flag
    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: true)
    _(service.instance_variable_get(:@cli)).must_be_same_as cli
    _(service.instance_variable_get(:@overwrite)).must_equal true
  end

  def test_defaults_overwrite_to_false
    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli)
    _(service.instance_variable_get(:@overwrite)).must_equal false
  end

  def test_initializes_tracking_arrays
    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli)
    _(service.instance_variable_get(:@created_files)).must_equal []
    _(service.instance_variable_get(:@skipped_files)).must_equal []
  end

  def test_accepts_optional_prompt_parameter
    cli = Object.new
    prompt = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt)
    _(service.instance_variable_get(:@prompt)).must_be_same_as prompt
  end

  def test_creates_default_tty_prompt_when_prompt_not_provided
    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli)
    _(service.instance_variable_get(:@prompt)).must_be_instance_of TTY::Prompt
  end

  # -- setup_api_configuration --

  def test_setup_api_configuration_skips_when_env_exists_and_not_overwrite_mode
    File.write(".env", "ANTHROPIC_API_KEY=existing")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ .env already exists (skipped)", :green]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.send(:setup_api_configuration)

    cli.verify
    _(File.read(".env")).must_equal "ANTHROPIC_API_KEY=existing"
    _(service.instance_variable_get(:@provider_slug)).must_equal "anthropic"
  end

  def test_setup_api_configuration_gathers_llm_config_when_env_missing
    FileUtils.mkdir_p("templates")
    File.write("templates/.env.erb", "<%= llm_env_var_name %>=<%= llm_api_key %>")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["Let's configure your API access.", :green]
    cli.expect :say, nil, [""]
    cli.expect :ask, "sk-ant-test-key", ["Anthropic API key:"]

    prompt = Minitest::Mock.new
    prompt.expect :select, "anthropic", ["Which LLM provider?", Jojo::ProviderHelper.available_providers, {per_page: 15}]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.send(:setup_api_configuration)

    cli.verify
    prompt.verify
    _(File.exist?(".env")).must_equal false  # File not created yet
    _(service.instance_variable_get(:@llm_provider_slug)).must_equal "anthropic"
    _(service.instance_variable_get(:@llm_api_key)).must_equal "sk-ant-test-key"
  end

  # -- setup_personal_configuration --

  def test_setup_personal_configuration_skips_when_config_yml_exists_and_not_overwrite_mode
    File.write("config.yml", "seeker_name: Existing")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ config.yml already exists (skipped)", :green]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.send(:setup_personal_configuration)

    cli.verify
  end

  def test_setup_personal_configuration_creates_config_yml_from_template_when_missing
    FileUtils.mkdir_p("templates")
    File.write("templates/config.yml.erb", <<~YAML)
      seeker_name: <%= seeker_name %>
      base_url: <%= base_url %>
      reasoning_ai:
        service: <%= reasoning_provider %>
        model: <%= reasoning_model %>
      text_generation_ai:
        service: <%= text_generation_provider %>
        model: <%= text_generation_model %>
    YAML

    cli = Minitest::Mock.new
    cli.expect :ask, "Tracy Atteberry", ["Your name:"]
    cli.expect :ask, "https://example.com", ["Your website base URL (e.g., https://yourname.com):"]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["✓ Created config.yml", :green]

    prompt = Minitest::Mock.new
    available_models = Jojo::ProviderHelper.available_models("anthropic")
    prompt.expect :select, "claude-sonnet-4-5", [
      "Which model for reasoning tasks (company research, resume tailoring)?",
      available_models,
      {per_page: 15}
    ]
    prompt.expect :select, "claude-3-5-haiku-20241022", [
      "Which model for text generation tasks (faster, simpler)?",
      available_models,
      {per_page: 15}
    ]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.instance_variable_set(:@provider_slug, "anthropic")
    service.instance_variable_set(:@search_provider_slug, nil)
    service.send(:setup_personal_configuration)

    cli.verify
    prompt.verify
    _(File.exist?("config.yml")).must_equal true
    content = File.read("config.yml")
    _(content).must_include "Tracy Atteberry"
    _(content).must_include "service: anthropic"
    _(content).must_include "model: claude-sonnet-4-5"
    _(content).must_include "model: claude-3-5-haiku-20241022"
  end

  # -- setup_search_configuration --

  def test_setup_search_configuration_configures_search_when_user_selects_yes_and_tavily
    cli = Minitest::Mock.new
    prompt = Minitest::Mock.new

    cli.expect :say, nil, [""]
    prompt.expect :yes?, true, ["Configure web search for company research? (requires Tavily or Serper API)"]
    prompt.expect :select, "tavily", ["Which search provider?", ["tavily", "serper"], Hash]
    cli.expect :ask, "sk-tavily-test", ["Tavily API key:"]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.send(:setup_search_configuration)

    cli.verify
    prompt.verify
    _(service.instance_variable_get(:@search_provider_slug)).must_equal "tavily"
    _(service.instance_variable_get(:@search_api_key)).must_equal "sk-tavily-test"
    _(service.instance_variable_get(:@search_env_var_name)).must_equal "TAVILY_API_KEY"
  end

  def test_setup_search_configuration_configures_search_when_user_selects_yes_and_serper
    cli = Minitest::Mock.new
    prompt = Minitest::Mock.new

    cli.expect :say, nil, [""]
    prompt.expect :yes?, true, ["Configure web search for company research? (requires Tavily or Serper API)"]
    prompt.expect :select, "serper", ["Which search provider?", ["tavily", "serper"], Hash]
    cli.expect :ask, "serper-key-123", ["Serper API key:"]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.send(:setup_search_configuration)

    cli.verify
    prompt.verify
    _(service.instance_variable_get(:@search_provider_slug)).must_equal "serper"
    _(service.instance_variable_get(:@search_api_key)).must_equal "serper-key-123"
    _(service.instance_variable_get(:@search_env_var_name)).must_equal "SERPER_API_KEY"
  end

  def test_setup_search_configuration_skips_search_when_user_selects_no
    cli = Minitest::Mock.new
    prompt = Minitest::Mock.new

    cli.expect :say, nil, [""]
    prompt.expect :yes?, false, ["Configure web search for company research? (requires Tavily or Serper API)"]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.send(:setup_search_configuration)

    cli.verify
    prompt.verify
    _(service.instance_variable_get(:@search_provider_slug)).must_be_nil
  end

  # -- write_env_file --

  def test_write_env_file_writes_env_with_llm_config_only_when_search_not_configured
    FileUtils.mkdir_p("templates")
    File.write("templates/.env.erb", <<~ERB)
      # LLM Provider Configuration
      # Generated during 'jojo setup' - edit this file to change your API key
      <%= llm_env_var_name %>=<%= llm_api_key %>

      <% if search_provider_slug %>
      # Web Search Provider Configuration (for company research enhancement)
      <%= search_env_var_name %>=<%= search_api_key %>
      <% end %>
    ERB

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ Created .env", :green]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.instance_variable_set(:@llm_env_var_name, "ANTHROPIC_API_KEY")
    service.instance_variable_set(:@llm_api_key, "sk-ant-test")
    service.instance_variable_set(:@search_provider_slug, nil)
    service.send(:write_env_file)

    cli.verify
    _(File.exist?(".env")).must_equal true
    content = File.read(".env")
    _(content).must_include "ANTHROPIC_API_KEY=sk-ant-test"
    _(content).wont_include "TAVILY"
    _(content).wont_include "SERPER"
  end

  def test_write_env_file_writes_env_with_both_llm_and_search_config
    FileUtils.mkdir_p("templates")
    File.write("templates/.env.erb", <<~ERB)
      # LLM Provider Configuration
      # Generated during 'jojo setup' - edit this file to change your API key
      <%= llm_env_var_name %>=<%= llm_api_key %>

      <% if search_provider_slug %>
      # Web Search Provider Configuration (for company research enhancement)
      <%= search_env_var_name %>=<%= search_api_key %>
      <% end %>
    ERB

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ Created .env", :green]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.instance_variable_set(:@llm_env_var_name, "OPENAI_API_KEY")
    service.instance_variable_set(:@llm_api_key, "sk-openai-test")
    service.instance_variable_set(:@search_provider_slug, "tavily")
    service.instance_variable_set(:@search_env_var_name, "TAVILY_API_KEY")
    service.instance_variable_set(:@search_api_key, "sk-tavily-test")
    service.send(:write_env_file)

    cli.verify
    _(File.exist?(".env")).must_equal true
    content = File.read(".env")
    _(content).must_include "OPENAI_API_KEY=sk-openai-test"
    _(content).must_include "TAVILY_API_KEY=sk-tavily-test"
  end

  def test_write_env_file_skips_writing_when_env_already_exists_in_skipped_files
    # Create existing .env with real content
    File.write(".env", "ANTHROPIC_API_KEY=original-key")

    cli = Minitest::Mock.new
    # Should NOT expect "Created .env" message

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.instance_variable_set(:@skipped_files, [".env"])
    # Instance vars intentionally nil (not populated when skipped)
    service.instance_variable_set(:@llm_env_var_name, nil)
    service.instance_variable_set(:@llm_api_key, nil)
    service.send(:write_env_file)

    cli.verify
    # File should NOT be overwritten
    _(File.read(".env")).must_equal "ANTHROPIC_API_KEY=original-key"
  end

  # -- setup_input_files --

  def test_setup_input_files_creates_inputs_directory_if_missing
    FileUtils.mkdir_p("templates")
    File.write("templates/resume_data.yml", "# JOJO_TEMPLATE_PLACEHOLDER")
    File.write("templates/default_resume.md.erb", "<!-- JOJO_TEMPLATE_PLACEHOLDER -->")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setting up your profile templates...", :green]
    2.times { cli.expect :say, nil, [String, :green] }

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.send(:setup_input_files)

    cli.verify
    _(Dir.exist?("inputs")).must_equal true
    _(Dir.exist?("inputs/templates")).must_equal true
  end

  def test_setup_input_files_copies_template_files_to_inputs
    FileUtils.mkdir_p("templates")
    File.write("templates/resume_data.yml", "# JOJO_TEMPLATE_PLACEHOLDER\nname: Test")
    File.write("templates/default_resume.md.erb", "<!-- JOJO_TEMPLATE_PLACEHOLDER -->\n<%= name %>")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setting up your profile templates...", :green]
    cli.expect :say, nil, ["✓ Created inputs/resume_data.yml (customize with your experience)", :green]
    cli.expect :say, nil, ["✓ Created inputs/templates/default_resume.md.erb (resume ERB template)", :green]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.send(:setup_input_files)

    cli.verify
    _(File.exist?("inputs/resume_data.yml")).must_equal true
    _(File.read("inputs/resume_data.yml")).must_include "JOJO_TEMPLATE_PLACEHOLDER"
    _(File.exist?("inputs/templates/default_resume.md.erb")).must_equal true
    _(File.read("inputs/templates/default_resume.md.erb")).must_include "JOJO_TEMPLATE_PLACEHOLDER"
  end

  def test_setup_input_files_skips_existing_files_unless_overwrite_mode
    FileUtils.mkdir_p("inputs")
    FileUtils.mkdir_p("inputs/templates")
    FileUtils.mkdir_p("templates")
    File.write("inputs/resume_data.yml", "Existing data")
    File.write("templates/resume_data.yml", "Template data")
    File.write("templates/default_resume.md.erb", "Template ERB")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setting up your profile templates...", :green]
    cli.expect :say, nil, ["✓ inputs/resume_data.yml already exists (skipped)", :green]
    cli.expect :say, nil, ["✓ Created inputs/templates/default_resume.md.erb (resume ERB template)", :green]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.send(:setup_input_files)

    cli.verify
    _(File.read("inputs/resume_data.yml")).must_equal "Existing data"
  end

  # -- show_summary --

  def test_show_summary_displays_created_files_and_next_steps
    cli = Minitest::Mock.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli)
    service.instance_variable_set(:@created_files, [".env", "config.yml", "inputs/resume_data.yml"])

    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setup complete!", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Created:"]
    3.times { cli.expect :say, nil, [String] }
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Next steps:", :cyan]
    cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
    cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
    cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

    service.send(:show_summary)

    cli.verify
  end

  def test_show_summary_shows_appropriate_message_when_no_files_created
    cli = Minitest::Mock.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli)
    service.instance_variable_set(:@created_files, [])
    service.instance_variable_set(:@skipped_files, [".env", "config.yml"])

    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setup complete!", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Next steps:", :cyan]
    cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
    cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
    cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

    service.send(:show_summary)

    cli.verify
  end

  # -- warn_if_overwrite_mode --

  def test_warn_if_overwrite_mode_prompts_for_confirmation_in_overwrite_mode
    cli = Minitest::Mock.new
    cli.expect :say, nil, ["⚠ WARNING: --overwrite will overwrite existing configuration files!", :yellow]
    cli.expect :say, nil, ["  This will replace: .env, config.yml, and all inputs/ files", :yellow]
    cli.expect :yes?, true, ["Continue?"]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: true)
    service.send(:warn_if_overwrite_mode)

    cli.verify
  end

  def test_warn_if_overwrite_mode_exits_when_user_declines_overwrite_mode
    cli = Minitest::Mock.new
    cli.expect :say, nil, ["⚠ WARNING: --overwrite will overwrite existing configuration files!", :yellow]
    cli.expect :say, nil, ["  This will replace: .env, config.yml, and all inputs/ files", :yellow]
    cli.expect :yes?, false, ["Continue?"]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: true)

    assert_raises(SystemExit) do
      service.send(:warn_if_overwrite_mode)
    end
  end

  def test_warn_if_overwrite_mode_does_nothing_when_not_in_overwrite_mode
    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)
    service.send(:warn_if_overwrite_mode)
    # No expectations, should complete without errors
  end

  # -- validate_configuration_completeness --

  def test_validate_configuration_completeness_fails_when_env_exists_but_config_yml_missing
    File.write(".env", "ANTHROPIC_API_KEY=test")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✗ Partial configuration detected", :red]
    cli.expect :say, nil, ["  Found: .env", :yellow]
    cli.expect :say, nil, ["  Missing: config.yml", :yellow]
    cli.expect :say, nil, ["", :yellow]
    cli.expect :say, nil, ["Options:", :yellow]
    cli.expect :say, nil, ["  • Run 'jojo setup --overwrite' to recreate all configuration", :yellow]
    cli.expect :say, nil, ["  • Manually create config.yml to match your existing .env setup", :yellow]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)

    assert_raises(SystemExit) do
      service.send(:validate_configuration_completeness)
    end

    cli.verify
  end

  def test_validate_configuration_completeness_fails_when_config_yml_exists_but_env_missing
    File.write("config.yml", "seeker_name: Test")

    cli = Minitest::Mock.new
    cli.expect :say, nil, ["✗ Partial configuration detected", :red]
    cli.expect :say, nil, ["  Found: config.yml", :yellow]
    cli.expect :say, nil, ["  Missing: .env", :yellow]
    cli.expect :say, nil, ["", :yellow]
    cli.expect :say, nil, ["Options:", :yellow]
    cli.expect :say, nil, ["  • Run 'jojo setup --overwrite' to recreate all configuration", :yellow]
    cli.expect :say, nil, ["  • Manually create .env with your API keys", :yellow]

    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)

    assert_raises(SystemExit) do
      service.send(:validate_configuration_completeness)
    end

    cli.verify
  end

  def test_validate_configuration_completeness_succeeds_when_both_env_and_config_yml_exist
    File.write(".env", "ANTHROPIC_API_KEY=test")
    File.write("config.yml", "seeker_name: Test")

    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)

    # Should not raise
    service.send(:validate_configuration_completeness)
  end

  def test_validate_configuration_completeness_succeeds_when_neither_env_nor_config_yml_exist
    # Empty directory - normal setup flow
    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: false)

    # Should not raise
    service.send(:validate_configuration_completeness)
  end

  def test_validate_configuration_completeness_proceeds_when_partial_config_detected_but_overwrite_is_set
    File.write(".env", "ANTHROPIC_API_KEY=test")
    # config.yml missing

    cli = Object.new
    service = Jojo::Commands::Setup::Service.new(cli_instance: cli, overwrite: true)

    # Should NOT raise, should proceed silently
    service.send(:validate_configuration_completeness)
  end
end
