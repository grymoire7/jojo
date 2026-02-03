# test/unit/commands/job_description/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/job_description/command"

describe Jojo::Commands::JobDescription::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {})
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::JobDescription::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "guard failures" do
    it "exits when no slug specified and no state" do
      @mock_cli.expect(:say, nil, [/No application specified/, :red])

      command = Jojo::Commands::JobDescription::Command.new(@mock_cli, job: "job.txt")

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "exits when employer directory does not exist" do
      @mock_cli.expect(:say, nil, [/does not exist/, :red])

      command = Jojo::Commands::JobDescription::Command.new(@mock_cli, slug: "nonexistent", job: "job.txt")

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end
  end

  describe "successful execution" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_employer = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new

      @mock_employer.expect(:base_path, "employers/acme-corp")
      @mock_employer.expect(:status_logger, @mock_status_logger)
    end

    it "processes job description and creates artifacts" do
      @mock_employer.expect(:create_artifacts, nil) do |job_source, ai_client, **kwargs|
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
        employer: @mock_employer,
        ai_client: @mock_ai_client
      )
      command.execute

      @mock_employer.verify
      @mock_cli.verify
    end
  end

  describe "logging" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_employer = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new

      @mock_employer.expect(:base_path, "employers/acme-corp")
      @mock_employer.expect(:status_logger, @mock_status_logger)
      @mock_employer.expect(:create_artifacts, nil, [String, Object], overwrite_flag: false, cli_instance: Object, verbose: false)

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :green])
    end

    it "logs with token count on success" do
      @mock_ai_client.expect(:total_tokens_used, 250)
      @mock_status_logger.expect(:log, nil, [], step: :job_description, tokens: 250, status: "complete")

      command = Jojo::Commands::JobDescription::Command.new(
        @mock_cli,
        slug: "acme-corp",
        job: "job.txt",
        employer: @mock_employer,
        ai_client: @mock_ai_client
      )
      command.execute

      @mock_status_logger.verify
    end
  end

  describe "error recovery" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_employer = Minitest::Mock.new
      @mock_ai_client = Minitest::Mock.new

      @mock_employer.expect(:base_path, "employers/acme-corp")
      @mock_employer.expect(:status_logger, @mock_status_logger)
    end

    it "displays error message when create_artifacts fails" do
      @mock_employer.expect(:create_artifacts, nil) { raise StandardError, "Failed to process job" }
      @mock_status_logger.expect(:log, nil, [], step: :job_description, status: "failed", error: "Failed to process job")

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, ["Error processing job description: Failed to process job", :red])

      command = Jojo::Commands::JobDescription::Command.new(
        @mock_cli,
        slug: "acme-corp",
        job: "job.txt",
        employer: @mock_employer,
        ai_client: @mock_ai_client
      )

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "exits with status 1 on error" do
      @mock_employer.expect(:create_artifacts, nil) { raise StandardError, "Error" }
      @mock_status_logger.expect(:log, nil, [], step: :job_description, status: "failed", error: "Error")

      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, [String, :red])

      command = Jojo::Commands::JobDescription::Command.new(
        @mock_cli,
        slug: "acme-corp",
        job: "job.txt",
        employer: @mock_employer,
        ai_client: @mock_ai_client
      )

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
    end
  end
end
