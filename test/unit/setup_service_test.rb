require_relative '../test_helper'
require_relative '../../lib/jojo/setup_service'
require 'thor'

describe Jojo::SetupService do
  describe '#initialize' do
    it 'stores cli_instance and force flag' do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli, force: true)
      _(service.instance_variable_get(:@cli)).must_be_same_as cli
      _(service.instance_variable_get(:@force)).must_equal true
    end

    it 'defaults force to false' do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli)
      _(service.instance_variable_get(:@force)).must_equal false
    end

    it 'initializes tracking arrays' do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli)
      _(service.instance_variable_get(:@created_files)).must_equal []
      _(service.instance_variable_get(:@skipped_files)).must_equal []
    end
  end

  describe '#setup_api_configuration' do
    it 'skips when .env exists and not force mode' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('.env', 'ANTHROPIC_API_KEY=existing')

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ .env already exists (skipped)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          _(File.read('.env')).must_equal 'ANTHROPIC_API_KEY=existing'
        end
      end
    end

    it 'creates .env when missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          cli = Minitest::Mock.new
          cli.expect :say, nil, ["Let's configure your API access.", :green]
          cli.expect :ask, 'sk-ant-test-key', ["Anthropic API key:"]
          cli.expect :say, nil, ["✓ Created .env", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          _(File.exist?('.env')).must_equal true
          _(File.read('.env')).must_include 'ANTHROPIC_API_KEY=sk-ant-test-key'
        end
      end
    end
  end

  describe '#setup_personal_configuration' do
    it 'skips when config.yml exists and not force mode' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', 'seeker_name: Existing')

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ config.yml already exists (skipped)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_personal_configuration)

          cli.verify
        end
      end
    end

    it 'creates config.yml from template when missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/config.yml.erb', 'seeker_name: <%= seeker_name %>')

          cli = Minitest::Mock.new
          cli.expect :ask, 'Tracy Atteberry', ["Your name:"]
          cli.expect :ask, 'https://example.com', ["Your website base URL (e.g., https://yourname.com):"]
          cli.expect :say, nil, ["✓ Created config.yml", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_personal_configuration)

          cli.verify
          _(File.exist?('config.yml')).must_equal true
          _(File.read('config.yml')).must_include 'Tracy Atteberry'
        end
      end
    end
  end
end
