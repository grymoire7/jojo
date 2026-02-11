require_relative "../test_helper"
require_relative "../../lib/jojo/status_logger"
require "json"

class StatusLoggerTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-company")
    @logger = @application.status_logger
    @application.create_directory!
  end

  def test_creates_status_log_file_on_first_write
    _(File.exist?(@application.status_log_path)).wont_equal true

    @logger.log("Test message")

    _(File.exist?(@application.status_log_path)).must_equal true
  end

  def test_appends_to_existing_status_log
    @logger.log("First message")
    @logger.log("Second message")

    content = File.read(@application.status_log_path)
    entry1 = JSON.parse(content.lines[0])
    entry2 = JSON.parse(content.lines[1])

    _(entry1["message"]).must_equal "First message"
    _(entry2["message"]).must_equal "Second message"
  end

  def test_includes_timestamp_in_log_entry
    @logger.log("Test message")

    content = File.read(@application.status_log_path)
    entry = JSON.parse(content.lines.first)

    _(entry["timestamp"]).must_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
  end

  def test_formats_log_entry_as_json
    @logger.log("Test message")

    content = File.read(@application.status_log_path)
    entry = JSON.parse(content.lines.first)

    _(entry["message"]).must_equal "Test message"
    _(entry["timestamp"]).wont_be_nil
  end

  def test_logs_step_with_metadata
    @logger.log(step: "Job Description Processing", tokens: 1500, status: "complete")

    content = File.read(@application.status_log_path)
    entry = JSON.parse(content.lines.first)

    _(entry["step"]).must_equal "Job Description Processing"
    _(entry["tokens"]).must_equal 1500
    _(entry["status"]).must_equal "complete"
    _(entry["timestamp"]).wont_be_nil
  end

  def test_creates_valid_jsonl_with_multiple_entries
    @logger.log("First message")
    @logger.log("Second message")
    @logger.log(step: "Step", status: "complete")

    content = File.read(@application.status_log_path)
    lines = content.lines

    _(lines.length).must_equal 3

    lines.each do |line|
      parsed = JSON.parse(line)
      _(parsed).wont_be_nil
    end
  end
end
