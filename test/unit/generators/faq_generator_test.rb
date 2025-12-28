require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/faq_generator'

describe Jojo::Generators::FaqGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
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
end
