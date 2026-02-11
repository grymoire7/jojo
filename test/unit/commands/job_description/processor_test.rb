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

    _(result[:job_description]).must_equal "Clean job description"
    _(result[:job_details]).must_include "Test Company"
    _(File.exist?(@application.job_description_path)).must_equal true
    _(File.exist?(@application.job_details_path)).must_equal true

    @ai_client.verify
  end

  def test_handles_file_not_found_error
    error = assert_raises(Jojo::Commands::JobDescription::Processor::ProcessingError) do
      @processor.process("nonexistent_file.txt")
    end

    _(error.message).must_include "File not found"
  end

  def test_extracts_job_description_using_ai
    raw_content = "Navigation bar\nJob posting: Ruby Developer\nFooter"

    @ai_client.expect(:reason, "Ruby Developer job", [String])
    @ai_client.expect(:generate_text, "company_name: Test\njob_title: Ruby Developer", [String])

    # We need to stub fetch_content method to avoid actual file/URL access
    @processor.stub(:fetch_content, raw_content) do
      result = @processor.process("dummy.txt")
      _(result[:job_description]).must_equal "Ruby Developer job"
    end

    @ai_client.verify
  end

  def test_extracts_key_details_using_ai
    @ai_client.expect(:reason, "Job description", [String])
    @ai_client.expect(:generate_text, "company_name: Acme\njob_title: Developer", [String])

    result = @processor.process(@test_file)

    _(result[:job_details]).must_include "company_name"
    _(result[:job_details]).must_include "job_title"

    @ai_client.verify
  end
end
