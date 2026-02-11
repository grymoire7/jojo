# test/unit/commands/website/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/website/command"

class Jojo::Commands::Website::CommandTest < JojoTest
  def setup
    super
    write_test_config
    create_application_fixture("acme-corp", files: {
      "job_description.md" => "Senior Ruby Developer",
      "resume.md" => "Tailored resume content",
      "research.md" => "Company research"
    })
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    _(Jojo::Commands::Website::Command.ancestors).must_include Jojo::Commands::Base
  end

  # guard failures

  def test_exits_when_employer_not_found
    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Website::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_when_resume_not_found
    FileUtils.rm("applications/acme-corp/resume.md")

    @mock_cli.expect(:say, nil, [/Generating website/, :green])
    @mock_cli.expect(:say, nil, [/Resume not found/, :red])

    command = Jojo::Commands::Website::Command.new(@mock_cli, slug: "acme-corp")

    error = assert_raises(SystemExit) { command.execute }
    _(error.status).must_equal 1
    @mock_cli.verify
  end

  def test_warns_but_continues_when_research_not_found
    FileUtils.rm("applications/acme-corp/research.md")

    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    mock_application.expect(:research_path, "applications/acme-corp/research.md")
    mock_application.expect(:index_html_path, "applications/acme-corp/index.html")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, nil)
    mock_ai_client.expect(:total_tokens_used, 100)
    mock_status_logger.expect(:log, nil, [], step: :website, tokens: 100, status: "complete", metadata: {template: "default"})

    @mock_cli.expect(:say, nil, ["Generating website for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Warning: Research not found. Website will be less targeted.", :yellow])
    @mock_cli.expect(:say, nil, [/Website generated/, :green])

    command = Jojo::Commands::Website::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    @mock_cli.verify
  end

  # successful execution

  def test_calls_generator_generate
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    mock_application.expect(:research_path, "applications/acme-corp/research.md")
    mock_application.expect(:index_html_path, "applications/acme-corp/index.html")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, nil)
    mock_ai_client.expect(:total_tokens_used, 200)
    mock_status_logger.expect(:log, nil, [], step: :website, tokens: 200, status: "complete", metadata: {template: "default"})

    @mock_cli.expect(:say, nil, ["Generating website for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Website generated and saved to applications/acme-corp/index.html", :green])

    command = Jojo::Commands::Website::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    mock_generator.verify
  end

  # logging

  def test_logs_with_template_metadata_on_success
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    mock_application.expect(:research_path, "applications/acme-corp/research.md")
    mock_application.expect(:index_html_path, "applications/acme-corp/index.html")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, nil)

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])

    mock_ai_client.expect(:total_tokens_used, 350)
    mock_status_logger.expect(:log, nil, [], step: :website, tokens: 350, status: "complete", metadata: {template: "default"})

    command = Jojo::Commands::Website::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )
    command.execute

    mock_status_logger.verify
  end

  # error recovery

  def test_displays_error_message_when_generator_fails
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    mock_application.expect(:research_path, "applications/acme-corp/research.md")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, nil) { raise StandardError, "AI service unavailable" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Error generating website: AI service unavailable", :red])
    mock_status_logger.expect(:log, nil, [], step: :website, status: "failed", error: "AI service unavailable")

    command = Jojo::Commands::Website::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_with_status_1_on_error
    mock_status_logger = Minitest::Mock.new
    mock_application = Minitest::Mock.new
    mock_ai_client = Minitest::Mock.new
    mock_generator = Minitest::Mock.new

    mock_application.expect(:artifacts_exist?, true)
    mock_application.expect(:company_name, "Acme Corp")
    mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
    mock_application.expect(:research_path, "applications/acme-corp/research.md")
    mock_application.expect(:status_logger, mock_status_logger)

    mock_generator.expect(:generate, nil) { raise StandardError, "Error" }

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])
    mock_status_logger.expect(:log, nil, [], step: :website, status: "failed", error: "Error")

    command = Jojo::Commands::Website::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: mock_application,
      ai_client: mock_ai_client,
      generator: mock_generator
    )

    error = assert_raises(SystemExit) { command.execute }
    _(error.status).must_equal 1
  end
end
