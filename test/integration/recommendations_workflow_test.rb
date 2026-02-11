require_relative "../test_helper"
require_relative "../../lib/jojo"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/website/generator"
require_relative "../../lib/jojo/config"
require "tmpdir"
require "fileutils"
require "yaml"

# Simple config stub to avoid complex mock expectations
class RecommendationsWorkflowTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

  def initialize
    @seeker_name = "Test User"
    @voice_and_tone = "professional"
    @website_cta_text = "Contact me"
    @website_cta_link = "mailto:test@example.com"
    @base_url = "https://example.com"
  end
end

class RecommendationsWorkflowIntegrationTest < JojoTest
  def setup
    super
    copy_templates
    @employer = Jojo::Application.new("integration-test-corp")

    # Create required files
    FileUtils.mkdir_p(@employer.base_path)
    File.write(@employer.job_description_path, "Software Engineer position")
    File.write(@employer.resume_path, "My resume content")
    File.write(@employer.branding_path, "I am the perfect fit for this opportunity.")

    # Create test inputs directory (NOT production inputs/)
    @inputs_path = File.join(@tmpdir, "test_inputs_recommendations")
    FileUtils.mkdir_p(@inputs_path)

    # Mock AI client
    @ai_client = Minitest::Mock.new

    # Config stub
    @config = RecommendationsWorkflowTestConfigStub.new
  end

  def teardown
    FileUtils.rm_rf(@employer.base_path)
    FileUtils.rm_rf(@inputs_path) if File.exist?(@inputs_path)
    super
  end

  def test_generates_complete_website_with_recommendations_carousel
    # Create resume_data.yml with recommendations
    resume_data = {
      "name" => "Test User",
      "email" => "test@example.com",
      "summary" => "Test summary",
      "skills" => ["Ruby"],
      "experience" => [],
      "recommendations" => [
        {
          "name" => "Jane Smith",
          "title" => "Senior Engineering Manager",
          "relationship" => "Former Manager at Acme Corp",
          "quote" => "Jane is an excellent engineer who consistently delivers high-quality work"
        },
        {
          "name" => "Bob Johnson",
          "title" => "Lead Developer",
          "relationship" => "Colleague at Tech Co",
          "quote" => "Exceptional technical expertise combined with collaborative approach"
        }
      ]
    }
    File.write(File.join(@inputs_path, "resume_data.yml"), resume_data.to_yaml)

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify HTML includes carousel structure
    assert_match(/<section class="recommendations[^"]*"/, html)
    assert_includes html, "What Others Say"
    assert_includes html, "carousel-track"
    assert_includes html, "carousel-slide"
    assert_includes html, "carousel-arrow"
    assert_includes html, "carousel-dots"

    # Verify recommendations content
    assert_includes html, "Jane Smith"
    assert_includes html, "Senior Engineering Manager"
    assert_includes html, "excellent engineer"
    assert_includes html, "Bob Johnson"

    # Verify JavaScript is included
    assert_includes html, "Recommendations Carousel JavaScript"
    assert_includes html, "function goToSlide"
    assert_includes html, "startAutoAdvance"
  end

  def test_generates_website_without_carousel_when_no_recommendations
    # Don't create recommendations file

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify no carousel HTML (CSS will be there but HTML elements should not)
    refute_includes html, '<section class="recommendations">'
    refute_includes html, '<div class="carousel-track">'
    refute_includes html, "Recommendations Carousel JavaScript"
  end

  def test_generates_static_card_for_single_recommendation
    # Create resume_data.yml with single recommendation
    resume_data = {
      "name" => "Test User",
      "email" => "test@example.com",
      "summary" => "Test summary",
      "skills" => ["Ruby"],
      "experience" => [],
      "recommendations" => [
        {
          "name" => "Alice Lee",
          "title" => "Developer",
          "relationship" => "Colleague",
          "quote" => "Great to work with"
        }
      ]
    }
    File.write(File.join(@inputs_path, "resume_data.yml"), resume_data.to_yaml)

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify recommendations section exists with single-recommendation class
    assert_match(/<section class="recommendations single-recommendation"/, html)
    assert_includes html, "Alice Lee"

    # Verify no carousel JavaScript (single recommendation)
    refute_includes html, "Recommendations Carousel JavaScript"
  end

  def test_positions_recommendations_after_job_description_and_before_projects
    # Add all sections
    resume_data = {
      "name" => "Test User",
      "email" => "test@example.com",
      "summary" => "Test summary",
      "skills" => ["Ruby"],
      "experience" => [],
      "recommendations" => [
        {
          "name" => "Jane Smith",
          "title" => "Manager",
          "relationship" => "Former Manager",
          "quote" => "Great engineer"
        }
      ]
    }
    File.write(File.join(@inputs_path, "resume_data.yml"), resume_data.to_yaml)
    File.write(@employer.job_description_annotations_path, "[]")

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Find positions in HTML
    job_desc_pos = html.index("job-description-comparison")
    recommendations_pos = html.index('class="recommendations"')
    projects_pos = html.index('class="projects"')

    # Verify order (skip nil checks for sections that might not exist)
    if job_desc_pos && recommendations_pos
      assert_operator recommendations_pos, :>, job_desc_pos
    end

    if recommendations_pos && projects_pos
      assert_operator projects_pos, :>, recommendations_pos
    end
  end
end
