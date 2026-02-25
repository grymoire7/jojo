require_relative "../test_helper"
require_relative "../../lib/jojo/commands/cover_letter/generator"
require_relative "../../lib/jojo/application"

class CoverLetterTemplateTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer at Acme Corp")
    File.write(@application.resume_path, "# Jane Doe\nSenior Ruby developer")

    @config = Minitest::Mock.new
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://example.com")
  end

  def test_render_template_includes_sender_header
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "This is the letter body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "Jane Doe"
    assert_includes result, "jane@example.com"
    assert_includes result, "https://janedoe.example.com"
    mock_ai.verify
    @config.verify
  end

  def test_render_template_includes_salutation_and_closing
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "This is the letter body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "Dear Hiring Manager,"
    assert_includes result, "This is the letter body."
    assert_includes result, "Sincerely,"
    mock_ai.verify
    @config.verify
  end

  def test_render_template_puts_landing_page_link_in_ps
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "This is the letter body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "P.S."
    assert_includes result, "Specifically for Acme Corp"
    assert_includes result, "https://example.com/acme-corp"
    refute result.start_with?("**Specifically")
    mock_ai.verify
    @config.verify
  end

  def test_render_template_date_format
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "Body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    expected_date = Time.now.strftime("%B, %Y")
    assert_includes result, expected_date
    mock_ai.verify
    @config.verify
  end
end
