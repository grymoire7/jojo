require_relative "../test_helper"
require_relative "../../lib/jojo/commands/setup/service"

describe "Setup Integration" do
  it "completes full setup flow with anthropic provider" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files
        FileUtils.mkdir_p("templates")
        FileUtils.cp(
          File.join(__dir__, "../../templates/.env.erb"),
          "templates/.env.erb"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/config.yml.erb"),
          "templates/config.yml.erb"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/resume_data.yml"),
          "templates/resume_data.yml"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/default_resume.md.erb"),
          "templates/default_resume.md.erb"
        )

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
        2.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setup complete!", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Created:"]
        4.times { cli.expect :say, nil, [String] } # 4 created files
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Next steps:", :cyan]
        cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
        cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
        cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

        service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
        service.run

        cli.verify
        prompt.verify

        # Verify .env
        _(File.exist?(".env")).must_equal true
        env_content = File.read(".env")
        _(env_content).must_include "ANTHROPIC_API_KEY=sk-ant-test123"

        # Verify config.yml
        _(File.exist?("config.yml")).must_equal true
        config_content = File.read("config.yml")
        _(config_content).must_include "seeker_name: Test User"
        _(config_content).must_include "service: anthropic"
        _(config_content).must_include "model: claude-sonnet-4-5"
        _(config_content).must_include "model: claude-3-5-haiku-20241022"

        # Verify input files
      end
    end
  end

  it "completes full setup flow with openai provider" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files (same as above)
        FileUtils.mkdir_p("templates")
        FileUtils.cp(
          File.join(__dir__, "../../templates/.env.erb"),
          "templates/.env.erb"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/config.yml.erb"),
          "templates/config.yml.erb"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/resume_data.yml"),
          "templates/resume_data.yml"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/default_resume.md.erb"),
          "templates/default_resume.md.erb"
        )

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
        2.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setup complete!", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Created:"]
        4.times { cli.expect :say, nil, [String] } # 4 created files
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Next steps:", :cyan]
        cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
        cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
        cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

        service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
        service.run

        cli.verify
        prompt.verify

        # Verify .env
        env_content = File.read(".env")
        _(env_content).must_include "OPENAI_API_KEY=sk-test-openai"

        # Verify config.yml
        config_content = File.read("config.yml")
        _(config_content).must_include "service: openai"
        _(config_content).must_include "model: gpt-4o"
        _(config_content).must_include "model: gpt-4o-mini"
      end
    end
  end

  it "completes full setup flow with search provider" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files
        FileUtils.mkdir_p("templates")
        FileUtils.cp(
          File.join(__dir__, "../../templates/.env.erb"),
          "templates/.env.erb"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/config.yml.erb"),
          "templates/config.yml.erb"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/resume_data.yml"),
          "templates/resume_data.yml"
        )
        FileUtils.cp(
          File.join(__dir__, "../../templates/default_resume.md.erb"),
          "templates/default_resume.md.erb"
        )

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
        2.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setup complete!", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Created:"]
        4.times { cli.expect :say, nil, [String] } # 4 created files
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Next steps:", :cyan]
        cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
        cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
        cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

        service = Jojo::Commands::Setup::Service.new(cli_instance: cli, prompt: prompt, overwrite: false)
        service.run

        cli.verify
        prompt.verify

        # Verify .env
        _(File.exist?(".env")).must_equal true
        env_content = File.read(".env")
        _(env_content).must_include "ANTHROPIC_API_KEY=sk-ant-test123"
        _(env_content).must_include "TAVILY_API_KEY=sk-tavily-test"

        # Verify config.yml
        _(File.exist?("config.yml")).must_equal true
        config_content = File.read("config.yml")
        _(config_content).must_include "seeker_name: Test User"
        _(config_content).must_include "service: anthropic"
        _(config_content).must_include "search: tavily"

        # Verify input files
      end
    end
  end
end
