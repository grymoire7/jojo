require_relative "../test_helper"
require_relative "../../lib/jojo/setup_service"
require_relative "../../lib/jojo/provider_helper"
require "thor"

describe Jojo::SetupService do
  describe "#initialize" do
    it "stores cli_instance and force flag" do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli, force: true)
      _(service.instance_variable_get(:@cli)).must_be_same_as cli
      _(service.instance_variable_get(:@force)).must_equal true
    end

    it "defaults force to false" do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli)
      _(service.instance_variable_get(:@force)).must_equal false
    end

    it "initializes tracking arrays" do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli)
      _(service.instance_variable_get(:@created_files)).must_equal []
      _(service.instance_variable_get(:@skipped_files)).must_equal []
    end

    it "accepts optional prompt parameter" do
      cli = Object.new
      prompt = Object.new
      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt)
      _(service.instance_variable_get(:@prompt)).must_be_same_as prompt
    end

    it "creates default TTY::Prompt when prompt not provided" do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli)
      _(service.instance_variable_get(:@prompt)).must_be_instance_of TTY::Prompt
    end
  end

  describe "#setup_api_configuration" do
    it "skips when .env exists and not force mode" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write(".env", "ANTHROPIC_API_KEY=existing")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ .env already exists (skipped)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          _(File.read(".env")).must_equal "ANTHROPIC_API_KEY=existing"
          _(service.instance_variable_get(:@provider_slug)).must_equal "anthropic"
        end
      end
    end

    it "gathers LLM config when .env missing" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("templates")
          File.write("templates/.env.erb", "<%= llm_env_var_name %>=<%= llm_api_key %>")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["Let's configure your API access.", :green]
          cli.expect :say, nil, [""]
          cli.expect :ask, "sk-ant-test-key", ["Anthropic API key:"]

          prompt = Minitest::Mock.new
          prompt.expect :select, "anthropic", ["Which LLM provider?", Jojo::ProviderHelper.available_providers, {per_page: 15}]

          service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          prompt.verify
          _(File.exist?(".env")).must_equal false  # File not created yet
          _(service.instance_variable_get(:@llm_provider_slug)).must_equal "anthropic"
          _(service.instance_variable_get(:@llm_api_key)).must_equal "sk-ant-test-key"
        end
      end
    end
  end

  describe "#setup_personal_configuration" do
    it "skips when config.yml exists and not force mode" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "seeker_name: Existing")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ config.yml already exists (skipped)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_personal_configuration)

          cli.verify
        end
      end
    end

    it "creates config.yml from template when missing" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
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

          service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
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
      end
    end
  end

  describe "#setup_search_configuration" do
    it "configures search when user selects yes and tavily" do
      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      cli.expect :say, nil, [""]
      prompt.expect :yes?, true, ["Configure web search for company research? (requires Tavily or Serper API)"]
      prompt.expect :select, "tavily", ["Which search provider?", ["tavily", "serper"], Hash]
      cli.expect :ask, "sk-tavily-test", ["Tavily API key:"]

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
      service.send(:setup_search_configuration)

      cli.verify
      prompt.verify
      _(service.instance_variable_get(:@search_provider_slug)).must_equal "tavily"
      _(service.instance_variable_get(:@search_api_key)).must_equal "sk-tavily-test"
      _(service.instance_variable_get(:@search_env_var_name)).must_equal "TAVILY_API_KEY"
    end

    it "configures search when user selects yes and serper" do
      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      cli.expect :say, nil, [""]
      prompt.expect :yes?, true, ["Configure web search for company research? (requires Tavily or Serper API)"]
      prompt.expect :select, "serper", ["Which search provider?", ["tavily", "serper"], Hash]
      cli.expect :ask, "serper-key-123", ["Serper API key:"]

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
      service.send(:setup_search_configuration)

      cli.verify
      prompt.verify
      _(service.instance_variable_get(:@search_provider_slug)).must_equal "serper"
      _(service.instance_variable_get(:@search_api_key)).must_equal "serper-key-123"
      _(service.instance_variable_get(:@search_env_var_name)).must_equal "SERPER_API_KEY"
    end

    it "skips search when user selects no" do
      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      cli.expect :say, nil, [""]
      prompt.expect :yes?, false, ["Configure web search for company research? (requires Tavily or Serper API)"]

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
      service.send(:setup_search_configuration)

      cli.verify
      prompt.verify
      _(service.instance_variable_get(:@search_provider_slug)).must_be_nil
    end
  end

  describe "#write_env_file" do
    it "writes .env with LLM config only when search not configured" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
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

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
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
      end
    end

    it "writes .env with both LLM and search config" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
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

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
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
      end
    end

    it "skips writing when .env already exists in skipped_files" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Create existing .env with real content
          File.write(".env", "ANTHROPIC_API_KEY=original-key")

          cli = Minitest::Mock.new
          # Should NOT expect "Created .env" message

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.instance_variable_set(:@skipped_files, [".env"])
          # Instance vars intentionally nil (not populated when skipped)
          service.instance_variable_set(:@llm_env_var_name, nil)
          service.instance_variable_set(:@llm_api_key, nil)
          service.send(:write_env_file)

          cli.verify
          # File should NOT be overwritten
          _(File.read(".env")).must_equal "ANTHROPIC_API_KEY=original-key"
        end
      end
    end
  end

  describe "#setup_input_files" do
    it "creates inputs directory if missing" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("templates")
          File.write("templates/resume_data.yml", "# JOJO_TEMPLATE_PLACEHOLDER")
          File.write("templates/recommendations.md", "<!-- JOJO_TEMPLATE_PLACEHOLDER -->")
          File.write("templates/default_resume.md.erb", "<!-- JOJO_TEMPLATE_PLACEHOLDER -->")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
          cli.expect :say, nil, [""]
          cli.expect :say, nil, ["Setting up your profile templates...", :green]
          3.times { cli.expect :say, nil, [String, :green] }

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_input_files)

          cli.verify
          _(Dir.exist?("inputs")).must_equal true
          _(Dir.exist?("inputs/templates")).must_equal true
        end
      end
    end

    it "copies template files to inputs/" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("templates")
          File.write("templates/resume_data.yml", "# JOJO_TEMPLATE_PLACEHOLDER\nname: Test")
          File.write("templates/recommendations.md", "<!-- JOJO_TEMPLATE_PLACEHOLDER -->\nRecs")
          File.write("templates/default_resume.md.erb", "<!-- JOJO_TEMPLATE_PLACEHOLDER -->\n<%= name %>")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
          cli.expect :say, nil, [""]
          cli.expect :say, nil, ["Setting up your profile templates...", :green]
          cli.expect :say, nil, ["✓ Created inputs/resume_data.yml (customize with your experience)", :green]
          cli.expect :say, nil, ["✓ Created inputs/recommendations.md (optional - customize or delete)", :green]
          cli.expect :say, nil, ["✓ Created inputs/templates/default_resume.md.erb (resume ERB template)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_input_files)

          cli.verify
          _(File.exist?("inputs/resume_data.yml")).must_equal true
          _(File.read("inputs/resume_data.yml")).must_include "JOJO_TEMPLATE_PLACEHOLDER"
          _(File.exist?("inputs/recommendations.md")).must_equal true
          _(File.read("inputs/recommendations.md")).must_include "JOJO_TEMPLATE_PLACEHOLDER"
          _(File.exist?("inputs/templates/default_resume.md.erb")).must_equal true
          _(File.read("inputs/templates/default_resume.md.erb")).must_include "JOJO_TEMPLATE_PLACEHOLDER"
        end
      end
    end

    it "skips existing files unless force mode" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("inputs")
          FileUtils.mkdir_p("inputs/templates")
          FileUtils.mkdir_p("templates")
          File.write("inputs/resume_data.yml", "Existing data")
          File.write("inputs/recommendations.md", "Existing recs")
          File.write("templates/resume_data.yml", "Template data")
          File.write("templates/recommendations.md", "Recs")
          File.write("templates/default_resume.md.erb", "Template ERB")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
          cli.expect :say, nil, [""]
          cli.expect :say, nil, ["Setting up your profile templates...", :green]
          cli.expect :say, nil, ["✓ inputs/resume_data.yml already exists (skipped)", :green]
          cli.expect :say, nil, ["✓ inputs/recommendations.md already exists (skipped)", :green]
          cli.expect :say, nil, ["✓ Created inputs/templates/default_resume.md.erb (resume ERB template)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_input_files)

          cli.verify
          _(File.read("inputs/resume_data.yml")).must_equal "Existing data"
          _(File.read("inputs/recommendations.md")).must_equal "Existing recs"
        end
      end
    end
  end

  describe "#show_summary" do
    it "displays created files and next steps" do
      cli = Minitest::Mock.new
      service = Jojo::SetupService.new(cli_instance: cli)
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
      cli.expect :say, nil, ["  3. Edit or delete inputs/recommendations.md if not needed"]
      cli.expect :say, nil, ["  4. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

      service.send(:show_summary)

      cli.verify
    end

    it "shows appropriate message when no files created" do
      cli = Minitest::Mock.new
      service = Jojo::SetupService.new(cli_instance: cli)
      service.instance_variable_set(:@created_files, [])
      service.instance_variable_set(:@skipped_files, [".env", "config.yml"])

      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["Setup complete!", :green]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["Next steps:", :cyan]
      cli.expect :say, nil, ["  1. Customize inputs/resume_data.yml with your experience (structured format)"]
      cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
      cli.expect :say, nil, ["  3. Edit or delete inputs/recommendations.md if not needed"]
      cli.expect :say, nil, ["  4. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["💡 Tip: The config.yml file contains resume_data.permissions to control curation."]

      service.send(:show_summary)

      cli.verify
    end
  end

  describe "#warn_if_force_mode" do
    it "prompts for confirmation in force mode" do
      cli = Minitest::Mock.new
      cli.expect :say, nil, ["⚠ WARNING: --force will overwrite existing configuration files!", :yellow]
      cli.expect :say, nil, ["  This will replace: .env, config.yml, and all inputs/ files", :yellow]
      cli.expect :yes?, true, ["Continue?"]

      service = Jojo::SetupService.new(cli_instance: cli, force: true)
      service.send(:warn_if_force_mode)

      cli.verify
    end

    it "exits when user declines force mode" do
      cli = Minitest::Mock.new
      cli.expect :say, nil, ["⚠ WARNING: --force will overwrite existing configuration files!", :yellow]
      cli.expect :say, nil, ["  This will replace: .env, config.yml, and all inputs/ files", :yellow]
      cli.expect :yes?, false, ["Continue?"]

      service = Jojo::SetupService.new(cli_instance: cli, force: true)

      assert_raises(SystemExit) do
        service.send(:warn_if_force_mode)
      end
    end

    it "does nothing when not in force mode" do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli, force: false)
      service.send(:warn_if_force_mode)
      # No expectations, should complete without errors
    end
  end

  describe "#validate_configuration_completeness" do
    it "fails when .env exists but config.yml missing (not force mode)" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write(".env", "ANTHROPIC_API_KEY=test")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✗ Partial configuration detected", :red]
          cli.expect :say, nil, ["  Found: .env", :yellow]
          cli.expect :say, nil, ["  Missing: config.yml", :yellow]
          cli.expect :say, nil, ["", :yellow]
          cli.expect :say, nil, ["Options:", :yellow]
          cli.expect :say, nil, ["  • Run 'jojo setup --force' to recreate all configuration", :yellow]
          cli.expect :say, nil, ["  • Manually create config.yml to match your existing .env setup", :yellow]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)

          assert_raises(SystemExit) do
            service.send(:validate_configuration_completeness)
          end

          cli.verify
        end
      end
    end

    it "fails when config.yml exists but .env missing (not force mode)" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("config.yml", "seeker_name: Test")

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✗ Partial configuration detected", :red]
          cli.expect :say, nil, ["  Found: config.yml", :yellow]
          cli.expect :say, nil, ["  Missing: .env", :yellow]
          cli.expect :say, nil, ["", :yellow]
          cli.expect :say, nil, ["Options:", :yellow]
          cli.expect :say, nil, ["  • Run 'jojo setup --force' to recreate all configuration", :yellow]
          cli.expect :say, nil, ["  • Manually create .env with your API keys", :yellow]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)

          assert_raises(SystemExit) do
            service.send(:validate_configuration_completeness)
          end

          cli.verify
        end
      end
    end

    it "succeeds when both .env and config.yml exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write(".env", "ANTHROPIC_API_KEY=test")
          File.write("config.yml", "seeker_name: Test")

          cli = Object.new
          service = Jojo::SetupService.new(cli_instance: cli, force: false)

          # Should not raise
          service.send(:validate_configuration_completeness)
        end
      end
    end

    it "succeeds when neither .env nor config.yml exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Empty directory - normal setup flow
          cli = Object.new
          service = Jojo::SetupService.new(cli_instance: cli, force: false)

          # Should not raise
          service.send(:validate_configuration_completeness)
        end
      end
    end

    it "proceeds when partial config detected but --force is set" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write(".env", "ANTHROPIC_API_KEY=test")
          # config.yml missing

          cli = Object.new
          service = Jojo::SetupService.new(cli_instance: cli, force: true)

          # Should NOT raise, should proceed silently
          service.send(:validate_configuration_completeness)
        end
      end
    end
  end
end
