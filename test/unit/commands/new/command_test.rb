# test/unit/commands/new/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/new/command"

class Jojo::Commands::New::CommandTest < JojoTest
  def setup
    super
    write_test_config
    create_inputs_fixture(files: {
      "resume_data.yml" => "name: Test User\n# Modified content"
    })
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    _(Jojo::Commands::New::Command.ancestors).must_include Jojo::Commands::Base
  end

  # -- validation --

  def test_exits_when_resume_data_yml_is_missing
    FileUtils.rm("inputs/resume_data.yml")

    @mock_cli.expect(:say, nil, [/inputs\/resume_data\.yml not found/, :red])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "new-corp")

    error = assert_raises(SystemExit) { command.execute }
    _(error.status).must_equal 1
    @mock_cli.verify
  end

  # -- guard failures --

  def test_exits_if_employer_already_exists
    create_application_fixture("existing", files: {})

    @mock_cli.expect(:say, nil, [/already exists/, :yellow])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "existing")

    error = assert_raises(SystemExit) { command.execute }
    _(error.status).must_equal 1
    @mock_cli.verify
  end

  # -- successful execution --

  def test_creates_employer_directory
    @mock_cli.expect(:say, nil, ["Created application workspace: applications/new-corp", :green])
    @mock_cli.expect(:say, nil, ["\nNext step:", :cyan])
    @mock_cli.expect(:say, nil, ["  jojo job_description -s new-corp -j <job_file_or_url>", :white])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "new-corp")
    command.execute

    _(Dir.exist?("applications/new-corp")).must_equal true
    @mock_cli.verify
  end

  def test_shows_next_step_instructions
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["\nNext step:", :cyan])
    @mock_cli.expect(:say, nil, [/jojo job_description -s test-corp/, :white])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "test-corp")
    command.execute

    @mock_cli.verify
  end
end
