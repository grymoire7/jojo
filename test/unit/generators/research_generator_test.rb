require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/research_generator'
require_relative '../../../lib/jojo/prompts/research_prompt'

describe Jojo::Generators::ResearchGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::ResearchGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: 'test/fixtures'
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create job description and job details fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.job_details_path, "company_name: Acme Corp\njob_title: Senior Ruby Developer")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @config.verify if @config
  end

  it "generates research from all inputs" do
    # Mock web search results
    web_results = "Acme Corp is a leading tech company..."

    # Mock AI response
    expected_research = "# Company Profile\n\nAcme Corp is..."
    @ai_client.expect(:reason, expected_research, [String])

    # Stub web search
    @generator.stub(:perform_web_search, web_results) do
      result = @generator.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  it "saves research to file" do
    web_results = "Acme Corp info..."
    expected_research = "# Company Profile\n\nResearch content..."
    @ai_client.expect(:reason, expected_research, [String])

    @generator.stub(:perform_web_search, web_results) do
      @generator.generate
    end

    _(File.exist?(@employer.research_path)).must_equal true
    _(File.read(@employer.research_path)).must_equal expected_research

    @ai_client.verify
  end

  it "handles missing job description" do
    FileUtils.rm_f(@employer.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  it "continues when web search fails" do
    expected_research = "# Company Profile\n\nResearch without web data..."
    @ai_client.expect(:reason, expected_research, [String])

    # Stub web search to return nil (failure)
    @generator.stub(:perform_web_search, nil) do
      result = @generator.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  it "continues when generic resume is missing" do
    # Create a generator with a nonexistent inputs path
    generator_no_resume = Jojo::Generators::ResearchGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: 'test/fixtures/nonexistent'
    )

    web_results = "Acme Corp info..."
    expected_research = "# Company Profile\n\nResearch content..."
    @ai_client.expect(:reason, expected_research, [String])

    generator_no_resume.stub(:perform_web_search, web_results) do
      result = generator_no_resume.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  it "extracts company name from job details" do
    inputs = @generator.send(:gather_inputs)

    _(inputs[:company_name]).must_equal "Acme Corp"
  end
end
