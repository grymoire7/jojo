# test/unit/commands/configure/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/configure/command"

class Jojo::Commands::Configure::CommandTest < JojoTest
  def setup
    super
    write_test_config
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    assert_includes Jojo::Commands::Configure::Command.ancestors, Jojo::Commands::Base
  end

  # -- successful execution --

  def test_calls_service_run
    @mock_service = Minitest::Mock.new
    @mock_service.expect(:run, nil)

    command = Jojo::Commands::Configure::Command.new(
      @mock_cli,
      service: @mock_service
    )
    command.execute

    @mock_service.verify
  end

  # -- error recovery --

  def test_displays_error_message_when_service_fails
    @mock_service = Minitest::Mock.new
    @mock_service.expect(:run, nil) { raise StandardError, "Configuration error" }

    @mock_cli.expect(:say, nil, ["Configure failed: Configuration error", :red])

    command = Jojo::Commands::Configure::Command.new(
      @mock_cli,
      service: @mock_service
    )

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_with_status_1_on_error
    @mock_service = Minitest::Mock.new
    @mock_service.expect(:run, nil) { raise StandardError, "Error" }

    @mock_cli.expect(:say, nil, [String, :red])

    command = Jojo::Commands::Configure::Command.new(
      @mock_cli,
      service: @mock_service
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  def test_allows_clean_exit_from_service
    @mock_service = Minitest::Mock.new
    @mock_service.expect(:run, nil) { exit 0 }

    command = Jojo::Commands::Configure::Command.new(
      @mock_cli,
      service: @mock_service
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 0, error.status
  end
end
