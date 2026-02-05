require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/commands/job_description/processor"
require_relative "../../lib/jojo/commands/job_description/prompt"

describe Jojo::Commands::JobDescription::Processor do
  before do
    @employer = Jojo::Employer.new("test-company")
    @config = Minitest::Mock.new
    @ai_client = Minitest::Mock.new
    @processor = Jojo::Commands::JobDescription::Processor.new(@employer, @ai_client, verbose: false)

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
