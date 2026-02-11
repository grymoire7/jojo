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
    refute_equal true, File.exist?(@application.status_log_path)

    @logger.log("Test message")

    assert_equal true, File.exist?(@application.status_log_path)
  end

  def test_appends_to_existing_status_log
    @logger.log("First message")
    @logger.log("Second message")

    content = File.read(@application.status_log_path)
    entry1 = JSON.parse(content.lines[0])
    entry2 = JSON.parse(content.lines[1])

    assert_equal "First message", entry1["message"]
    assert_equal "Second message", entry2["message"]
  end

  def test_includes_timestamp_in_log_entry
    @logger.log("Test message")

    content = File.read(@application.status_log_path)
    entry = JSON.parse(content.lines.first)

    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, entry["timestamp"])
  end

  def test_formats_log_entry_as_json
    @logger.log("Test message")

    content = File.read(@application.status_log_path)
    entry = JSON.parse(content.lines.first)

    assert_equal "Test message", entry["message"]
    refute_nil entry["timestamp"]
  end

  def test_logs_step_with_metadata
    @logger.log(step: "Job Description Processing", tokens: 1500, status: "complete")

    content = File.read(@application.status_log_path)
    entry = JSON.parse(content.lines.first)

    assert_equal "Job Description Processing", entry["step"]
    assert_equal 1500, entry["tokens"]
    assert_equal "complete", entry["status"]
    refute_nil entry["timestamp"]
  end

  def test_creates_valid_jsonl_with_multiple_entries
    @logger.log("First message")
    @logger.log("Second message")
    @logger.log(step: "Step", status: "complete")

    content = File.read(@application.status_log_path)
    lines = content.lines

    assert_equal 3, lines.length

    lines.each do |line|
      parsed = JSON.parse(line)
      refute_nil parsed
    end
  end
end
