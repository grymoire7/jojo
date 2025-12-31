require_relative "../test_helper"
require_relative "../../lib/jojo/status_logger"
require "json"

describe Jojo::StatusLogger do
  before do
    @employer = Jojo::Employer.new("test-company")
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
    entry1 = JSON.parse(content.lines[0])
    entry2 = JSON.parse(content.lines[1])

    _(entry1["message"]).must_equal "First message"
    _(entry2["message"]).must_equal "Second message"
  end

  it "includes timestamp in log entry" do
    @logger.log("Test message")

    content = File.read(@employer.status_log_path)
    entry = JSON.parse(content.lines.first)

    _(entry["timestamp"]).must_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
  end

  it "formats log entry as JSON" do
    @logger.log("Test message")

    content = File.read(@employer.status_log_path)
    entry = JSON.parse(content.lines.first)

    _(entry["message"]).must_equal "Test message"
    _(entry["timestamp"]).wont_be_nil
  end

  it "logs step with metadata" do
    @logger.log_step("Job Description Processing", tokens: 1500, status: "complete")

    content = File.read(@employer.status_log_path)
    entry = JSON.parse(content.lines.first)

    _(entry["step"]).must_equal "Job Description Processing"
    _(entry["tokens"]).must_equal 1500
    _(entry["status"]).must_equal "complete"
    _(entry["timestamp"]).wont_be_nil
  end

  it "creates valid JSONL with multiple entries" do
    @logger.log("First message")
    @logger.log("Second message")
    @logger.log_step("Step", status: "complete")

    content = File.read(@employer.status_log_path)
    lines = content.lines

    _(lines.length).must_equal 3

    # Each line should be valid JSON
    lines.each do |line|
      parsed = JSON.parse(line)
      _(parsed).wont_be_nil
    end
  end
end
