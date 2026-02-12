# test/unit/commands/job_description/processor_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/ai_client"
require_relative "../../../../lib/jojo/commands/job_description/processor"
require_relative "../../../../lib/jojo/commands/job_description/prompt"

class Jojo::Commands::JobDescription::ProcessorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-company")
    @config = Minitest::Mock.new
    @ai_client = Minitest::Mock.new
    @processor = Jojo::Commands::JobDescription::Processor.new(@application, @ai_client, verbose: false)

    @application.create_directory!

    # Create test job description file
    @test_file = "test_job.txt"
    File.write(@test_file, "Senior Ruby Developer\n\nWe are looking for a senior Ruby developer...")
  end

  def test_processes_job_description_from_file
    # Mock AI responses
    @ai_client.expect(:reason, "Clean job description", [String])
    @ai_client.expect(:generate_text, "company_name: Test Company\njob_title: Senior Ruby Developer", [String])

    result = @processor.process(@test_file)

    assert_equal "Clean job description", result[:job_description]
    assert_includes result[:job_details], "Test Company"
    assert_equal true, File.exist?(@application.job_description_path)
    assert_equal true, File.exist?(@application.job_details_path)

    @ai_client.verify
  end

  def test_handles_file_not_found_error
    error = assert_raises(Jojo::Commands::JobDescription::Processor::ProcessingError) do
      @processor.process("nonexistent_file.txt")
    end

    assert_includes error.message, "File not found"
  end

  def test_extracts_job_description_using_ai
    raw_content = "Navigation bar\nJob posting: Ruby Developer\nFooter"

    @ai_client.expect(:reason, "Ruby Developer job", [String])
    @ai_client.expect(:generate_text, "company_name: Test\njob_title: Ruby Developer", [String])

    # We need to stub fetch_content method to avoid actual file/URL access
    @processor.stub(:fetch_content, raw_content) do
      result = @processor.process("dummy.txt")
      assert_equal "Ruby Developer job", result[:job_description]
    end

    @ai_client.verify
  end

  def test_extracts_key_details_using_ai
    @ai_client.expect(:reason, "Job description", [String])
    @ai_client.expect(:generate_text, "company_name: Acme\njob_title: Developer", [String])

    result = @processor.process(@test_file)

    assert_includes result[:job_details], "company_name"
    assert_includes result[:job_details], "job_title"

    @ai_client.verify
  end

  def test_identifies_urls_correctly
    assert Jojo::UrlDetector.url?("https://example.com/job")
    assert Jojo::UrlDetector.url?("http://example.com/job")
    refute Jojo::UrlDetector.url?("path/to/file.txt")
    refute Jojo::UrlDetector.url?("job_description.md")
  end

  def test_saves_raw_content_for_url_source
    @ai_client.expect(:reason, "Clean description", [String])
    @ai_client.expect(:generate_text, "company_name: Test", [String])

    markdown_content = "# Job Posting\nContent from web"

    @processor.stub(:fetch_from_url, markdown_content) do
      @processor.process("https://example.com/job")
    end

    assert File.exist?(@application.job_description_raw_path)
    assert_equal markdown_content, File.read(@application.job_description_raw_path)

    @ai_client.verify
  end

  def test_uses_overwrite_check_when_cli_instance_provided
    overwrite_calls = []

    mock_cli = Object.new
    mock_cli.define_singleton_method(:with_overwrite_check) do |path, _flag, &block|
      overwrite_calls << path
      block.call
    end

    processor = Jojo::Commands::JobDescription::Processor.new(
      @application, @ai_client,
      overwrite_flag: true,
      cli_instance: mock_cli,
      verbose: false
    )

    @ai_client.expect(:reason, "Clean description", [String])
    @ai_client.expect(:generate_text, "company_name: Test", [String])

    processor.process(@test_file)

    assert_equal 2, overwrite_calls.length
    assert_includes overwrite_calls, @application.job_description_path
    assert_includes overwrite_calls, @application.job_details_path

    @ai_client.verify
  end
end
