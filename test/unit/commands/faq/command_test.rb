# test/unit/commands/faq/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/faq/command"

describe Jojo::Commands::Faq::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {
      "job_description.md" => "Senior Ruby Developer",
      "resume.md" => "Tailored resume content"
    })
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::Faq::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "guard failures" do
    it "exits when employer not found" do
      @mock_cli.expect(:say, nil, [/not found/, :red])
      @mock_cli.expect(:say, nil, [String, :yellow])

      command = Jojo::Commands::Faq::Command.new(@mock_cli, slug: "nonexistent")

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "exits when resume not found" do
      FileUtils.rm("applications/acme-corp/resume.md")

      @mock_cli.expect(:say, nil, [/Generating FAQs/, :green])
      @mock_cli.expect(:say, nil, [/resume not found/, :red])

      command = Jojo::Commands::Faq::Command.new(@mock_cli, slug: "acme-corp")

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
      @mock_cli.verify
    end
  end

  describe "successful execution" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new
      @mock_generator = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
      @mock_application.expect(:faq_path, "applications/acme-corp/faq.md")
      @mock_application.expect(:status_logger, @mock_status_logger)
    end

    it "calls generator.generate and reports faq count" do
      faqs = [{q: "Q1", a: "A1"}, {q: "Q2", a: "A2"}, {q: "Q3", a: "A3"}]
      @mock_generator.expect(:generate, faqs)
      @mock_ai_client.expect(:total_tokens_used, 200)
      @mock_status_logger.expect(:log, nil, [], step: :faq, tokens: 200, status: "complete", faq_count: 3)

      @mock_cli.expect(:say, nil, ["Generating FAQs for Acme Corp...", :green])
      @mock_cli.expect(:say, nil, ["Generated 3 FAQs and saved to applications/acme-corp/faq.md", :green])

      command = Jojo::Commands::Faq::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

      @mock_generator.verify
      @mock_cli.verify
    end
  end

  describe "logging" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new
      @mock_generator = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
      @mock_application.expect(:faq_path, "applications/acme-corp/faq.md")
      @mock_application.expect(:status_logger, @mock_status_logger)

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
    end

    it "logs with faq_count on success" do
      faqs = [{q: "Q1", a: "A1"}, {q: "Q2", a: "A2"}]
      @mock_generator.expect(:generate, faqs)
      @mock_ai_client.expect(:total_tokens_used, 350)
      @mock_status_logger.expect(:log, nil, [], step: :faq, tokens: 350, status: "complete", faq_count: 2)

      command = Jojo::Commands::Faq::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

      @mock_status_logger.verify
    end
  end

  describe "error recovery" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new
      @mock_generator = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:resume_path, "applications/acme-corp/resume.md")
      @mock_application.expect(:status_logger, @mock_status_logger)
    end

    it "displays error message when generator fails" do
      @mock_generator.expect(:generate, nil) { raise StandardError, "AI service unavailable" }

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, ["Error generating FAQs: AI service unavailable", :red])
      @mock_status_logger.expect(:log, nil, [], step: :faq, status: "failed", error: "AI service unavailable")

      command = Jojo::Commands::Faq::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "exits with status 1 on error" do
      @mock_generator.expect(:generate, nil) { raise StandardError, "Error" }

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :red])
      @mock_status_logger.expect(:log, nil, [], step: :faq, status: "failed", error: "Error")

      command = Jojo::Commands::Faq::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
    end
  end
end
