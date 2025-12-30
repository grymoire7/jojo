require_relative '../test_helper'
require_relative '../../lib/jojo/setup_service'

describe 'Setup Integration' do
  it 'completes full setup flow with anthropic provider' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files
        FileUtils.mkdir_p('templates')
        FileUtils.cp(
          File.join(__dir__, '../../templates/.env.erb'),
          'templates/.env.erb'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/config.yml.erb'),
          'templates/config.yml.erb'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/generic_resume.md'),
          'templates/generic_resume.md'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/recommendations.md'),
          'templates/recommendations.md'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/projects.yml'),
          'templates/projects.yml'
        )

        # Mock CLI interactions
        cli = Minitest::Mock.new

        # warn_if_force_mode (skipped - not in force mode)

        # setup_api_configuration
        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :ask, 'anthropic', [/Which LLM provider/]
        cli.expect :ask, 'sk-ant-test123', ["Anthropic API key:"]
        cli.expect :say, nil, ["✓ Created .env", :green]

        # setup_personal_configuration
        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Available models for anthropic:", :cyan]
        cli.expect :say, nil, [String] # model list
        cli.expect :say, nil, [""]
        cli.expect :ask, 'claude-sonnet-4-5', [/Which model for reasoning/]
        cli.expect :ask, 'claude-3-5-haiku-20241022', [/Which model for text generation/]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        # setup_input_files
        cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setting up your profile templates...", :green]
        3.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setup complete!", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Created:"]
        5.times { cli.expect :say, nil, [String] } # 5 created files
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Next steps:", :cyan]
        cli.expect :say, nil, ["  1. Customize inputs/generic_resume.md with your actual experience"]
        cli.expect :say, nil, ["  2. Edit or delete inputs/recommendations.md and inputs/projects.yml if not needed"]
        cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["💡 Tip: Delete the first comment line in each file after customizing."]

        service = Jojo::SetupService.new(cli_instance: cli, force: false)
        service.run

        cli.verify

        # Verify .env
        _(File.exist?('.env')).must_equal true
        env_content = File.read('.env')
        _(env_content).must_include 'ANTHROPIC_API_KEY=sk-ant-test123'

        # Verify config.yml
        _(File.exist?('config.yml')).must_equal true
        config_content = File.read('config.yml')
        _(config_content).must_include 'seeker_name: Test User'
        _(config_content).must_include 'service: anthropic'
        _(config_content).must_include 'model: claude-sonnet-4-5'
        _(config_content).must_include 'model: claude-3-5-haiku-20241022'

        # Verify input files
        _(File.exist?('inputs/generic_resume.md')).must_equal true
        _(File.exist?('inputs/recommendations.md')).must_equal true
        _(File.exist?('inputs/projects.yml')).must_equal true
      end
    end
  end

  it 'completes full setup flow with openai provider' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files (same as above)
        FileUtils.mkdir_p('templates')
        FileUtils.cp(
          File.join(__dir__, '../../templates/.env.erb'),
          'templates/.env.erb'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/config.yml.erb'),
          'templates/config.yml.erb'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/generic_resume.md'),
          'templates/generic_resume.md'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/recommendations.md'),
          'templates/recommendations.md'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/projects.yml'),
          'templates/projects.yml'
        )

        # Mock CLI interactions
        cli = Minitest::Mock.new

        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :ask, 'openai', [/Which LLM provider/]
        cli.expect :ask, 'sk-test-openai', ["Openai API key:"]
        cli.expect :say, nil, ["✓ Created .env", :green]

        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Available models for openai:", :cyan]
        cli.expect :say, nil, [String]
        cli.expect :say, nil, [""]
        cli.expect :ask, 'gpt-4o', [/Which model for reasoning/]
        cli.expect :ask, 'gpt-4o-mini', [/Which model for text generation/]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setting up your profile templates...", :green]
        3.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setup complete!", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Created:"]
        5.times { cli.expect :say, nil, [String] } # 5 created files
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Next steps:", :cyan]
        cli.expect :say, nil, ["  1. Customize inputs/generic_resume.md with your actual experience"]
        cli.expect :say, nil, ["  2. Edit or delete inputs/recommendations.md and inputs/projects.yml if not needed"]
        cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["💡 Tip: Delete the first comment line in each file after customizing."]

        service = Jojo::SetupService.new(cli_instance: cli, force: false)
        service.run

        cli.verify

        # Verify .env
        env_content = File.read('.env')
        _(env_content).must_include 'OPENAI_API_KEY=sk-test-openai'

        # Verify config.yml
        config_content = File.read('config.yml')
        _(config_content).must_include 'service: openai'
        _(config_content).must_include 'model: gpt-4o'
        _(config_content).must_include 'model: gpt-4o-mini'
      end
    end
  end
end
