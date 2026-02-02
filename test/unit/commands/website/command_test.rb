# test/unit/commands/website/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/website/command"

describe Jojo::Commands::Website::Command do
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

    # Create employer with required files
    FileUtils.mkdir_p("employers/acme-corp")
    File.write("employers/acme-corp/job_description.md", "Senior Ruby Developer")

    @mock_cli = Minitest::Mock.new
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  it "inherits from Base" do
    _(Jojo::Commands::Website::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "exits when employer not found" do
    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Website::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  it "exits when resume not found" do
    @mock_cli.expect(:say, nil, [/Generating website/, :green])
    @mock_cli.expect(:say, nil, [/Resume not found/, :red])

    command = Jojo::Commands::Website::Command.new(@mock_cli, slug: "acme-corp")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  it "warns when research not found" do
    # Create resume file
    File.write("employers/acme-corp/resume.md", "Test resume content")

    @mock_cli.expect(:say, nil, [/Generating website/, :green])
    @mock_cli.expect(:say, nil, [/Research not found/, :yellow])
    # Will fail later when branding.md is not found

    command = Jojo::Commands::Website::Command.new(@mock_cli, slug: "acme-corp")

    # Expecting it to eventually fail since branding.md doesn't exist
    # We just want to verify the warning is shown first
    @mock_cli.expect(:say, nil, [/Error generating website/, :red])

    assert_raises(SystemExit) { command.execute }
  end
end
