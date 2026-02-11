# test/unit/commands/research/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/research/generator"

class Jojo::Commands::Research::GeneratorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Commands::Research::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )

    @application.create_directory!

    # Create job description and job details fixtures
    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@application.job_details_path, "company_name: Acme Corp\njob_title: Senior Ruby Developer")
  end

  def teardown
    @config&.verify
    super
  end

  def test_generates_research_from_all_inputs
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

  def test_saves_research_to_file
    web_results = "Acme Corp info..."
    expected_research = "# Company Profile\n\nResearch content..."
    @ai_client.expect(:reason, expected_research, [String])

    @generator.stub(:perform_web_search, web_results) do
      @generator.generate
    end

    _(File.exist?(@application.research_path)).must_equal true
    _(File.read(@application.research_path)).must_equal expected_research

    @ai_client.verify
  end

  def test_handles_missing_job_description
    FileUtils.rm_f(@application.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  def test_continues_when_web_search_fails
    expected_research = "# Company Profile\n\nResearch without web data..."
    @ai_client.expect(:reason, expected_research, [String])

    # Stub web search to return nil (failure)
    @generator.stub(:perform_web_search, nil) do
      result = @generator.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  def test_continues_when_generic_resume_is_missing
    # Create a generator with a nonexistent inputs path
    generator_no_resume = Jojo::Commands::Research::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path("nonexistent")
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

  def test_extracts_company_name_from_job_details
    inputs = @generator.send(:gather_inputs)

    _(inputs[:company_name]).must_equal "Acme Corp"
  end
end
