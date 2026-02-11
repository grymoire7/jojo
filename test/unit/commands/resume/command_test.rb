# test/unit/commands/resume/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/command"

class Jojo::Commands::Resume::CommandTest < JojoTest
  def setup
    super
    write_test_config
    create_application_fixture("acme-corp", files: {
      "job_description.md" => "Senior Ruby Developer"
    })
    create_inputs_fixture(files: {"resume_data.yml" => "name: Test User"})
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    assert_includes Jojo::Commands::Resume::Command.ancestors, Jojo::Commands::Base
  end

  # -- guard failures --

  def test_exits_when_employer_not_found
    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Resume::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_when_resume_data_not_found
    FileUtils.rm("inputs/resume_data.yml")

    @mock_cli.expect(:say, nil, [/Generating resume/, :green])
    @mock_cli.expect(:say, nil, [/Warning.*Research not found/, :yellow])
    @mock_cli.expect(:say, nil, [/Resume data not found/, :red])
    @mock_cli.expect(:say, nil, [/Run 'jojo setup'/, :yellow])

    command = Jojo::Commands::Resume::Command.new(@mock_cli, slug: "acme-corp")

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
    @mock_cli.verify
  end

  def test_warns_but_continues_when_research_not_found
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new
    @mock_generator = Minitest::Mock.new

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:research_path, "applications/acme-corp/research.md")
    @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    @mock_application.expect(:status_logger, @mock_status_logger)

    @mock_generator.expect(:generate, nil)
    @mock_ai_client.expect(:total_tokens_used, 100)
    @mock_status_logger.expect(:log, nil, [], step: :resume, tokens: 100, status: "complete")

    @mock_cli.expect(:say, nil, ["Generating resume for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Warning: Research not found. Resume will be less targeted.", :yellow])
    @mock_cli.expect(:say, nil, [/Resume generated/, :green])

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  # -- successful execution --

  def test_calls_generator_generate
    setup_successful_execution_mocks

    @mock_generator.expect(:generate, nil)
    @mock_ai_client.expect(:total_tokens_used, 200)
    @mock_status_logger.expect(:log, nil, [], step: :resume, tokens: 200, status: "complete")

    @mock_cli.expect(:say, nil, ["Generating resume for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Resume generated and saved to applications/acme-corp/resume.md", :green])

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )
    command.execute

    @mock_generator.verify
  end

  def test_displays_success_message_with_resume_path
    setup_successful_execution_mocks

    @mock_generator.expect(:generate, nil)
    @mock_ai_client.expect(:total_tokens_used, 200)
    @mock_status_logger.expect(:log, nil, [], step: :resume, tokens: 200, status: "complete")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Resume generated and saved to applications/acme-corp/resume.md", :green])

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  # -- logging --

  def test_logs_with_step_tokens_and_status_on_success
    setup_logging_mocks

    @mock_ai_client.expect(:total_tokens_used, 350)
    @mock_status_logger.expect(:log, nil, [], step: :resume, tokens: 350, status: "complete")

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )
    command.execute

    @mock_status_logger.verify
  end

  # -- error recovery --

  def test_displays_error_message_when_generator_fails
    setup_error_recovery_mocks

    @mock_generator.expect(:generate, nil) { raise StandardError, "AI service unavailable" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Error generating resume: AI service unavailable", :red])
    @mock_status_logger.expect(:log, nil, [], step: :resume, status: "failed", error: "AI service unavailable")

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_logs_failure_with_error_message
    setup_error_recovery_mocks

    @mock_generator.expect(:generate, nil) { raise StandardError, "Connection timeout" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])
    @mock_status_logger.expect(:log, nil, [], step: :resume, status: "failed", error: "Connection timeout")

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )

    assert_raises(SystemExit) { command.execute }
    @mock_status_logger.verify
  end

  def test_exits_with_status_1_on_error
    setup_error_recovery_mocks

    @mock_generator.expect(:generate, nil) { raise StandardError, "Error" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])
    @mock_status_logger.expect(:log, nil, [], step: :resume, status: "failed", error: "Error")

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  def test_continues_even_if_logging_fails_during_error_handling
    setup_error_recovery_mocks

    @mock_generator.expect(:generate, nil) { raise StandardError, "Primary error" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Error generating resume: Primary error", :red])

    failing_logger = Object.new
    def failing_logger.log(**_args)
      raise StandardError, "Logging also failed"
    end
    @mock_application.expect(:status_logger, failing_logger)

    command = Jojo::Commands::Resume::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      ai_client: @mock_ai_client,
      generator: @mock_generator
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  # -- generator creation (when not injected) --

  def test_creates_generator_with_correct_dependencies
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new

    File.write("applications/acme-corp/research.md", "Research content")

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:research_path, "applications/acme-corp/research.md")

    generator_created = false
    generator_args = nil

    Jojo::Commands::Resume::Generator.stub :new, ->(employer, ai_client, **opts) {
      generator_created = true
      generator_args = {application: employer, ai_client: ai_client, opts: opts}
      mock_gen = Minitest::Mock.new
      mock_gen.expect(:generate, nil)
      mock_gen
    } do
      @mock_application.expect(:status_logger, @mock_status_logger)
      @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
      @mock_ai_client.expect(:total_tokens_used, 0)
      @mock_status_logger.expect(:log, nil, [], step: :resume, tokens: 0, status: "complete")

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])

      command = Jojo::Commands::Resume::Command.new(
        @mock_cli,
        slug: "acme-corp",
        verbose: true,
        overwrite: true,
        application: @mock_application,
        ai_client: @mock_ai_client
      )
      command.execute
    end

    assert_equal true, generator_created
    assert_equal @mock_application.object_id, generator_args[:application].object_id
    assert_equal @mock_ai_client.object_id, generator_args[:ai_client].object_id
    assert_equal true, generator_args[:opts][:verbose]
    assert_equal true, generator_args[:opts][:overwrite_flag]
    assert_equal @mock_cli.object_id, generator_args[:opts][:cli_instance].object_id
    refute_nil generator_args[:opts][:config]
  end

  private

  def setup_successful_execution_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new
    @mock_generator = Minitest::Mock.new

    # Create research file so no warning is shown
    File.write("applications/acme-corp/research.md", "Research content")

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:research_path, "applications/acme-corp/research.md")
    @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    @mock_application.expect(:status_logger, @mock_status_logger)
  end

  def setup_logging_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new
    @mock_generator = Minitest::Mock.new

    File.write("applications/acme-corp/research.md", "Research content")

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:research_path, "applications/acme-corp/research.md")
    @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    @mock_application.expect(:status_logger, @mock_status_logger)

    @mock_generator.expect(:generate, nil)

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
  end

  def setup_error_recovery_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new
    @mock_generator = Minitest::Mock.new

    File.write("applications/acme-corp/research.md", "Research content")

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:research_path, "applications/acme-corp/research.md")
    @mock_application.expect(:status_logger, @mock_status_logger)
  end
end
