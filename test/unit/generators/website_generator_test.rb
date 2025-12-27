require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/website_generator'
require_relative '../../../lib/jojo/prompts/website_prompt'

describe Jojo::Generators::WebsiteGenerator do
  # Simple config stub to avoid complex mock expectations
  class UnitTestConfigStub
    attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

    def initialize
      @seeker_name = "Jane Doe"
      @voice_and_tone = "professional and friendly"
      @website_cta_text = "Schedule a Call"
      @website_cta_link = "https://calendly.com/janedoe/30min"
      @base_url = "https://janedoe.com"
    end
  end

  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = UnitTestConfigStub.new
    @generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: 'test/fixtures'
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.resume_path, "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer...")
    File.write(@employer.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates website with all inputs" do
    expected_branding = "I'm a perfect fit for Acme Corp because...\n\nMy experience aligns perfectly..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    _(result).must_include "Am I a good match for Acme Corp?"
    _(result).must_include "I'm a perfect fit for Acme Corp because..."
    _(result).must_include "My experience aligns perfectly..."
    _(result).must_include "Schedule a Call"
    _(result).must_include "https://calendly.com/janedoe/30min"

    @ai_client.verify
  end

  it "saves website to index.html" do
    expected_branding = "Branding statement content..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    @generator.generate

    _(File.exist?(@employer.index_html_path)).must_equal true
    content = File.read(@employer.index_html_path)
    _(content).must_include expected_branding
    _(content).must_include "<!DOCTYPE html>"
    _(content).must_include "</html>"

    @ai_client.verify
  end

  it "generates website with minimal inputs (no research, no job_details)" do
    FileUtils.rm_f(@employer.research_path)

    expected_branding = "Branding statement without research..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    # Should not raise error
    result = @generator.generate
    _(result).must_include "Branding statement without research"

    @ai_client.verify
  end

  it "generates website with custom template" do
    # Create test template
    FileUtils.mkdir_p('templates/website')
    File.write('templates/website/modern.html.erb', '<html><body><h1><%= seeker_name %></h1></body></html>')

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, @ai_client, config: @config, template: 'modern', verbose: false)

    expected_branding = "Modern branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = generator.generate

    _(result).must_include "<h1>Jane Doe</h1>"

    FileUtils.rm_f('templates/website/modern.html.erb')
    @ai_client.verify
  end

  it "raises error when template is missing" do
    generator = Jojo::Generators::WebsiteGenerator.new(@employer, @ai_client, config: @config, template: 'nonexistent', verbose: false)

    expected_branding = "Branding..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    error = assert_raises(RuntimeError) do
      generator.generate
    end

    _(error.message).must_include "Template not found"
    _(error.message).must_include "nonexistent"
  end

  it "fails when resume is missing" do
    FileUtils.rm_f(@employer.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Resume not found"
  end

  it "fails when job description is missing" do
    FileUtils.rm_f(@employer.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  it "copies branding image when it exists" do
    # test/fixtures already has branding_image.jpg, and @generator uses inputs_path: 'test/fixtures'
    expected_branding = "Branding with image..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    @generator.generate

    # Check that image was copied
    image_path = File.join(@employer.website_path, 'branding_image.jpg')
    _(File.exist?(image_path)).must_equal true

    # Check that HTML references the image
    html = File.read(@employer.index_html_path)
    _(html).must_include 'branding_image.jpg'

    @ai_client.verify
  end

  it "skips branding image when missing" do
    # Create a generator with nonexistent inputs path (no branding_image.jpg)
    generator_no_image = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: 'test/fixtures/nonexistent'
    )

    expected_branding = "Branding without image..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator_no_image.generate

    # Image should not exist in website directory
    image_path = File.join(@employer.website_path, 'branding_image.jpg')
    _(File.exist?(image_path)).must_equal false

    @ai_client.verify
  end

  it "renders template with all variables" do
    expected_branding = "Full branding statement..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    # Check all template variables rendered
    _(result).must_include "Jane Doe"
    _(result).must_include "Acme Corp"
    _(result).must_include "Schedule a Call"
    _(result).must_include "https://calendly.com/janedoe/30min"
    _(result).must_include "https://janedoe.com/resume/acme-corp"
    _(result).must_include "https://janedoe.com/cover-letter/acme-corp"

    @ai_client.verify
  end

  it "handles missing CTA link gracefully" do
    @config.website_cta_link = nil  # No CTA link configured

    expected_branding = "Branding without CTA..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    _(result).wont_include '<section class="cta-section">'
    _(result).wont_include 'class="cta-button"'

    @ai_client.verify
  end

  it "handles empty CTA link gracefully" do
    @config.website_cta_link = "   "  # Empty/whitespace CTA link

    expected_branding = "Branding without CTA..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    _(result).wont_include '<section class="cta-section">'
    _(result).wont_include 'class="cta-button"'

    @ai_client.verify
  end
end
