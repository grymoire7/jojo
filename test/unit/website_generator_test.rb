require_relative '../test_helper'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/generators/website_generator'
require 'fileutils'

describe Jojo::Generators::WebsiteGenerator do
  # Simple config stub for testing
  class ConfigStub
    attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

    def initialize
      @seeker_name = "John Doe"
      @voice_and_tone = "professional and friendly"
      @website_cta_text = "Get in Touch"
      @website_cta_link = "https://calendly.com/test/30min"
      @base_url = "https://example.com"
    end
  end

  before do
    @employer = Jojo::Employer.new('Test Company')
    @ai_client = Minitest::Mock.new
    @config = ConfigStub.new

    # Clean up test directory
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    FileUtils.rm_f('inputs/branding_image.jpg')
  end

  it "initializes with required parameters" do
    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    _(generator.employer).must_equal @employer
    _(generator.template_name).must_equal 'default'
    _(generator.verbose).must_equal false
  end

  it "initializes with custom template" do
    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      template: 'modern'
    )

    _(generator.template_name).must_equal 'modern'
  end

  it "raises error when job description is missing" do
    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    error = _ { generator.generate }.must_raise RuntimeError
    _(error.message).must_include "Job description not found"
  end

  it "raises error when resume is missing" do
    # Create job description but not resume
    File.write(@employer.job_description_path, "Job description content...")

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    error = _ { generator.generate }.must_raise RuntimeError
    _(error.message).must_include "Resume not found"
  end

  it "generates website with all inputs" do
    # Create required files
    File.write(@employer.job_description_path, "Senior Ruby Developer...")
    File.write(@employer.resume_path, "# John Doe\n\nExperienced developer...")
    File.write(@employer.research_path, "Company research...")

    expected_branding = "I'm perfect for this role because..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    result = generator.generate

    _(result).must_include "<!DOCTYPE html>"
    _(result).must_include expected_branding
    _(File.exist?(@employer.index_html_path)).must_equal true

    @ai_client.verify
  end

  it "generates website without optional research" do
    # Create only required files
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")

    expected_branding = "Branding statement..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: true  # Test verbose mode
    )

    # Should not raise error
    result = generator.generate

    _(result).must_include expected_branding
    _(File.exist?(@employer.index_html_path)).must_equal true

    @ai_client.verify
  end

  it "raises error when template doesn't exist" do
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")

    expected_branding = "Branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      template: 'nonexistent'
    )

    error = _ { generator.generate }.must_raise RuntimeError
    _(error.message).must_include "Template not found"
    _(error.message).must_include "nonexistent"
  end

  it "copies branding image when it exists" do
    # Create required files
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")

    # Create branding image
    FileUtils.mkdir_p('inputs')
    File.write('inputs/branding_image.jpg', 'fake image data')

    expected_branding = "Branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    generator.generate

    # Verify image was copied
    website_image = File.join(@employer.website_path, 'branding_image.jpg')
    _(File.exist?(website_image)).must_equal true
    _(File.read(website_image)).must_equal 'fake image data'

    @ai_client.verify
  end

  it "skips branding image when it doesn't exist" do
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")

    expected_branding = "Branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    # Should not raise error
    generator.generate

    # Verify no image file in website directory
    website_image = File.join(@employer.website_path, 'branding_image.jpg')
    _(File.exist?(website_image)).must_equal false

    @ai_client.verify
  end

  it "renders template with all variables" do
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")

    expected_branding = "I'm the perfect candidate for Test Company."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    html = generator.generate

    # Verify all template variables are present
    _(html).must_include "John Doe"  # seeker_name
    _(html).must_include "Test Company"  # company_name
    _(html).must_include expected_branding
    _(html).must_include "Get in Touch"  # cta_text
    _(html).must_include "https://calendly.com/test/30min"  # cta_link
    _(html).must_include "https://example.com"  # base_url
    _(html).must_include "test-company"  # company_slug

    @ai_client.verify
  end

  it "handles job details when present" do
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")
    File.write(@employer.job_details_path, YAML.dump({ 'job_title' => 'Senior Developer' }))

    expected_branding = "Branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config
    )

    html = generator.generate

    _(html).must_include "Senior Developer"

    @ai_client.verify
  end

  it "handles missing CTA link gracefully" do
    File.write(@employer.job_description_path, "Job description...")
    File.write(@employer.resume_path, "Resume content...")

    @config.website_cta_link = nil

    expected_branding = "Branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: true  # Should log warning
    )

    html = generator.generate

    # CTA section should not be rendered
    _(html).wont_include '<section class="cta-section">'

    @ai_client.verify
  end
end
