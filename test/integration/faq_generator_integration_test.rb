# test/integration/faq_generator_integration_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/faq/generator"

class FaqGeneratorIntegrationTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp")
    File.write(@application.resume_path, "# Jane Doe\nSenior Ruby developer")
    File.write(@application.research_path, "Acme Corp is a SaaS company")
    File.write(@application.job_details_path, <<~YAML)
      company_name: Acme Corp
      position_title: Senior Ruby Developer
      required_skills:
        - Ruby on Rails
        - PostgreSQL
    YAML
  end

  def test_full_faq_pipeline_with_all_inputs
    @config.expect(:seeker_name, "Jane Doe")
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      {question: "What experience do you have with Ruby on Rails?", answer: "I have 7 years of Rails experience."},
      {question: "Why are you interested in Acme Corp?", answer: "Acme's focus on developer tools aligns with my passion."},
      {question: "How do you handle database optimization?", answer: "I have deep PostgreSQL knowledge."}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    generator = Jojo::Commands::Faq::Generator.new(@application, @ai_client, config: @config, verbose: false)
    result = generator.generate

    assert_equal 3, result.length
    assert_equal "What experience do you have with Ruby on Rails?", result[0][:question]

    # Verify file saved
    assert File.exist?(@application.faq_path)
    saved = JSON.parse(File.read(@application.faq_path), symbolize_names: true)
    assert_equal 3, saved.length

    @ai_client.verify
    @config.verify
  end

  def test_faq_pipeline_filters_invalid_entries
    @config.expect(:seeker_name, "Jane Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      {question: "Valid question?", answer: "Valid answer"},
      {question: "", answer: "No question"},
      {question: "No answer?", answer: ""}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    generator = Jojo::Commands::Faq::Generator.new(@application, @ai_client, config: @config, verbose: false)
    result = generator.generate

    assert_equal 1, result.length
    assert_equal "Valid question?", result[0][:question]

    @ai_client.verify
    @config.verify
  end
end
