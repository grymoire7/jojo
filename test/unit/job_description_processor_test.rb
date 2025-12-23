require_relative '../test_helper'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/ai_client'
require_relative '../../lib/jojo/job_description_processor'
require_relative '../../lib/jojo/prompts/job_description_prompts'

describe Jojo::JobDescriptionProcessor do
  before do
    @employer = Jojo::Employer.new('Test Company')
    @config = Minitest::Mock.new
    @ai_client = Minitest::Mock.new
    @processor = Jojo::JobDescriptionProcessor.new(@employer, @ai_client, verbose: false)

    # Clean up before tests
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create test job description file
    @test_file = 'test/fixtures/test_job.txt'
    FileUtils.mkdir_p('test/fixtures')
    File.write(@test_file, "Senior Ruby Developer\n\nWe are looking for a senior Ruby developer...")
  end

  after do
    # Clean up after tests
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    File.delete(@test_file) if File.exist?(@test_file)
  end

  it "processes job description from file" do
    # Mock AI responses
    @ai_client.expect(:reason, "Clean job description", [String])
    @ai_client.expect(:generate_text, "company_name: Test Company\njob_title: Senior Ruby Developer", [String])

    result = @processor.process(@test_file)

    _(result[:job_description]).must_equal "Clean job description"
    _(result[:job_details]).must_include "Test Company"
    _(File.exist?(@employer.job_description_path)).must_equal true
    _(File.exist?(@employer.job_details_path)).must_equal true

    @ai_client.verify
  end

  it "handles file not found error" do
    error = assert_raises(RuntimeError) do
      @processor.process('nonexistent_file.txt')
    end

    _(error.message).must_include "File not found"
  end

  it "saves raw content when processing URL" do
    # Skip this test if no network or we want unit tests only
    skip "URL processing requires network and mocking"
  end

  it "extracts job description using AI" do
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

  it "extracts key details using AI" do
    @ai_client.expect(:reason, "Job description", [String])
    @ai_client.expect(:generate_text, "company_name: Acme\njob_title: Developer", [String])

    result = @processor.process(@test_file)

    _(result[:job_details]).must_include "company_name"
    _(result[:job_details]).must_include "job_title"

    @ai_client.verify
  end
end
