require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/faq/generator"
require_relative "../../lib/jojo/commands/website/generator"
require_relative "../../lib/jojo/config"
require "yaml"
require "json"
require "tempfile"

describe "FAQ Workflow Integration" do
  before do
    @employer = Jojo::Application.new("integration-test-corp")
    @ai_client = Minitest::Mock.new

    # Create minimal config in a temp file
    @config_file = Tempfile.new(["config", ".yml"])
    config_data = {
      "seeker_name" => "John Doe",
      "voice_and_tone" => "professional and friendly",
      "base_url" => "https://johndoe.com",
      "reasoning_ai" => {"service" => "anthropic", "model" => "sonnet"},
      "text_generation_ai" => {"service" => "anthropic", "model" => "haiku"}
    }
    @config_file.write(YAML.dump(config_data))
    @config_file.close
    @config = Jojo::Config.new(@config_file.path)

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "We need a senior Ruby developer with 5+ years experience.")
    File.write(@employer.resume_path, "# John Doe\n\nSenior Ruby developer with 7 years of experience.")
    File.write(@employer.research_path, "Integration Test Corp is a fast-growing startup.")
    File.write(@employer.branding_path, "I am excited to apply because my Ruby experience matches your needs.")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @config_file.close!
    @config_file.unlink if @config_file.path && File.exist?(@config_file.path)
  end

  it "generates FAQs and includes them in website" do
    # Generate FAQs
    faq_generator = Jojo::Commands::Faq::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    faq_response = JSON.generate([
      {question: "What's your Ruby experience?", answer: "I have 7 years of Ruby experience..."},
      {question: "Why this company?", answer: "Integration Test Corp's mission resonates..."},
      {question: "Where can I find your resume?", answer: "<a href='...'>Resume</a>"}
    ])

    @ai_client.expect(:reason, faq_response, [String])

    faqs = faq_generator.generate

    _(faqs.length).must_equal 3
    _(File.exist?(@employer.faq_path)).must_equal true

    @ai_client.verify

    # Generate website with FAQs
    website_generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    html = website_generator.generate

    _(html).must_include "Your Questions, Answered"
    _(html).must_include "What's your Ruby experience?"
    _(html).must_include "Why this company?"
    _(html).must_include "faq-accordion"
    _(html).must_include "toggleFaq" # JavaScript function

    @ai_client.verify
  end

  it "handles missing FAQ file gracefully in website generation" do
    website_generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    # Don't create FAQ file
    FileUtils.rm_f(@employer.faq_path) if File.exist?(@employer.faq_path)

    html = website_generator.generate

    _(html).wont_include "Your Questions, Answered"
    _(html).wont_include '<div class="faq-accordion"'

    @ai_client.verify
  end

  it "handles malformed FAQ JSON gracefully" do
    # Write malformed JSON
    File.write(@employer.faq_path, "This is not valid JSON")

    website_generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    html = website_generator.generate

    _(html).wont_include "Your Questions, Answered"

    @ai_client.verify
  end

  it "renders FAQ section in correct position" do
    # Create FAQ file
    faqs = [{question: "Test?", answer: "Answer"}]
    File.write(@employer.faq_path, JSON.generate(faqs))

    website_generator = Jojo::Commands::Website::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    html = website_generator.generate

    # FAQ should come before footer
    faq_position = html.index("Your Questions, Answered")
    footer_position = html.index('<footer class="footer">')

    _(faq_position).wont_be_nil
    _(footer_position).wont_be_nil
    _(faq_position).must_be :<, footer_position

    @ai_client.verify
  end
end
