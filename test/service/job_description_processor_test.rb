require_relative '../test_helper'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/ai_client'
require_relative '../../lib/jojo/job_description_processor'
require_relative '../../lib/jojo/prompts/job_description_prompts'

describe Jojo::JobDescriptionProcessor do
  before do
    @employer = Jojo::Employer.new('test-company')
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

  it "saves raw content when processing URL" do
    # Skip this test if no network or we want unit tests only
    skip "URL processing requires network and mocking"
  end
end
