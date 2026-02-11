# test/unit/commands/website/generator_recommendations_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/website/generator"
require_relative "../../../../lib/jojo/config"
require "yaml"

# Simple config stub to avoid complex mock expectations
class WebsiteGeneratorRecommendationsTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

  def initialize
    @seeker_name = "Test User"
    @voice_and_tone = "professional"
    @website_cta_text = "Get in touch"
    @website_cta_link = nil
    @base_url = "https://example.com"
  end
end

class Jojo::Commands::Website::GeneratorRecommendationsTest < JojoTest
  def setup
    super
    copy_templates
    @application = Jojo::Application.new("test-corp")

    # Create required files
    FileUtils.mkdir_p(@application.base_path)
    File.write(@application.job_description_path, "Job description")
    File.write(@application.resume_path, "Resume content")

    # Mock AI client
    @ai_client = Minitest::Mock.new
    @ai_client.expect(:generate_text, "Branding statement", [String])

    # Config stub
    @config = WebsiteGeneratorRecommendationsTestConfigStub.new
  end

  def teardown
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
    tmp_recs_path = fixture_path("tmp_recommendations_unit")
    FileUtils.rm_rf(tmp_recs_path) if File.exist?(tmp_recs_path)
    super
  end

  def test_loads_recommendations_from_resume_data_yml
    resume_data_content = {
      "name" => "Test User",
      "email" => "test@example.com",
      "summary" => "Test summary",
      "skills" => ["Ruby"],
      "experience" => [],
      "recommendations" => [
        {
          "name" => "Jane Smith",
          "title" => "Engineering Manager",
          "relationship" => "Former Manager",
          "quote" => "Great engineer"
        }
      ]
    }.to_yaml

    inputs_path = fixture_path("tmp_recommendations_unit")
    FileUtils.mkdir_p(inputs_path)
    File.write(File.join(inputs_path, "resume_data.yml"), resume_data_content)

    generator = Jojo::Commands::Website::Generator.new(
      @application,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    recommendations = generator.send(:load_recommendations)

    _(recommendations.length).must_equal 1
    _(recommendations[0][:name]).must_equal "Jane Smith"
    _(recommendations[0][:quote]).must_equal "Great engineer"
  end

  def test_handles_missing_resume_data_yml_gracefully
    inputs_path = fixture_path("tmp_recommendations_unit")
    FileUtils.mkdir_p(inputs_path)
    # No resume_data.yml file

    generator = Jojo::Commands::Website::Generator.new(
      @application,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    recommendations = generator.send(:load_recommendations)
    _(recommendations).must_be_nil
  end
end
