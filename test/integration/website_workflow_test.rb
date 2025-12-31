require_relative "../test_helper"
require_relative "../../lib/jojo/employer"
require_relative "../../lib/jojo/config"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/generators/website_generator"

describe "Website Generation Workflow" do
  # Simple config stub
  class IntegrationTestConfigStub
    attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

    def initialize
      @seeker_name = "John Doe"
      @voice_and_tone = "professional and friendly"
      @website_cta_text = "Schedule a Call"
      @website_cta_link = "https://calendly.com/johndoe/30min"
      @base_url = "https://johndoe.com"
    end
  end

  before do
    @employer = Jojo::Employer.new("test-company")
    @ai_client = Minitest::Mock.new
    @config = IntegrationTestConfigStub.new

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Test Company...")
    File.write(@employer.job_details_path, "company_name: Test Company\nposition_title: Senior Ruby Developer\n")
    File.write(@employer.resume_path, "# John Doe\n\n## Professional Summary\n\nSenior Ruby developer with 10 years experience...")
    File.write(@employer.research_path, "# Company Profile\n\nTest Company is an innovative tech startup...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates complete website from end to end" do
    expected_branding = "I'm excited about Test Company because my background in Ruby development aligns perfectly with your needs.\n\nWith 10 years of experience, I've built scalable web applications."

    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      template: "default",
      verbose: false
    )

    generator.generate

    # Verify file was created
    _(File.exist?(@employer.index_html_path)).must_equal true

    # Verify HTML structure
    html = File.read(@employer.index_html_path)
    _(html).must_include "<!DOCTYPE html>"
    _(html).must_include "<html lang=\"en\">"
    _(html).must_include "</html>"

    # Verify content sections
    _(html).must_include "Am I a good match for Test Company?"
    _(html).must_include "I'm excited about Test Company because"
    _(html).must_include "With 10 years of experience"
    _(html).must_include "Schedule a Call"
    _(html).must_include "https://calendly.com/johndoe/30min"

    # Verify footer links
    _(html).must_include "https://johndoe.com/resume/test-company"
    _(html).must_include "https://johndoe.com/cover-letter/test-company"

    # Verify responsive CSS
    _(html).must_include "@media (max-width: 640px)"
    _(html).must_include "viewport"

    @ai_client.verify
  end

  it "works with custom template" do
    # Create custom template
    FileUtils.mkdir_p("templates/website")
    custom_template = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title><%= seeker_name %> - <%= company_name %></title></head>
      <body>
        <h1>Custom Template</h1>
        <div><%= branding_statement %></div>
        <% if cta_link && !cta_link.strip.empty? %>
        <a href="<%= cta_link %>"><%= cta_text %></a>
        <% end %>
      </body>
      </html>
    HTML
    File.write("templates/website/custom.html.erb", custom_template)

    expected_branding = "Custom branding statement..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      template: "custom",
      verbose: false
    )

    result = generator.generate

    _(result).must_include "Custom Template"
    _(result).must_include "John Doe - Test Company"
    _(result).must_include expected_branding
    _(result).must_include "https://calendly.com/johndoe/30min"

    FileUtils.rm_f("templates/website/custom.html.erb")
    @ai_client.verify
  end

  it "handles branding image workflow" do
    expected_branding = "Branding with image..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    # Use test/fixtures which has branding_image.jpg
    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures"
    )

    generator.generate

    # Verify image was copied to website directory
    website_image = File.join(@employer.website_path, "branding_image.jpg")
    _(File.exist?(website_image)).must_equal true

    # Verify HTML includes image reference
    html = File.read(@employer.index_html_path)
    _(html).must_include "branding_image.jpg"
    _(html).must_include '<img src="branding_image.jpg"'

    @ai_client.verify
  end

  it "generates website without CTA when not configured" do
    @config.website_cta_link = nil  # No CTA configured

    expected_branding = "Branding without CTA..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    generator.generate

    html = File.read(@employer.index_html_path)

    # CTA section should not be present
    _(html).wont_include '<section class="cta-section">'
    _(html).wont_include 'class="cta-button"'

    # But rest of website should be intact
    _(html).must_include "Am I a good match for Test Company?"
    _(html).must_include "Branding without CTA"

    @ai_client.verify
  end

  it "gracefully handles missing optional inputs" do
    # Remove optional files
    FileUtils.rm_f(@employer.research_path)

    expected_branding = "Branding without research..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    # Should not raise error
    result = generator.generate

    _(File.exist?(@employer.index_html_path)).must_equal true
    _(result).must_include expected_branding

    @ai_client.verify
  end
end
