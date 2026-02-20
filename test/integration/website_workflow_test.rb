require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/commands/website/generator"

# Simple config stub
class WebsiteWorkflowTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

  def initialize
    @seeker_name = "John Doe"
    @voice_and_tone = "professional and friendly"
    @website_cta_text = "Schedule a Call"
    @website_cta_link = "https://calendly.com/johndoe/30min"
    @base_url = "https://johndoe.com"
  end
end

class WebsiteWorkflowTest < JojoTest
  def setup
    super
    copy_templates
    @employer = Jojo::Application.new("test-company")
    @ai_client = Minitest::Mock.new
    @config = WebsiteWorkflowTestConfigStub.new

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Test Company...")
    File.write(@employer.job_details_path, "company_name: Test Company\nposition_title: Senior Ruby Developer\n")
    File.write(@employer.resume_path, "# John Doe\n\n## Professional Summary\n\nSenior Ruby developer with 10 years experience...")
    File.write(@employer.research_path, "# Company Profile\n\nTest Company is an innovative tech startup...")
    File.write(@employer.branding_path, "I'm excited about Test Company because my background in Ruby development aligns perfectly with your needs.\n\nWith 10 years of experience, I've built scalable web applications.")
  end

  def teardown
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    super
  end

  def test_generates_complete_website_from_end_to_end
    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      template: "default",
      verbose: false
    )

    generator.generate

    # Verify file was created
    assert_equal true, File.exist?(@employer.index_html_path)

    # Verify HTML structure
    html = File.read(@employer.index_html_path)
    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, '<html lang="en" data-theme="jojo">'
    assert_includes html, "</html>"

    # Verify content sections
    assert_includes html, "Am I a good match for Test Company?"
    assert_includes html, "I'm excited about Test Company because"
    assert_includes html, "With 10 years of experience"
    assert_includes html, "Schedule a Call"
    assert_includes html, "https://calendly.com/johndoe/30min"

    # Verify footer links
    assert_includes html, "resume.pdf"
    assert_includes html, "cover-letter.pdf"

    # Verify Tailwind CSS output with DaisyUI theme
    styles_css = File.read(File.join(@employer.website_path, "styles.css"))
    assert_includes styles_css, "tailwindcss"
    assert_includes styles_css, "--color-primary:oklch" # DaisyUI jojo theme primary color
    assert_includes html, '<link rel="stylesheet" href="styles.css">'
    assert_includes html, "viewport"
    assert_includes html, "Inter" # Google Fonts

    @ai_client.verify
  end

  def test_works_with_custom_template
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

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      template: "custom",
      verbose: false
    )

    result = generator.generate

    assert_includes result, "Custom Template"
    assert_includes result, "John Doe - Test Company"
    assert_includes result, "I'm excited about Test Company"
    assert_includes result, "https://calendly.com/johndoe/30min"

    FileUtils.rm_f("templates/website/custom.html.erb")
    @ai_client.verify
  end

  def test_handles_branding_image_workflow
    # Use test/fixtures which has branding_image.jpg
    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )

    generator.generate

    # Verify image was copied to website directory
    website_image = File.join(@employer.website_path, "branding_image.jpg")
    assert_equal true, File.exist?(website_image)

    # Verify HTML includes image reference
    html = File.read(@employer.index_html_path)
    assert_includes html, "branding_image.jpg"
    assert_includes html, '<img src="branding_image.jpg"'

    @ai_client.verify
  end

  def test_generates_website_without_cta_when_not_configured
    @config.website_cta_link = nil  # No CTA configured

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    generator.generate

    html = File.read(@employer.index_html_path)

    # CTA section should not be present
    refute_includes html, "Let's Connect"
    refute_includes html, "btn btn-primary btn-lg"

    # But rest of website should be intact
    assert_includes html, "Am I a good match for Test Company?"
    assert_includes html, "I'm excited about Test Company"

    @ai_client.verify
  end

  def test_gracefully_handles_missing_optional_inputs
    # Remove optional files
    FileUtils.rm_f(@employer.research_path)

    generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    # Should not raise error
    result = generator.generate

    assert_equal true, File.exist?(@employer.index_html_path)
    assert_includes result, "I'm excited about Test Company"

    @ai_client.verify
  end
end
