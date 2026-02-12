# test/integration/cover_letter_generator_integration_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/cover_letter/generator"

class CoverLetterGeneratorIntegrationTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp")
    File.write(@application.resume_path, "# Jane Doe - Tailored Resume\nSenior Ruby developer")
    File.write(@application.research_path, "Acme Corp is a SaaS company")
    File.write(@application.job_details_path, "company_name: Acme Corp\nposition_title: Senior Developer\n")
  end

  def test_full_cover_letter_pipeline
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://example.com")

    cover_letter_content = "Dear Hiring Manager,\n\nI am excited to apply for the Senior Ruby Developer role..."
    @ai_client.expect(:generate_text, cover_letter_content, [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )
    result = generator.generate

    # Verify landing page link prepended
    assert_includes result, "**Specifically for Acme Corp**: https://example.com/resume/acme-corp"
    assert_includes result, cover_letter_content

    # Verify file saved
    assert File.exist?(@application.cover_letter_path)
    saved = File.read(@application.cover_letter_path)
    assert_includes saved, "Specifically for Acme Corp"
    assert_includes saved, cover_letter_content

    @ai_client.verify
    @config.verify
  end

  def test_cover_letter_pipeline_without_research
    FileUtils.rm_f(@application.research_path)

    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    @ai_client.expect(:generate_text, "Cover letter without research...", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "Cover letter without research..."
    @ai_client.verify
    @config.verify
  end
end
