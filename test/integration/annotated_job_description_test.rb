require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/annotate/generator"
require_relative "../../lib/jojo/commands/website/generator"

# Simple config stub to avoid complex mock expectations
class IntegrationTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

  def initialize
    @seeker_name = "John Doe"
    @voice_and_tone = "professional"
    @website_cta_text = "Contact Me"
    @website_cta_link = "mailto:john@example.com"
    @base_url = "https://john.example.com"
  end
end

class AnnotatedJobDescriptionIntegrationTest < JojoTest
  def setup
    super
    copy_templates
    @employer = Jojo::Application.new("techcorp")
    @ai_client = Minitest::Mock.new
    @config = IntegrationTestConfigStub.new

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create fixtures
    @job_description = "We need 5+ years of Ruby experience and knowledge of distributed systems. PostgreSQL expertise required."
    @resume = "# John Doe\n\nSenior Ruby developer with 7 years building web applications.\nExperience with PostgreSQL and Redis.\nBuilt distributed message queue system."

    File.write(@employer.job_description_path, @job_description)
    File.write(@employer.job_details_path, "company_name: TechCorp\nposition_title: Senior Ruby Developer\n")
    File.write(@employer.resume_path, @resume)
    File.write(@employer.branding_path, "I'm a great fit for TechCorp...")
  end

  def teardown
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    super
  end

  def test_generates_annotated_website_from_job_description_and_resume
    # Generate annotations
    annotation_generator = Jojo::Commands::Annotate::Generator.new(@employer, @ai_client, verbose: false)

    annotations_json = JSON.generate([
      {text: "5+ years of Ruby", match: "Built Ruby apps for 7 years", tier: "strong"},
      {text: "distributed systems", match: "Built distributed message queue system", tier: "strong"},
      {text: "PostgreSQL", match: "Experience with PostgreSQL and Redis", tier: "moderate"}
    ])

    @ai_client.expect(:reason, annotations_json, [String])
    annotation_generator.generate
    @ai_client.verify

    # Generate website with annotations
    website_generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )

    html = website_generator.generate

    # Verify annotation section exists
    _(html).must_include "Compare Me to the Job Description"
    _(html).must_include '<div id="annotation-tooltip"'

    # Verify annotations are injected
    _(html).must_include '<span class="annotated" data-tier="strong" data-match="Built Ruby apps for 7 years">5+ years of Ruby</span>'
    _(html).must_include '<span class="annotated" data-tier="strong" data-match="Built distributed message queue system">distributed systems</span>'
    _(html).must_include '<span class="annotated" data-tier="moderate" data-match="Experience with PostgreSQL and Redis">PostgreSQL</span>'

    # Verify legend
    _(html).must_include "Strong match"
    _(html).must_include "Moderate match"
    _(html).must_include "Worth a mention"

    # Verify JavaScript present
    _(html).must_include "function showTooltip"
    _(html).must_include "annotation.dataset.match"

    @ai_client.verify
  end

  def test_website_works_without_annotations_graceful_degradation
    # Don't generate annotations

    website_generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )

    html = website_generator.generate

    # Verify annotation section NOT present
    _(html).wont_include "Compare Me to the Job Description"
    _(html).wont_include '<div id="annotation-tooltip"'

    # But website still works
    _(html).must_include "Am I a good match for TechCorp?"
    _(html).must_include "I'm a great fit for TechCorp..."

    @ai_client.verify
  end
end
