# test/unit/commands/website/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/employer"
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

describe Jojo::Commands::Website::Generator do
  before do
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = WebsiteGeneratorTestConfigStub.new
    @generator = Jojo::Commands::Website::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures"
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

  after do
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
  end

  it "generates website with all inputs" do
    result = @generator.generate

    _(result).must_include "Am I a good match for Acme Corp?"
    _(result).must_include "I'm a perfect fit for Acme Corp..."
    _(result).must_include "My experience aligns perfectly..."
    _(result).must_include "Schedule a Call"
    _(result).must_include "https://calendly.com/janedoe/30min"
  end

  it "saves website to index.html" do
    @generator.generate

    _(File.exist?(@application.index_html_path)).must_equal true
    content = File.read(@application.index_html_path)
    _(content).must_include "I'm a perfect fit for Acme Corp..."
    _(content).must_include "<!DOCTYPE html>"
    _(content).must_include "</html>"
  end

  it "generates website with minimal inputs (no research, no job_details)" do
    FileUtils.rm_f(@application.research_path)
    File.write(@application.branding_path, "Branding statement without research...")

    # Should not raise error
    result = @generator.generate
    _(result).must_include "Branding statement without research"
  end

  it "generates website with custom template" do
    # Create test template
    FileUtils.mkdir_p("templates/website")
    File.write("templates/website/modern.html.erb", "<html><body><h1><%= seeker_name %></h1></body></html>")

    generator = Jojo::Commands::Website::Generator.new(@application, @ai_client, config: @config, template: "modern", verbose: false)

    result = generator.generate

    _(result).must_include "<h1>Jane Doe</h1>"

    FileUtils.rm_f("templates/website/modern.html.erb")
  end

  it "raises error when template is missing" do
    generator = Jojo::Commands::Website::Generator.new(@application, @ai_client, config: @config, template: "nonexistent", verbose: false)

    error = assert_raises(RuntimeError) do
      generator.generate
    end

    _(error.message).must_include "Template not found"
    _(error.message).must_include "nonexistent"
  end

  it "fails when resume is missing" do
    FileUtils.rm_f(@application.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Resume not found"
  end

  it "fails when job description is missing" do
    FileUtils.rm_f(@application.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  it "copies branding image when it exists" do
    # test/fixtures already has branding_image.jpg, and @generator uses inputs_path: 'test/fixtures'
    @generator.generate

    # Check that image was copied
    image_path = File.join(@application.website_path, "branding_image.jpg")
    _(File.exist?(image_path)).must_equal true

    # Check that HTML references the image
    html = File.read(@application.index_html_path)
    _(html).must_include "branding_image.jpg"
  end

  it "skips branding image when missing" do
    # Create a generator with nonexistent inputs path (no branding_image.jpg)
    generator_no_image = Jojo::Commands::Website::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures/nonexistent"
    )

    generator_no_image.generate

    # Image should not exist in website directory
    image_path = File.join(@application.website_path, "branding_image.jpg")
    _(File.exist?(image_path)).must_equal false
  end

  it "renders template with all variables" do
    result = @generator.generate

    # Check all template variables rendered
    _(result).must_include "Jane Doe"
    _(result).must_include "Acme Corp"
    _(result).must_include "Schedule a Call"
    _(result).must_include "https://calendly.com/janedoe/30min"
    _(result).must_include "resume.pdf"
    _(result).must_include "cover-letter.pdf"
  end

  it "handles missing CTA link gracefully" do
    @config.website_cta_link = nil  # No CTA link configured

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    _(result).wont_include '<section class="cta-section">'
    _(result).wont_include 'class="cta-button"'
  end

  it "handles empty CTA link gracefully" do
    @config.website_cta_link = "   "  # Empty/whitespace CTA link

    result = @generator.generate

    # CTA section should not be rendered (check for actual section tag, not CSS class)
    _(result).wont_include '<section class="cta-section">'
    _(result).wont_include 'class="cta-button"'
  end

  it "loads and injects annotations into job description HTML" do
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

  it "omits annotation section when annotations.json missing" do
    # Don't create annotations file

    result = @generator.generate

    # Should NOT include annotation section
    _(result).wont_include "Compare Me to the Job Description"
    _(result).wont_include '<div id="annotation-tooltip"'
  end

  it "annotates all occurrences of same text" do
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

  it "prevents nested spans when annotation texts overlap" do
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

  it "loads and passes FAQs to template" do
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

  it "handles missing FAQ file gracefully" do
    FileUtils.rm_f(@application.faq_path) if File.exist?(@application.faq_path)
    File.write(@application.branding_path, "Branding statement")

    html = @generator.generate

    _(html).wont_include "Your Questions, Answered"
    _(html).wont_include '<div class="faq-accordion"'
  end

  it "fails when branding.md is missing" do
    FileUtils.rm_f(@application.branding_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "branding.md not found"
    _(error.message).must_include "jojo branding"
  end

  it "fails when branding.md is empty" do
    File.write(@application.branding_path, "")

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "branding.md not found"
  end
end
