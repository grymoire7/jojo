require_relative "../test_helper"
require_relative "../../lib/jojo/employer"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/job_description_processor"
require_relative "../../lib/jojo/prompts/job_description_prompts"

describe Jojo::JobDescriptionProcessor do
  before do
    @employer = Jojo::Employer.new("test-company")
    @config = Minitest::Mock.new
    @ai_client = Minitest::Mock.new
    @processor = Jojo::JobDescriptionProcessor.new(@employer, @ai_client, verbose: false)

    # Clean up before tests
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!
  end

  after do
    # Clean up after tests
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  # Note: No tests currently implemented
  # URL processing tests require network mocking to be added
end
