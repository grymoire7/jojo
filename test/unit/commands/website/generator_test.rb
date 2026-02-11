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

    _(result).must_include "Am I a good match for Acme Corp?"
    _(result).must_include "I'm a perfect fit for Acme Corp..."
    _(result).must_include "My experience aligns perfectly..."
    _(result).must_include "Schedule a Call"
    _(result).must_include "https://calendly.com/janedoe/30min"
  end

  def test_saves_website_to_index_html
    @generator.generate

    _(File.exist?(@application.index_html_path)).must_equal true
    content = File.read(@application.index_html_path)
    _(content).must_include "I'm a perfect fit for Acme Corp..."
    _(content).must_include "<!DOCTYPE html>"
    _(content).must_include "</html>"
  end

  def test_generates_website_with_minimal_inputs
    FileUtils.rm_f(@application.research_path)
    File.write(@application.branding_path, "Branding statement without research...")

    # Should not raise error
    result = @generator.generate
    _(result).must_include "Branding statement without research"
  end

  def test_generates_website_with_custom_template
    # Create test template
    FileUtils.mkdir_p("templates/website")
    File.write("templates/website/modern.html.erb", "<html><body><h1><%= seeker_name %></h1></body></html>")

    generator = Jojo::Commands::Website::Generator.new(@application, @ai_client, config: @config, template: "modern", verbose: false)

    result = generator.generate

    _(result).must_include "<h1>Jane Doe</h1>"

    FileUtils.rm_f("templates/website/modern.html.erb")
  end

  def test_raises_error_when_template_is_missing
    generator = Jojo::Commands::Website::Generator.new(@application, @ai_client, config: @config, template: "nonexistent", verbose: false)

    error = assert_raises(RuntimeError) do
      generator.generate
    end

    _(error.message).must_include "Template not found"
    _(error.message).must_include "nonexistent"
  end

  def test_fails_when_resume_is_missing
    FileUtils.rm_f(@application.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Resume not found"
  end

  def test_fails_when_job_description_is_missing
    FileUtils.rm_f(@application.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  def test_copies_branding_image_when_it_exists
    # fixture_path already has branding_image.jpg, and @generator uses inputs_path: fixture_path
    @generator.generate

    # Check that image was copied
    image_path = File.join(@application.website_path, "branding_image.jpg")
    _(File.exist?(image_path)).must_equal true

    # Check that HTML references the image
    html = File.read(@application.index_html_path)
    _(html).must_include "branding_image.jpg"
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
    _(File.exist?(image_path)).must_equal false
  end

  def test_renders_template_with_all_variables
    result = @generator.generate

    # Check all template variables rendered
    _(result).must_include "Jane Doe"
    _(result).must_include "Acme Corp"
    _(result).must_include "Schedule a Call"
    _(result).must_include "https://calendly.com/janedoe/30min"
    _(result).must_include "resume.pdf"
    _(result).must_include "cover-letter.pdf"
  end

  def test_handles_missing_cta_link_gracefully
    @config.website_cta_link = nil  # No CTA link configured

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    _(result).wont_include '<section class="cta-section">'
    _(result).wont_include 'class="cta-button"'
  end

  def test_handles_empty_cta_link_gracefully
    @config.website_cta_link = "   "  # Empty/whitespace CTA link

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    _(result).wont_include '<section class="cta-section">'
    _(result).wont_include 'class="cta-button"'
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
    _(result).must_include "Compare Me to the Job Description"
    _(result).must_include '<span class="annotated" data-tier="strong" data-match="7 years Ruby experience">Ruby</span>'
    _(result).must_include '<span class="annotated" data-tier="moderate" data-match="Built message queue">distributed systems</span>'
  end

  def test_omits_annotation_section_when_annotations_json_missing
    # Don't create annotations file

    result = @generator.generate

    # Should NOT include annotation section
    _(result).wont_include "Compare Me to the Job Description"
    _(result).wont_include '<div id="annotation-tooltip"'
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
    _(annotation_count).must_equal 3
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
    _(result).must_match(/<span class="annotated"[^>]*>Ruby<\/span> developers who know/)

    # Check that "Ruby on Rails" is annotated as a whole phrase
    _(result).must_match(/know <span class="annotated"[^>]*>Ruby on Rails<\/span>\./)

    # Check that "Ruby" WITHIN "Ruby on Rails" is NOT separately annotated (no nested spans)
    # This regex looks for a span containing another span - which would indicate nesting
    nested_spans = result.scan(/<span class="annotated"[^>]*>(.*?)<\/span>/m).any? do |match|
      match[0].include?("<span class=\"annotated\"")
    end
    _(nested_spans).must_equal false

    # Check that data-match attributes don't contain span tags (malformed HTML)
    data_match_with_spans = result.scan(/data-match="([^"]*<span[^"]*)"/)
    _(data_match_with_spans.empty?).must_equal true
  end

  def test_loads_and_passes_faqs_to_template
    # Create mock FAQs file
    faqs_data = [
      {question: "What's your experience?", answer: "I have 7 years..."},
      {question: "Why this company?", answer: "I'm excited about..."}
    ]
    File.write(@application.faq_path, JSON.generate(faqs_data))

    html = @generator.generate

    _(html).must_include "What's your experience?"
    _(html).must_include "Why this company?"
    _(html).must_include "Your Questions, Answered"
  end

  def test_handles_missing_faq_file_gracefully
    FileUtils.rm_f(@application.faq_path) if File.exist?(@application.faq_path)
    File.write(@application.branding_path, "Branding statement")

    html = @generator.generate

    _(html).wont_include "Your Questions, Answered"
    _(html).wont_include '<div class="faq-accordion"'
  end

  def test_fails_when_branding_md_is_missing
    FileUtils.rm_f(@application.branding_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "branding.md not found"
    _(error.message).must_include "jojo branding"
  end

  def test_fails_when_branding_md_is_empty
    File.write(@application.branding_path, "")

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "branding.md not found"
  end
end
