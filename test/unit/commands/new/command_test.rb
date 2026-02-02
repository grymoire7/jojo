# test/unit/commands/new/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/new/command"

describe Jojo::Commands::New::Command do
  before do
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Create inputs directory with resume_data.yml
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\n# Modified content")

    @mock_cli = Minitest::Mock.new
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  it "inherits from Base" do
    _(Jojo::Commands::New::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "creates employer directory" do
    @mock_cli.expect(:say, nil, [/Created/, :green])
    @mock_cli.expect(:say, nil, [/Next step/, :cyan])
    @mock_cli.expect(:say, nil, [String, :white])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "new-corp")
    command.execute

    _(Dir.exist?("employers/new-corp")).must_equal true
    @mock_cli.verify
  end

  it "exits if employer already exists" do
    FileUtils.mkdir_p("employers/existing")

    @mock_cli.expect(:say, nil, [/already exists/, :yellow])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "existing")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end
end
