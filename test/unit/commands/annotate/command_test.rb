# test/unit/commands/annotate/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/annotate/command"

class Jojo::Commands::Annotate::CommandTest < JojoTest
  def setup
    super
    write_test_config
    create_application_fixture("acme-corp", files: {
      "job_description.md" => "5+ years Python",
      "resume.md" => "7 years Python experience"
    })
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    assert_includes Jojo::Commands::Annotate::Command.ancestors, Jojo::Commands::Base
  end

  # --- guard failures ---

  def test_exits_when_employer_not_found
    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Annotate::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  # --- successful execution ---

  def test_calls_generator_with_generate
    mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_successful_execution_mocks

    mock_generator.expect(:generate, [{requirement: "Python", evidence: "7 years"}])
    mock_ai_client.expect(:total_tokens_used, 150)
    mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 150, status: "complete")

    # Expect all say calls
    @mock_cli.expect(:say, nil, ["Generating annotations for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Generated 1 annotations", :green])
    @mock_cli.expect(:say, nil, ["  Saved to: applications/acme-corp/job_description_annotations.json", :green])

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    mock_generator.verify
  end

  def test_reports_correct_annotation_count
    mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_successful_execution_mocks

    annotations = [
      {requirement: "Python", evidence: "7 years"},
      {requirement: "AWS", evidence: "3 years"},
      {requirement: "Docker", evidence: "5 years"}
    ]
    mock_generator.expect(:generate, annotations)
    mock_ai_client.expect(:total_tokens_used, 500)
    mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 500, status: "complete")

    @mock_cli.expect(:say, nil, ["Generating annotations for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Generated 3 annotations", :green])
    @mock_cli.expect(:say, nil, [String, :green])

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  # --- logging ---

  def test_logs_with_step_tokens_and_status_on_success
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:job_description_annotations_path, "path/to/annotations.json")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, [{requirement: "test"}])

    # Stub CLI say calls
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])

    mock_ai_client.expect(:total_tokens_used, 250)
    mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 250, status: "complete")

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    mock_status_logger.verify
  end

  # --- user output ---

  def test_displays_starting_message_with_company_name
    _mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_user_output_mocks

    @mock_cli.expect(:say, nil, ["Generating annotations for Test Company...", :green])
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "test",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  def test_displays_annotation_count_on_completion
    _mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_user_output_mocks

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Generated 2 annotations", :green])
    @mock_cli.expect(:say, nil, [String, :green])

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "test",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  def test_displays_save_path_on_completion
    _mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_user_output_mocks

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["  Saved to: applications/test/annotations.json", :green])

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "test",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  # --- error recovery ---

  def test_displays_error_message_when_generator_fails
    mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_error_recovery_mocks

    mock_generator.expect(:generate, nil) { raise StandardError, "AI service unavailable" }

    @mock_cli.expect(:say, nil, [String, :green]) # starting message
    @mock_cli.expect(:say, nil, ["Error generating annotations: AI service unavailable", :red])
    mock_status_logger.expect(:log, nil, [], step: :annotate, status: "failed", error: "AI service unavailable")

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_logs_failure_with_error_message
    mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_error_recovery_mocks

    mock_generator.expect(:generate, nil) { raise StandardError, "Connection timeout" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])
    mock_status_logger.expect(:log, nil, [], step: :annotate, status: "failed", error: "Connection timeout")

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )

    assert_raises(SystemExit) { command.execute }
    mock_status_logger.verify
  end

  def test_exits_with_status_1_on_error
    mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_error_recovery_mocks

    mock_generator.expect(:generate, nil) { raise StandardError, "Error" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])
    mock_status_logger.expect(:log, nil, [], step: :annotate, status: "failed", error: "Error")

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  def test_continues_even_if_logging_fails_during_error_handling
    _mock_status_logger, mock_application, mock_ai_client, mock_generator = setup_error_recovery_mocks

    mock_generator.expect(:generate, nil) { raise StandardError, "Primary error" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Error generating annotations: Primary error", :red])

    # Create a logger that raises when log is called
    failing_logger = Object.new
    def failing_logger.log(**_args)
      raise StandardError, "Logging also failed"
    end
    mock_application.expect(:status_logger, failing_logger)

    command = Jojo::Commands::Annotate::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )

    # Should still exit, not crash from logging error
    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  # --- generator creation (when not injected) ---

  def test_creates_generator_with_correct_dependencies
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")

    generator_created = false
    generator_args = nil

    # Stub Generator.new to capture args
    Jojo::Commands::Annotate::Generator.stub :new, ->(employer, ai_client, **opts) {
      generator_created = true
      generator_args = {application: employer, ai_client: ai_client, opts: opts}
      mock_gen = Minitest::Mock.new
      mock_gen.expect(:generate, [])
      mock_gen
    } do
      mock_application.expect(:status_logger, mock_status_logger)
      mock_application.expect(:job_description_annotations_path, "path/to/file.json")
      mock_ai_client.expect(:total_tokens_used, 0)
      mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 0, status: "complete")

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        verbose: true,
        overwrite: true,
        application: mock_application,
        ai_client: mock_ai_client
      )
      command.execute
    end

    assert_equal true, generator_created
    assert_equal mock_application.object_id, generator_args[:application].object_id
    assert_equal mock_ai_client.object_id, generator_args[:ai_client].object_id
    assert_equal true, generator_args[:opts][:verbose]
    assert_equal true, generator_args[:opts][:overwrite_flag]
    assert_equal @mock_cli.object_id, generator_args[:opts][:cli_instance].object_id
  end

  private

  def setup_successful_execution_mocks
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    # Employer expectations for guard and output
    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:job_description_annotations_path, "applications/acme-corp/job_description_annotations.json")
    mock_application.expect(:status_logger, mock_status_logger)

    [mock_status_logger, mock_application, mock_ai_client, mock_generator]
  end

  def setup_user_output_mocks
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Test Company")
    mock_application.expect(:job_description_annotations_path, "applications/test/annotations.json")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, [{req: "a"}, {req: "b"}])
    mock_ai_client.expect(:total_tokens_used, 100)
    mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 100, status: "complete")

    [mock_status_logger, mock_application, mock_ai_client, mock_generator]
  end

  def setup_error_recovery_mocks
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:status_logger, mock_status_logger)

    [mock_status_logger, mock_application, mock_ai_client, mock_generator]
  end
end
