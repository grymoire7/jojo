# test/unit/commands/resume/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/command"

describe Jojo::Commands::Resume::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {
      "job_description.md" => "Senior Ruby Developer"
    })
    create_inputs_fixture(files: {"resume_data.yml" => "name: Test User"})
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::Resume::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "guard failures" do
    it "exits when employer not found" do
      @mock_cli.expect(:say, nil, [/not found/, :red])
      @mock_cli.expect(:say, nil, [String, :yellow])

      command = Jojo::Commands::Resume::Command.new(@mock_cli, slug: "nonexistent")

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "exits when resume data not found" do
      FileUtils.rm("inputs/resume_data.yml")

      @mock_cli.expect(:say, nil, [/Generating resume/, :green])
      @mock_cli.expect(:say, nil, [/Warning.*Research not found/, :yellow])
      @mock_cli.expect(:say, nil, [/Resume data not found/, :red])
      @mock_cli.expect(:say, nil, [/Run 'jojo setup'/, :yellow])

      command = Jojo::Commands::Resume::Command.new(@mock_cli, slug: "acme-corp")

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
      @mock_cli.verify
    end

    it "warns but continues when research not found" do
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
  end

  describe "successful execution" do
    before do
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

    it "calls generator.generate" do
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

    it "displays success message with resume path" do
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
  end

  describe "logging" do
    before do
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

    it "logs with step, tokens, and status on success" do
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
  end

  describe "error recovery" do
    before do
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

    it "displays error message when generator fails" do
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

    it "logs failure with error message" do
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

    it "exits with status 1 on error" do
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
      _(error.status).must_equal 1
    end

    it "continues even if logging fails during error handling" do
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
      _(error.status).must_equal 1
    end
  end

  describe "generator creation (when not injected)" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new

      File.write("applications/acme-corp/research.md", "Research content")

      @mock_application.expect(:artifacts_exist?, true)
      @mock_application.expect(:company_name, "Acme Corp")
      @mock_application.expect(:research_path, "applications/acme-corp/research.md")
    end

    it "creates generator with correct dependencies" do
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

      _(generator_created).must_equal true
      _(generator_args[:application].object_id).must_equal @mock_application.object_id
      _(generator_args[:ai_client].object_id).must_equal @mock_ai_client.object_id
      _(generator_args[:opts][:verbose]).must_equal true
      _(generator_args[:opts][:overwrite_flag]).must_equal true
      _(generator_args[:opts][:cli_instance].object_id).must_equal @mock_cli.object_id
      _(generator_args[:opts][:config]).wont_be_nil
    end
  end
end
