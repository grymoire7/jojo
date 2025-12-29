require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/faq_generator'

describe Jojo::Generators::FaqGenerator do
  before do
    @employer = Jojo::Employer.new('acme-corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::FaqGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "We need 5+ years of Python experience.")
    File.write(@employer.resume_path, "# John Doe\n\nSenior Python developer with 7 years experience.")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates FAQs from job description and resume" do
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      { question: "What's your Python experience?", answer: "I have 7 years of Python experience..." },
      { question: "Where can I find your resume?", answer: "Download here: <a href='...'>Resume</a>" }
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    _(result).must_be_kind_of Array
    _(result.length).must_equal 2
    _(result[0][:question]).must_equal "What's your Python experience?"

    @ai_client.verify
    @config.verify
  end

  it "saves FAQs to JSON file" do
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      { question: "What's your experience?", answer: "I have experience..." }
    ])

    @ai_client.expect(:reason, ai_response, [String])

    @generator.generate

    _(File.exist?(@employer.faq_path)).must_equal true

    saved_data = JSON.parse(File.read(@employer.faq_path), symbolize_names: true)
    _(saved_data.length).must_equal 1
    _(saved_data[0][:question]).must_equal "What's your experience?"

    @ai_client.verify
    @config.verify
  end

  it "handles malformed JSON from AI" do
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    @ai_client.expect(:reason, "This is not valid JSON", [String])

    result = @generator.generate

    _(result).must_equal []

    @ai_client.verify
    @config.verify
  end

  it "filters out invalid FAQ items" do
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      { question: "Valid question?", answer: "Valid answer" },
      { question: "", answer: "Missing question" },
      { question: "Missing answer?", answer: "" },
      { answer: "Missing question field" }
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    _(result.length).must_equal 1
    _(result[0][:question]).must_equal "Valid question?"

    @ai_client.verify
    @config.verify
  end

  it "handles missing research gracefully" do
    FileUtils.rm_f(@employer.research_path)

    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      { question: "Question?", answer: "Answer" }
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    _(result.length).must_equal 1

    @ai_client.verify
    @config.verify
  end

  it "raises error when job description missing" do
    FileUtils.rm_f(@employer.job_description_path)

    _ { @generator.generate }.must_raise RuntimeError
  end

  it "raises error when resume missing" do
    FileUtils.rm_f(@employer.resume_path)

    _ { @generator.generate }.must_raise RuntimeError
  end
end
