require_relative "../../test_helper"
require_relative "../../../lib/jojo/employer"
require_relative "../../../lib/jojo/generators/website_generator"
require_relative "../../../lib/jojo/config"
require "tmpdir"
require "fileutils"
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

describe "WebsiteGenerator with Recommendations" do
  before do
    @employer = Jojo::Employer.new("test-corp")

    # Create required files
    FileUtils.mkdir_p(@employer.base_path)
    File.write(@employer.job_description_path, "Job description")
    File.write(@employer.resume_path, "Resume content")

    # Mock AI client
    @ai_client = Minitest::Mock.new
    @ai_client.expect(:generate_text, "Branding statement", [String])

    # Config stub
    @config = WebsiteGeneratorRecommendationsTestConfigStub.new
  end

  after do
    FileUtils.rm_rf(@employer.base_path)
    FileUtils.rm_rf("test/fixtures/tmp_recommendations_unit") if File.exist?("test/fixtures/tmp_recommendations_unit")
  end

  it "loads recommendations from resume_data_yml" do
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

    inputs_path = "test/fixtures/tmp_recommendations_unit"
    FileUtils.mkdir_p(inputs_path)
    File.write(File.join(inputs_path, "resume_data.yml"), resume_data_content)

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    recommendations = generator.send(:load_recommendations)

    _(recommendations.length).must_equal 1
    _(recommendations[0][:name]).must_equal "Jane Smith"
    _(recommendations[0][:quote]).must_equal "Great engineer"
  end

  it "handles missing resume_data_yml gracefully" do
    inputs_path = "test/fixtures/tmp_recommendations_unit"
    FileUtils.mkdir_p(inputs_path)
    # No resume_data.yml file

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    recommendations = generator.send(:load_recommendations)
    _(recommendations).must_be_nil
  end
end
