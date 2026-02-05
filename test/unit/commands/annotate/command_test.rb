# test/unit/commands/annotate/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/annotate/command"

describe Jojo::Commands::Annotate::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {
      "job_description.md" => "5+ years Python",
      "resume.md" => "7 years Python experience"
    })
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::Annotate::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "guard failures" do
    it "exits when employer not found" do
      @mock_cli.expect(:say, nil, [/not found/, :red])
      @mock_cli.expect(:say, nil, [String, :yellow])

      command = Jojo::Commands::Annotate::Command.new(@mock_cli, slug: "nonexistent")

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end
  end

  describe "successful execution" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new
      @mock_generator = Minitest::Mock.new

      # Employer expectations for guard and output
      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:job_description_annotations_path, "applications/acme-corp/job_description_annotations.json")
      @mock_application.expect(:status_logger, @mock_status_logger)
    end

    it "calls generator with generate" do
      @mock_generator.expect(:generate, [{requirement: "Python", evidence: "7 years"}])
      @mock_ai_client.expect(:total_tokens_used, 150)
      @mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 150, status: "complete")

      # Expect all say calls
      @mock_cli.expect(:say, nil, ["Generating annotations for Acme Corp...", :green])
      @mock_cli.expect(:say, nil, ["Generated 1 annotations", :green])
      @mock_cli.expect(:say, nil, ["  Saved to: applications/acme-corp/job_description_annotations.json", :green])

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

      @mock_generator.verify
    end

    it "reports correct annotation count" do
      annotations = [
        {requirement: "Python", evidence: "7 years"},
        {requirement: "AWS", evidence: "3 years"},
        {requirement: "Docker", evidence: "5 years"}
      ]
      @mock_generator.expect(:generate, annotations)
      @mock_ai_client.expect(:total_tokens_used, 500)
      @mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 500, status: "complete")

      @mock_cli.expect(:say, nil, ["Generating annotations for Acme Corp...", :green])
      @mock_cli.expect(:say, nil, ["Generated 3 annotations", :green])
      @mock_cli.expect(:say, nil, [String, :green])

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

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
      @mock_application.expect(:job_description_annotations_path, "path/to/annotations.json")
      @mock_application.expect(:status_logger, @mock_status_logger)

      @mock_generator.expect(:generate, [{requirement: "test"}])

      # Stub CLI say calls
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
    end

    it "logs with step, tokens, and status on success" do
      @mock_ai_client.expect(:total_tokens_used, 250)
      @mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 250, status: "complete")

      command = Jojo::Commands::Annotate::Command.new(
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

  describe "user output" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new
      @mock_generator = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Test Company")
      @mock_application.expect(:job_description_annotations_path, "applications/test/annotations.json")
      @mock_application.expect(:status_logger, @mock_status_logger)

      @mock_generator.expect(:generate, [{req: "a"}, {req: "b"}])
      @mock_ai_client.expect(:total_tokens_used, 100)
      @mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 100, status: "complete")
    end

    it "displays starting message with company name" do
      @mock_cli.expect(:say, nil, ["Generating annotations for Test Company...", :green])
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "test",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

      @mock_cli.verify
    end

    it "displays annotation count on completion" do
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, ["Generated 2 annotations", :green])
      @mock_cli.expect(:say, nil, [String, :green])

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "test",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

      @mock_cli.verify
    end

    it "displays save path on completion" do
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, ["  Saved to: applications/test/annotations.json", :green])

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "test",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )
      command.execute

      @mock_cli.verify
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
      @mock_application.expect(:status_logger, @mock_status_logger)
    end

    it "displays error message when generator fails" do
      @mock_generator.expect(:generate, nil) { raise StandardError, "AI service unavailable" }

      @mock_cli.expect(:say, nil, [String, :green]) # starting message
      @mock_cli.expect(:say, nil, ["Error generating annotations: AI service unavailable", :red])
      @mock_status_logger.expect(:log, nil, [], step: :annotate, status: "failed", error: "AI service unavailable")

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "logs failure with error message" do
      @mock_generator.expect(:generate, nil) { raise StandardError, "Connection timeout" }

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :red])
      @mock_status_logger.expect(:log, nil, [], step: :annotate, status: "failed", error: "Connection timeout")

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )

      assert_raises(SystemExit) { command.execute }
      @mock_status_logger.verify
    end

    it "exits with status 1 on error" do
      @mock_generator.expect(:generate, nil) { raise StandardError, "Error" }

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :red])
      @mock_status_logger.expect(:log, nil, [], step: :annotate, status: "failed", error: "Error")

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
    end

    it "continues even if logging fails during error handling" do
      @mock_generator.expect(:generate, nil) { raise StandardError, "Primary error" }

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, ["Error generating annotations: Primary error", :red])

      # Create a logger that raises when log is called
      failing_logger = Object.new
      def failing_logger.log(**_args)
        raise StandardError, "Logging also failed"
      end
      @mock_application.expect(:status_logger, failing_logger)

      command = Jojo::Commands::Annotate::Command.new(
        @mock_cli,
        slug: "acme-corp",
        application: @mock_application,
        ai_client: @mock_ai_client,
        generator: @mock_generator
      )

      # Should still exit, not crash from logging error
      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
    end
  end

  describe "generator creation (when not injected)" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
    end

    it "creates generator with correct dependencies" do
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
        @mock_application.expect(:status_logger, @mock_status_logger)
        @mock_application.expect(:job_description_annotations_path, "path/to/file.json")
        @mock_ai_client.expect(:total_tokens_used, 0)
        @mock_status_logger.expect(:log, nil, [], step: :annotate, tokens: 0, status: "complete")

        @mock_cli.expect(:say, nil, [String, :green])
        @mock_cli.expect(:say, nil, [String, :green])
        @mock_cli.expect(:say, nil, [String, :green])

        command = Jojo::Commands::Annotate::Command.new(
          @mock_cli,
          slug: "acme-corp",
          verbose: true,
          overwrite: true,
          application: @mock_application,
          ai_client: @mock_ai_client
        )
        command.execute
      end

      _(generator_created).must_equal true
      _(generator_args[:application].object_id).must_equal @mock_application.object_id
      _(generator_args[:ai_client].object_id).must_equal @mock_ai_client.object_id
      _(generator_args[:opts][:verbose]).must_equal true
      _(generator_args[:opts][:overwrite_flag]).must_equal true
      _(generator_args[:opts][:cli_instance].object_id).must_equal @mock_cli.object_id
    end
  end
end
