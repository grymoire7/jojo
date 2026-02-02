# test/unit/commands/cover_letter/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/cover_letter/command"

describe Jojo::Commands::CoverLetter::Command do
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
    _(Jojo::Commands::CoverLetter::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "exits when employer not found" do
    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::CoverLetter::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end
end
