# test/unit/commands/website/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/website/generator"

# Simple config stub to avoid complex mock expectations
class WebsiteGeneratorTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

  def initialize
    @seeker_name = "Jane Doe"
    @voice_and_tone = "professional and friendly"
    @website_cta_text = "Schedule a Call"
    @website_cta_link = "https://calendly.com/janedoe/30min"
    @base_url = "https://janedoe.com"
  end
end

class Jojo::Commands::Website::GeneratorTest < JojoTest
  def setup
    super
    copy_templates
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = WebsiteGeneratorTestConfigStub.new
    @generator = Jojo::Commands::Website::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )

    # Clean up and create directories
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
    @application.create_directory!

    # Create required fixtures
    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@application.resume_path, "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer...")
    File.write(@application.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
    File.write(@application.job_details_path, "company_name: Acme Corp\nposition_title: Senior Developer\n")
    File.write(@application.branding_path, "I'm a perfect fit for Acme Corp...\n\nMy experience aligns perfectly...")
  end

  def teardown
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
    super
  end

  def test_generates_website_with_all_inputs
    result = @generator.generate

    assert_includes result, "Am I a good match for Acme Corp?"
    assert_includes result, "I'm a perfect fit for Acme Corp..."
    assert_includes result, "My experience aligns perfectly..."
    assert_includes result, "Schedule a Call"
    assert_includes result, "https://calendly.com/janedoe/30min"
  end

  def test_saves_website_to_index_html
    @generator.generate

    assert_equal true, File.exist?(@application.index_html_path)
    content = File.read(@application.index_html_path)
    assert_includes content, "I'm a perfect fit for Acme Corp..."
    assert_includes content, "<!DOCTYPE html>"
    assert_includes content, "</html>"
  end

  def test_generates_website_with_minimal_inputs
    FileUtils.rm_f(@application.research_path)
    File.write(@application.branding_path, "Branding statement without research...")

    # Should not raise error
    result = @generator.generate
    assert_includes result, "Branding statement without research"
  end

  def test_generates_website_with_custom_template
    # Create test template
    FileUtils.mkdir_p("templates/website")
    File.write("templates/website/modern.html.erb", "<html><body><h1><%= seeker_name %></h1></body></html>")

    generator = Jojo::Commands::Website::Generator.new(@application, @ai_client, config: @config, template: "modern", verbose: false)

    result = generator.generate

    assert_includes result, "<h1>Jane Doe</h1>"

    FileUtils.rm_f("templates/website/modern.html.erb")
  end

  def test_raises_error_when_template_is_missing
    generator = Jojo::Commands::Website::Generator.new(@application, @ai_client, config: @config, template: "nonexistent", verbose: false)

    error = assert_raises(RuntimeError) do
      generator.generate
    end

    assert_includes error.message, "Template not found"
    assert_includes error.message, "nonexistent"
  end

  def test_fails_when_resume_is_missing
    FileUtils.rm_f(@application.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    assert_includes error.message, "Resume not found"
  end

  def test_fails_when_job_description_is_missing
    FileUtils.rm_f(@application.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    assert_includes error.message, "Job description not found"
  end

  def test_copies_branding_image_when_it_exists
    # fixture_path already has branding_image.jpg, and @generator uses inputs_path: fixture_path
    @generator.generate

    # Check that image was copied
    image_path = File.join(@application.website_path, "branding_image.jpg")
    assert_equal true, File.exist?(image_path)

    # Check that HTML references the image
    html = File.read(@application.index_html_path)
    assert_includes html, "branding_image.jpg"
  end

  def test_skips_branding_image_when_missing
    # Create a generator with nonexistent inputs path (no branding_image.jpg)
    generator_no_image = Jojo::Commands::Website::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path("nonexistent")
    )

    generator_no_image.generate

    # Image should not exist in website directory
    image_path = File.join(@application.website_path, "branding_image.jpg")
    assert_equal false, File.exist?(image_path)
  end

  def test_renders_template_with_all_variables
    result = @generator.generate

    # Check all template variables rendered
    assert_includes result, "Jane Doe"
    assert_includes result, "Acme Corp"
    assert_includes result, "Schedule a Call"
    assert_includes result, "https://calendly.com/janedoe/30min"
    assert_includes result, "resume.pdf"
    assert_includes result, "cover_letter.pdf"
  end

  def test_handles_missing_cta_link_gracefully
    @config.website_cta_link = nil  # No CTA link configured

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    refute_includes result, "Let's Connect"
    refute_includes result, "btn btn-primary btn-lg"
  end

  def test_handles_empty_cta_link_gracefully
    @config.website_cta_link = "   "  # Empty/whitespace CTA link

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    refute_includes result, "Let's Connect"
    refute_includes result, "btn btn-primary btn-lg"
  end

  def test_loads_and_injects_annotations_into_job_description_html
    # Update job description to include text being annotated
    File.write(@application.job_description_path, "We need Ruby and distributed systems experience.")

    # Create annotations JSON
    annotations = [
      {text: "Ruby", match: "7 years Ruby experience", tier: "strong"},
      {text: "distributed systems", match: "Built message queue", tier: "moderate"}
    ]
    File.write(@application.job_description_annotations_path, JSON.generate(annotations))

    result = @generator.generate

    # Should include annotated job description section
    assert_includes result, "Compare Me to the Job Description"
    assert_includes result, '<span class="annotated" data-tier="strong" data-match="7 years Ruby experience">Ruby</span>'
    assert_includes result, '<span class="annotated" data-tier="moderate" data-match="Built message queue">distributed systems</span>'
  end

  def test_omits_annotation_section_when_annotations_json_missing
    # Don't create annotations file

    result = @generator.generate

    # Should NOT include annotation section
    refute_includes result, "Compare Me to the Job Description"
    refute_includes result, '<div id="annotation-tooltip"'
  end

  def test_annotates_all_occurrences_of_same_text
    # Job description with duplicate text
    File.write(@application.job_description_path, "We need Ruby skills. Ruby is our main language. Ruby developers wanted.")

    annotations = [
      {text: "Ruby", match: "7 years Ruby experience", tier: "strong"}
    ]
    File.write(@application.job_description_annotations_path, JSON.generate(annotations))

    result = @generator.generate

    # Count occurrences of annotated "Ruby"
    annotation_count = result.scan(/<span class="annotated"[^>]*>Ruby<\/span>/).length
    assert_equal 3, annotation_count
  end

  def test_prevents_nested_spans_when_annotation_texts_overlap
    # Job description with overlapping text patterns
    # "Ruby" appears alone and within "Ruby on Rails"
    File.write(@application.job_description_path, "We need Ruby developers who know Ruby on Rails.\n\nRuby is great. Ruby on Rails is a framework.")

    # Create overlapping annotations (shorter text appears within longer text)
    annotations = [
      {text: "Ruby", match: "7 years Ruby experience", tier: "strong"},
      {text: "Ruby on Rails", match: "Full-stack Ruby on Rails experience", tier: "strong"}
    ]
    File.write(@application.job_description_annotations_path, JSON.generate(annotations))

    result = @generator.generate

    # Check that standalone "Ruby" is annotated
    assert_match(/<span class="annotated"[^>]*>Ruby<\/span> developers who know/, result)

    # Check that "Ruby on Rails" is annotated as a whole phrase
    assert_match(/know <span class="annotated"[^>]*>Ruby on Rails<\/span>\./, result)

    # Check that "Ruby" WITHIN "Ruby on Rails" is NOT separately annotated (no nested spans)
    # This regex looks for a span containing another span - which would indicate nesting
    nested_spans = result.scan(/<span class="annotated"[^>]*>(.*?)<\/span>/m).any? do |match|
      match[0].include?("<span class=\"annotated\"")
    end
    assert_equal false, nested_spans

    # Check that data-match attributes don't contain span tags (malformed HTML)
    data_match_with_spans = result.scan(/data-match="([^"]*<span[^"]*)"/)
    assert_equal true, data_match_with_spans.empty?
  end

  def test_loads_and_passes_faqs_to_template
    # Create mock FAQs file
    faqs_data = [
      {question: "What's your experience?", answer: "I have 7 years..."},
      {question: "Why this company?", answer: "I'm excited about..."}
    ]
    File.write(@application.faq_path, JSON.generate(faqs_data))

    html = @generator.generate

    assert_includes html, "What's your experience?"
    assert_includes html, "Why this company?"
    assert_includes html, "Your Questions, Answered"
  end

  def test_handles_missing_faq_file_gracefully
    FileUtils.rm_f(@application.faq_path) if File.exist?(@application.faq_path)
    File.write(@application.branding_path, "Branding statement")

    html = @generator.generate

    refute_includes html, "Your Questions, Answered"
    refute_includes html, "faq-accordion"
  end

  def test_fails_when_branding_md_is_missing
    FileUtils.rm_f(@application.branding_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    assert_includes error.message, "branding.md not found"
    assert_includes error.message, "jojo branding"
  end

  def test_fails_when_branding_md_is_empty
    File.write(@application.branding_path, "")

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    assert_includes error.message, "branding.md not found"
  end

  def test_uses_inputs_template_override_when_present
    FileUtils.mkdir_p("override_inputs/templates/website")
    File.write("override_inputs/templates/website/index.html.erb", "<html>OVERRIDE: <%= seeker_name %></html>")

    generator = Jojo::Commands::Website::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "override_inputs"
    )
    result = generator.generate

    assert_includes result, "OVERRIDE: Jane Doe"
  end

  def test_uses_inputs_asset_override_when_present
    FileUtils.mkdir_p("override_inputs/templates/website")
    File.write("override_inputs/templates/website/index.html.erb", "<html>website</html>")
    File.write("override_inputs/templates/website/script.js", "// CUSTOM JS")

    generator = Jojo::Commands::Website::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "override_inputs"
    )
    generator.generate

    assert_includes File.read(File.join(@application.website_path, "script.js")), "// CUSTOM JS"
  end
end
