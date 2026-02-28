require_relative "../test_helper"
require_relative "../../lib/jojo/commands/configure/service"

class SetupIntegrationTest < JojoTest
  def test_completes_full_setup_flow_with_anthropic_provider
    setup_template_files

    # Mock CLI interactions
    cli = Minitest::Mock.new

    # warn_if_overwrite_mode (skipped - not in overwrite mode)

    # setup_api_configuration
    cli.expect :say, nil, ["Setting up Jojo...", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Let's configure your API access.", :green]
    cli.expect :say, nil, [""]
    cli.expect :ask, "sk-ant-test123", ["Anthropic API key:"]

    # setup_search_configuration (skip)
    cli.expect :say, nil, [""]

    # write_env_file
    cli.expect :say, nil, ["✓ Created .env", :green]

    # setup_personal_configuration
    cli.expect :ask, "Test User", ["Your name:"]
    cli.expect :ask, "https://test.com", [/Your website base URL/]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["✓ Created config.yml", :green]

    # Add prompt mock
    prompt = Minitest::Mock.new
    providers = Jojo::ProviderHelper.available_providers
    available_models = Jojo::ProviderHelper.available_models("anthropic")

    prompt.expect :select, "anthropic", ["Which LLM provider?", providers, {per_page: 15}]
    prompt.expect :yes?, false, [String]  # Skip search configuration
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

    # setup_input_files
    cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setting up your profile templates...", :green]
    cli.expect :say, nil, [String, :green]

    # show_summary
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Configuration complete!", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Created:"]
    3.times { cli.expect :say, nil, [String] } # 3 created files
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Next steps:", :cyan]
    cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
    cli.expect :say, nil, ["  2. Copy templates/resume.md.erb to inputs/templates/ to customize resume layout"]
    cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

    service = Jojo::Commands::Configure::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.run

    cli.verify
    prompt.verify

    # Verify .env
    assert_equal true, File.exist?(".env")
    env_content = File.read(".env")
    assert_includes env_content, "ANTHROPIC_API_KEY=sk-ant-test123"

    # Verify config.yml
    assert_equal true, File.exist?("config.yml")
    config_content = File.read("config.yml")
    assert_includes config_content, "seeker_name: Test User"
    assert_includes config_content, "service: anthropic"
    assert_includes config_content, "model: claude-sonnet-4-5"
    assert_includes config_content, "model: claude-3-5-haiku-20241022"

    # Verify input files
  end

  def test_completes_full_setup_flow_with_openai_provider
    setup_template_files

    # Mock CLI interactions
    cli = Minitest::Mock.new

    # setup_api_configuration
    cli.expect :say, nil, ["Setting up Jojo...", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Let's configure your API access.", :green]
    cli.expect :say, nil, [""]
    cli.expect :ask, "sk-test-openai", ["Openai API key:"]

    # setup_search_configuration (skip)
    cli.expect :say, nil, [""]

    # write_env_file
    cli.expect :say, nil, ["✓ Created .env", :green]

    # setup_personal_configuration
    cli.expect :ask, "Test User", ["Your name:"]
    cli.expect :ask, "https://test.com", [/Your website base URL/]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["✓ Created config.yml", :green]

    # Add prompt mock
    prompt = Minitest::Mock.new
    providers = Jojo::ProviderHelper.available_providers
    available_models = Jojo::ProviderHelper.available_models("openai")

    prompt.expect :select, "openai", ["Which LLM provider?", providers, {per_page: 15}]
    prompt.expect :yes?, false, [String]  # Skip search configuration
    prompt.expect :select, "gpt-4o", [
      "Which model for reasoning tasks (company research, resume tailoring)?",
      available_models,
      {per_page: 15}
    ]
    prompt.expect :select, "gpt-4o-mini", [
      "Which model for text generation tasks (faster, simpler)?",
      available_models,
      {per_page: 15}
    ]

    cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setting up your profile templates...", :green]
    cli.expect :say, nil, [String, :green]

    # show_summary
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Configuration complete!", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Created:"]
    3.times { cli.expect :say, nil, [String] } # 3 created files
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Next steps:", :cyan]
    cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
    cli.expect :say, nil, ["  2. Copy templates/resume.md.erb to inputs/templates/ to customize resume layout"]
    cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

    service = Jojo::Commands::Configure::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.run

    cli.verify
    prompt.verify

    # Verify .env
    env_content = File.read(".env")
    assert_includes env_content, "OPENAI_API_KEY=sk-test-openai"

    # Verify config.yml
    config_content = File.read("config.yml")
    assert_includes config_content, "service: openai"
    assert_includes config_content, "model: gpt-4o"
    assert_includes config_content, "model: gpt-4o-mini"
  end

  def test_completes_full_setup_flow_with_search_provider
    setup_template_files

    # Mock CLI interactions
    cli = Minitest::Mock.new
    prompt = Minitest::Mock.new

    # warn_if_overwrite_mode (skipped - not in overwrite mode)

    # setup_api_configuration
    cli.expect :say, nil, ["Setting up Jojo...", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Let's configure your API access.", :green]
    cli.expect :say, nil, [""]
    prompt.expect :select, "anthropic", ["Which LLM provider?", Array, Hash]
    cli.expect :ask, "sk-ant-test123", ["Anthropic API key:"]

    # setup_search_configuration
    cli.expect :say, nil, [""]
    prompt.expect :yes?, true, [String]  # Configure search?
    prompt.expect :select, "tavily", ["Which search provider?", Array, Hash]
    cli.expect :ask, "sk-tavily-test", ["Tavily API key:"]

    # write_env_file
    cli.expect :say, nil, ["✓ Created .env", :green]

    # setup_personal_configuration
    cli.expect :ask, "Test User", ["Your name:"]
    cli.expect :ask, "https://test.com", [/Your website base URL/]
    cli.expect :say, nil, [""]
    prompt.expect :select, "claude-sonnet-4-5", [/Which model for reasoning/, Array, Hash]
    cli.expect :say, nil, [""]
    prompt.expect :select, "claude-3-5-haiku-20241022", [/Which model for text generation/, Array, Hash]
    cli.expect :say, nil, ["✓ Created config.yml", :green]

    # setup_input_files
    cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Setting up your profile templates...", :green]
    cli.expect :say, nil, [String, :green]

    # show_summary
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Configuration complete!", :green]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Created:"]
    3.times { cli.expect :say, nil, [String] } # 3 created files
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["Next steps:", :cyan]
    cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
    cli.expect :say, nil, ["  2. Copy templates/resume.md.erb to inputs/templates/ to customize resume layout"]
    cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
    cli.expect :say, nil, [""]
    cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

    service = Jojo::Commands::Configure::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
    service.run

    cli.verify
    prompt.verify

    # Verify .env
    assert_equal true, File.exist?(".env")
    env_content = File.read(".env")
    assert_includes env_content, "ANTHROPIC_API_KEY=sk-ant-test123"
    assert_includes env_content, "TAVILY_API_KEY=sk-tavily-test"

    # Verify config.yml
    assert_equal true, File.exist?("config.yml")
    config_content = File.read("config.yml")
    assert_includes config_content, "seeker_name: Test User"
    assert_includes config_content, "service: anthropic"
    assert_includes config_content, "search: tavily"

    # Verify input files
  end

  private

  def setup_template_files
    templates_dir = File.join(@original_dir, "templates")
    FileUtils.mkdir_p("templates")
    FileUtils.cp(File.join(templates_dir, ".env.erb"), "templates/.env.erb")
    FileUtils.cp(File.join(templates_dir, "config.yml.erb"), "templates/config.yml.erb")
    FileUtils.cp(File.join(templates_dir, "resume_data.yml"), "templates/resume_data.yml")
    FileUtils.cp(File.join(templates_dir, "resume.md.erb"), "templates/resume.md.erb")
  end
end
