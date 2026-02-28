# test/unit/commands/cover_letter/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/cover_letter/generator"

class Jojo::Commands::CoverLetter::GeneratorTest < JojoTest
  def setup
    super
    copy_templates
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Commands::CoverLetter::Generator.new(
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
    File.write(@application.resume_path, "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer...") # REQUIRED for cover letter
    File.write(@application.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
    File.write(@application.job_details_path, "company_name: Acme Corp\nposition_title: Senior Developer\n")
  end

  def teardown
    @config&.verify
    super
  end

  def test_generates_cover_letter_from_all_inputs
    expected_cover_letter = "Dear Hiring Manager,\n\nI am genuinely excited about the opportunity..."
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    result = @generator.generate

    assert_includes result, "Specifically for Acme Corp"
    assert_includes result, "https://tracyatteberry.com/acme-corp"
    assert_includes result, expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  def test_saves_cover_letter_to_file
    expected_cover_letter = "Dear Hiring Manager,\n\nTailored content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    @generator.generate

    assert_equal true, File.exist?(@application.cover_letter_path)
    content = File.read(@application.cover_letter_path)
    assert_includes content, "Specifically for Acme Corp"
    assert_includes content, expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  def test_fails_when_tailored_resume_is_missing
    FileUtils.rm_f(@application.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    assert_includes error.message, "Tailored resume not found"
  end

  def test_fails_when_generic_resume_is_missing
    # Create a generator with a nonexistent inputs path
    generator_no_resume = Jojo::Commands::CoverLetter::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path("nonexistent")
    )

    error = assert_raises(RuntimeError) do
      generator_no_resume.generate
    end

    assert_includes error.message, "Resume data not found"
  end

  def test_fails_when_job_description_is_missing
    FileUtils.rm_f(@application.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    assert_includes error.message, "Job description not found"
  end

  def test_continues_when_research_is_missing_with_warning
    FileUtils.rm_f(@application.research_path)

    expected_cover_letter = "Cover letter without research insights..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    # Should not raise error
    result = @generator.generate
    assert_includes result, expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  def test_generates_correct_landing_page_link
    expected_cover_letter = "Cover letter content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    result = @generator.generate

    assert_includes result, "**Specifically for Acme Corp**: https://tracyatteberry.com/acme-corp"

    @ai_client.verify
    @config.verify
  end
end
