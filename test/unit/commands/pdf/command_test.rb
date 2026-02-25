# test/unit/commands/pdf/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/command"

class Jojo::Commands::Pdf::CommandTest < JojoTest
  def setup
    super
    write_test_config
    create_application_fixture("acme-corp", files: {
      "job_description.md" => "Senior Ruby Developer",
      "resume.md" => "Tailored resume content",
      "cover_letter.md" => "Cover letter content"
    })
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    assert_includes Jojo::Commands::Pdf::Command.ancestors, Jojo::Commands::Base
  end

  # -- guard failures --

  def test_exits_when_employer_not_found
    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Pdf::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  # -- successful execution --

  def test_reports_generated_pdfs
    setup_successful_execution_mocks

    results = {generated: [:resume, :cover_letter], skipped: []}
    @mock_converter.expect(:generate_all, results)
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "complete", generated: 2)

    @mock_cli.expect(:say, nil, ["Generating PDFs for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Resume HTML and PDF generated", :green])
    @mock_cli.expect(:say, nil, ["Cover_letter HTML and PDF generated", :green])
    @mock_cli.expect(:say, nil, ["PDF generation complete!", :green])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )
    command.execute

    @mock_converter.verify
    @mock_cli.verify
  end

  def test_reports_skipped_pdfs
    setup_successful_execution_mocks

    results = {generated: [:resume], skipped: [:cover_letter]}
    @mock_converter.expect(:generate_all, results)
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "complete", generated: 1)

    @mock_cli.expect(:say, nil, ["Generating PDFs for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Resume HTML and PDF generated", :green])
    @mock_cli.expect(:say, nil, ["Skipped cover_letter: markdown file not found", :yellow])
    @mock_cli.expect(:say, nil, ["PDF generation complete!", :green])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )
    command.execute

    @mock_cli.verify
  end

  def test_exits_with_message_when_no_pdfs_generated
    setup_successful_execution_mocks

    results = {generated: [], skipped: [:resume, :cover_letter]}
    @mock_converter.expect(:generate_all, results)

    @mock_cli.expect(:say, nil, ["Generating PDFs for Acme Corp...", :green])
    @mock_cli.expect(:say, nil, ["Skipped resume: markdown file not found", :yellow])
    @mock_cli.expect(:say, nil, ["Skipped cover_letter: markdown file not found", :yellow])
    @mock_cli.expect(:say, nil, ["No PDFs generated. Generate resume and cover letter first.", :yellow])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
    @mock_cli.verify
  end

  # -- logging --

  def test_logs_with_generated_count_on_success
    setup_logging_mocks

    results = {generated: [:resume], skipped: []}
    @mock_converter.expect(:generate_all, results)
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "complete", generated: 1)

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )
    command.execute

    @mock_status_logger.verify
  end

  # -- error recovery --

  def test_handles_pandoc_not_found_error
    setup_error_recovery_mocks

    @mock_converter.expect(:generate_all, nil) do
      raise Jojo::Commands::Pdf::PandocChecker::PandocNotFoundError, "Pandoc not installed"
    end
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "failed", error: "Pandoc not installed")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Pandoc not installed", :red])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
    @mock_cli.verify
  end

  def test_handles_wkhtmltopdf_not_found_error
    setup_error_recovery_mocks

    @mock_converter.expect(:generate_all, nil) do
      raise Jojo::Commands::Pdf::WkhtmltopdfChecker::WkhtmltopdfNotFoundError, "wkhtmltopdf is not installed"
    end
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "failed", error: "wkhtmltopdf is not installed")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["wkhtmltopdf is not installed", :red])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
    @mock_cli.verify
  end

  def test_displays_error_message_when_converter_fails
    setup_error_recovery_mocks

    @mock_converter.expect(:generate_all, nil) { raise StandardError, "PDF generation failed" }
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "failed", error: "PDF generation failed")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, ["Error generating PDFs: PDF generation failed", :red])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end

  def test_exits_with_status_1_on_error
    setup_error_recovery_mocks

    @mock_converter.expect(:generate_all, nil) { raise StandardError, "Error" }
    @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "failed", error: "Error")

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :red])

    command = Jojo::Commands::Pdf::Command.new(
      @mock_cli,
      slug: "acme-corp",
      application: @mock_application,
      converter: @mock_converter
    )

    error = assert_raises(SystemExit) { command.execute }
    assert_equal 1, error.status
  end

  private

  def setup_successful_execution_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_converter = Minitest::Mock.new

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:status_logger, @mock_status_logger)
  end

  def setup_logging_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_converter = Minitest::Mock.new

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:status_logger, @mock_status_logger)

    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
    @mock_cli.expect(:say, nil, [String, :green])
  end

  def setup_error_recovery_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_converter = Minitest::Mock.new

    @mock_application.expect(:artifacts_exist?, true)
    @mock_application.expect(:company_name, "Acme Corp")
    @mock_application.expect(:status_logger, @mock_status_logger)
  end
end
