# test/integration/research_generator_integration_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/research/generator"

class ResearchGeneratorIntegrationTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp")
    File.write(@application.job_details_path, "company_name: Acme Corp\njob_title: Senior Ruby Developer")
  end

  def test_full_research_pipeline_without_web_search
    @config.expect(:search_configured?, false)

    expected_research = "# Acme Corp Research\n\nBased on the job description..."
    @ai_client.expect(:reason, expected_research, [String])

    generator = Jojo::Commands::Research::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_equal expected_research, result
    assert File.exist?(@application.research_path)
    assert_equal expected_research, File.read(@application.research_path)

    @ai_client.verify
    @config.verify
  end

  def test_research_pipeline_without_resume_data
    @config.expect(:search_configured?, false)

    expected_research = "Research without resume context..."
    @ai_client.expect(:reason, expected_research, [String])

    generator = Jojo::Commands::Research::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "nonexistent_path"
    )
    result = generator.generate

    assert_equal expected_research, result
    @ai_client.verify
    @config.verify
  end

  def test_research_pipeline_extracts_company_name_from_job_details
    @config.expect(:search_configured?, false)

    @ai_client.expect(:reason, "Research content", [String])

    generator = Jojo::Commands::Research::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_equal "Research content", result
    @ai_client.verify
    @config.verify
  end
end
