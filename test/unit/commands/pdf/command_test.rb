# test/unit/commands/pdf/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/command"

describe Jojo::Commands::Pdf::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {
      "job_description.md" => "Senior Ruby Developer",
      "resume.md" => "Tailored resume content",
      "cover_letter.md" => "Cover letter content"
    })
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::Pdf::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "guard failures" do
    it "exits when employer not found" do
      @mock_cli.expect(:say, nil, [/not found/, :red])
      @mock_cli.expect(:say, nil, [String, :yellow])

      command = Jojo::Commands::Pdf::Command.new(@mock_cli, slug: "nonexistent")

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end
  end

  describe "successful execution" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_converter = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:status_logger, @mock_status_logger)
    end

    it "reports generated PDFs" do
      results = {generated: [:resume, :cover_letter], skipped: []}
      @mock_converter.expect(:generate_all, results)
      @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "complete", generated: 2)

      @mock_cli.expect(:say, nil, ["Generating PDFs for Acme Corp...", :green])
      @mock_cli.expect(:say, nil, ["Resume PDF generated", :green])
      @mock_cli.expect(:say, nil, ["Cover_letter PDF generated", :green])
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

    it "reports skipped PDFs" do
      results = {generated: [:resume], skipped: [:cover_letter]}
      @mock_converter.expect(:generate_all, results)
      @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "complete", generated: 1)

      @mock_cli.expect(:say, nil, ["Generating PDFs for Acme Corp...", :green])
      @mock_cli.expect(:say, nil, ["Resume PDF generated", :green])
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

    it "exits with message when no PDFs generated" do
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
      _(error.status).must_equal 1
      @mock_cli.verify
    end
  end

  describe "logging" do
    before do
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

    it "logs with generated count on success" do
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
  end

  describe "error recovery" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_converter = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:status_logger, @mock_status_logger)
    end

    it "handles PandocNotFoundError" do
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
      _(error.status).must_equal 1
      @mock_cli.verify
    end

    it "displays error message when converter fails" do
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

    it "exits with status 1 on error" do
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
      _(error.status).must_equal 1
    end
  end
end
