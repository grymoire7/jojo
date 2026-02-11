# test/unit/commands/faq/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/faq/generator"

class Jojo::Commands::Faq::GeneratorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Commands::Faq::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false
    )

    @application.create_directory!

    # Create required fixtures
    File.write(@application.job_description_path, "We need 5+ years of Python experience.")
    File.write(@application.resume_path, "# John Doe\n\nSenior Python developer with 7 years experience.")
  end

  def test_generates_faqs_from_job_description_and_resume
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      {question: "What's your Python experience?", answer: "I have 7 years of Python experience..."},
      {question: "Where can I find your resume?", answer: "Download here: <a href='...'>Resume</a>"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    assert_kind_of Array, result
    assert_equal 2, result.length
    assert_equal "What's your Python experience?", result[0][:question]

    @ai_client.verify
    @config.verify
  end

  def test_saves_faqs_to_json_file
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      {question: "What's your experience?", answer: "I have experience..."}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    @generator.generate

    assert_equal true, File.exist?(@application.faq_path)

    saved_data = JSON.parse(File.read(@application.faq_path), symbolize_names: true)
    assert_equal 1, saved_data.length
    assert_equal "What's your experience?", saved_data[0][:question]

    @ai_client.verify
    @config.verify
  end

  def test_handles_malformed_json_from_ai
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    @ai_client.expect(:reason, "This is not valid JSON", [String])

    result = @generator.generate

    assert_equal [], result

    @ai_client.verify
    @config.verify
  end

  def test_filters_out_invalid_faq_items
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      {question: "Valid question?", answer: "Valid answer"},
      {question: "", answer: "Missing question"},
      {question: "Missing answer?", answer: ""},
      {answer: "Missing question field"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    assert_equal 1, result.length
    assert_equal "Valid question?", result[0][:question]

    @ai_client.verify
    @config.verify
  end

  def test_handles_missing_research_gracefully
    FileUtils.rm_f(@application.research_path)

    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      {question: "Question?", answer: "Answer"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    assert_equal 1, result.length

    @ai_client.verify
    @config.verify
  end

  def test_raises_error_when_job_description_missing
    FileUtils.rm_f(@application.job_description_path)

    assert_raises(RuntimeError) { @generator.generate }
  end

  def test_raises_error_when_resume_missing
    FileUtils.rm_f(@application.resume_path)

    assert_raises(RuntimeError) { @generator.generate }
  end
end
