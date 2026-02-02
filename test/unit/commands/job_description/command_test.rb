# test/unit/commands/job_description/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/job_description/command"

describe Jojo::Commands::JobDescription::Command do
  before do
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Create config
    File.write("config.yml", <<~YAML)
      seeker_name: "Test User"
      base_url: "https://example.com"
      reasoning_ai_service: openai
      reasoning_ai_model: gpt-4
      text_generation_ai_service: openai
      text_generation_ai_model: gpt-4
    YAML

    @mock_cli = Minitest::Mock.new
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  it "inherits from Base" do
    _(Jojo::Commands::JobDescription::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "exits when no slug specified and no state" do
    @mock_cli.expect(:say, nil, [/No application specified/, :red])

    command = Jojo::Commands::JobDescription::Command.new(@mock_cli, job: "job.txt")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  it "exits when employer directory does not exist" do
    @mock_cli.expect(:say, nil, [/does not exist/, :red])

    command = Jojo::Commands::JobDescription::Command.new(@mock_cli, slug: "nonexistent", job: "job.txt")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end
end
