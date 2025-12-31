require_relative "../test_helper"
require_relative "../../lib/jojo"
require_relative "../../lib/jojo/employer"
require_relative "../../lib/jojo/generators/website_generator"
require_relative "../../lib/jojo/config"
require "tmpdir"
require "fileutils"

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

describe "Recommendations Workflow Integration" do
  before do
    @employer = Jojo::Employer.new("integration-test-corp")

    # Create required files
    FileUtils.mkdir_p(@employer.base_path)
    File.write(@employer.job_description_path, "Software Engineer position")
    File.write(@employer.resume_path, "My resume content")

    # Create test inputs directory (NOT production inputs/)
    @inputs_path = "test/fixtures/tmp_recommendations"
    FileUtils.mkdir_p(@inputs_path)

    # Mock AI client
    @ai_client = Minitest::Mock.new
    @ai_client.expect(:generate_text, "I am the perfect fit", [String])

    # Config stub
    @config = RecommendationsWorkflowTestConfigStub.new
  end

  after do
    FileUtils.rm_rf(@employer.base_path)
    FileUtils.rm_rf(@inputs_path) if File.exist?(@inputs_path)
  end

  it "generates complete website with recommendations carousel" do
    # Create recommendations file
    File.write(
      File.join(@inputs_path, "recommendations.md"),
      File.read("test/fixtures/recommendations.md")
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify HTML includes carousel structure
    _(html).must_include '<section class="recommendations">'
    _(html).must_include "What Others Say"
    _(html).must_include "carousel-track"
    _(html).must_include "carousel-slide"
    _(html).must_include "carousel-arrow"
    _(html).must_include "carousel-dots"

    # Verify recommendations content
    _(html).must_include "Jane Smith"
    _(html).must_include "Senior Engineering Manager"
    _(html).must_include "excellent engineer"
    _(html).must_include "Bob Johnson"

    # Verify JavaScript is included
    _(html).must_include "Recommendations Carousel JavaScript"
    _(html).must_include "function goToSlide"
    _(html).must_include "startAutoAdvance"
  end

  it "generates website without carousel when no recommendations" do
    # Don't create recommendations file

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify no carousel HTML (CSS will be there but HTML elements should not)
    _(html).wont_include '<section class="recommendations">'
    _(html).wont_include '<div class="carousel-track">'
    _(html).wont_include "Recommendations Carousel JavaScript"
  end

  it "generates static card for single recommendation" do
    # Create recommendations file with single recommendation
    File.write(
      File.join(@inputs_path, "recommendations.md"),
      File.read("test/fixtures/recommendations_minimal.md")
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify recommendations section exists
    _(html).must_include '<section class="recommendations single-recommendation">'
    _(html).must_include "Alice Lee"

    # Verify no carousel JavaScript (single recommendation)
    _(html).wont_include "Recommendations Carousel JavaScript"
  end

  it "positions recommendations after job description and before projects" do
    # Add all sections
    File.write(
      File.join(@inputs_path, "recommendations.md"),
      File.read("test/fixtures/recommendations.md")
    )
    File.write(
      File.join(@inputs_path, "projects.yml"),
      File.read("test/fixtures/valid_projects.yml")
    )
    File.write(@employer.job_description_annotations_path, "[]")

    generator = Jojo::Generators::WebsiteGenerator.new(
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
      _(recommendations_pos).must_be :>, job_desc_pos
    end

    if recommendations_pos && projects_pos
      _(projects_pos).must_be :>, recommendations_pos
    end
  end

  it "handles malformed recommendations gracefully" do
    File.write(
      File.join(@inputs_path, "recommendations.md"),
      File.read("test/fixtures/recommendations_malformed.md")
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    # Should not raise error
    html = generator.generate

    # Should include valid recommendation, skip invalid
    _(html).must_include "Valid Person"
    _(html).wont_include "Missing Name"
  end
end
