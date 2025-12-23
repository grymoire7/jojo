require_relative '../test_helper'
require_relative '../../lib/jojo/status_logger'

describe Jojo::StatusLogger do
  before do
    @employer = Jojo::Employer.new('Test Company')
    @logger = Jojo::StatusLogger.new(@employer)

    # Clean up before tests
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "creates status log file on first write" do
    _(File.exist?(@employer.status_log_path)).wont_equal true

    @logger.log("Test message")

    _(File.exist?(@employer.status_log_path)).must_equal true
  end

  it "appends to existing status log" do
    @logger.log("First message")
    @logger.log("Second message")

    content = File.read(@employer.status_log_path)
    _(content).must_include "First message"
    _(content).must_include "Second message"
  end

  it "includes timestamp in log entry" do
    @logger.log("Test message")

    content = File.read(@employer.status_log_path)
    _(content).must_match /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
  end

  it "formats log entry as markdown bold timestamp" do
    @logger.log("Test message")

    content = File.read(@employer.status_log_path)
    _(content).must_match /\*\*\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\*\*: Test message/
  end

  it "logs step with metadata" do
    @logger.log_step("Job Description Processing", tokens: 1500, status: "complete")

    content = File.read(@employer.status_log_path)
    _(content).must_include "Job Description Processing"
    _(content).must_include "Tokens: 1500"
    _(content).must_include "Status: complete"
  end
end
