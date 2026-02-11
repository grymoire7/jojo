# test/unit/commands/job_description/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/job_description/command"

class Jojo::Commands::JobDescription::CommandTest < JojoTest
  def setup
    super
    write_test_config
    create_application_fixture("acme-corp", files: {})
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    assert_includes Jojo::Commands::JobDescription::Command.ancestors, Jojo::Commands::Base
  end

  # -- guard failures --

  def test_exits_when_no_slug_specified_and_no_state
    @mock_cli.expect(:say, nil, [/No application specified/, :red])

    command = Jojo::Commands::JobDescription::Command.new(@mock_cli, job: "job.txt")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_when_employer_directory_does_not_exist
    @mock_cli.expect(:say, nil, [/does not exist/, :red])

    command = Jojo::Commands::JobDescription::Command.new(@mock_cli, slug: "nonexistent", job: "job.txt")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  # -- successful execution --

  def test_processes_job_description_and_creates_artifacts
    setup_successful_execution_mocks

    @mock_application.expect(:create_artifacts, nil) do |job_source, ai_client, **kwargs|
      job_source == "job.txt" && kwargs[:overwrite_flag] == false && kwargs[:verbose] == false
    end
    @mock_ai_client.expect(:total_tokens_used, 150)
    @mock_status_logger.expect(:log, nil, [], step: :job_description, tokens: 150, status: "complete")

    @mock_cli.expect(:say, nil, ["Processing job description for: acme-corp", :green])
    @mock_cli.expect(:say, nil, ["-> Job description processed and saved", :green])
    @mock_cli.expect(:say, nil, ["-> Job details extracted and saved", :green])

    command = Jojo::Commands::JobDescription::Command.new(
      @mock_cli,
      slug: "acme-corp",
      job: "job.txt",
      application: @mock_application,
      ai_client: @mock_ai_client
    )
    command.execute

    @mock_application.verify
    @mock_cli.verify
  end

  # -- logging --

  def test_logs_with_token_count_on_success
    setup_logging_mocks

    @mock_ai_client.expect(:total_tokens_used, 250)
    @mock_status_logger.expect(:log, nil, [], step: :job_description, tokens: 250, status: "complete")

    command = Jojo::Commands::JobDescription::Command.new(
      @mock_cli,
      slug: "acme-corp",
      job: "job.txt",
      application: @mock_application,
      ai_client: @mock_ai_client
    )
    command.execute

    @mock_status_logger.verify
  end

  # -- error recovery --

  def test_displays_error_message_when_create_artifacts_fails
    setup_error_recovery_mocks

    @mock_application.expect(:create_artifacts, nil) { raise StandardError, "Failed to process job" }
    @mock_status_logger.expect(:log, nil, [], step: :job_description, status: "failed", error: "Failed to process job")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Error processing job description: Failed to process job", :red])

    command = Jojo::Commands::JobDescription::Command.new(
      @mock_cli,
      slug: "acme-corp",
      job: "job.txt",
      application: @mock_application,
      ai_client: @mock_ai_client
    )

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_with_status_1_on_error
    setup_error_recovery_mocks

    @mock_application.expect(:create_artifacts, nil) { raise StandardError, "Error" }
    @mock_status_logger.expect(:log, nil, [], step: :job_description, status: "failed", error: "Error")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])

    command = Jojo::Commands::JobDescription::Command.new(
      @mock_cli,
      slug: "acme-corp",
      job: "job.txt",
      application: @mock_application,
      ai_client: @mock_ai_client
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  private

  def setup_successful_execution_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new

    @mock_application.expect(:base_path, "applications/acme-corp")
    @mock_application.expect(:status_logger, @mock_status_logger)
  end

  def setup_logging_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new

    @mock_application.expect(:base_path, "applications/acme-corp")
    @mock_application.expect(:status_logger, @mock_status_logger)
    @mock_application.expect(:create_artifacts, nil, [String, Object], overwrite_flag: false, cli_instance: Object, verbose: false)

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
  end

  def setup_error_recovery_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new

    @mock_application.expect(:base_path, "applications/acme-corp")
    @mock_application.expect(:status_logger, @mock_status_logger)
  end
end
