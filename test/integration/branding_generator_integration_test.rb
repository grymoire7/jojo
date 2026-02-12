# test/integration/branding_generator_integration_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/branding/generator"

class BrandingGeneratorIntegrationTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp")
    File.write(@application.resume_path, "# Jane Doe\nSenior Ruby developer with 7 years experience")
    File.write(@application.research_path, "Acme Corp builds developer tools")
    File.write(@application.job_details_path, "company_name: Acme Corp\nposition_title: Senior Developer\n")
  end

  def test_full_branding_pipeline
    config = Object.new
    config.define_singleton_method(:seeker_name) { "Jane Doe" }
    config.define_singleton_method(:voice_and_tone) { "professional and friendly" }

    branding_content = "# Why I'm the Right Fit\n\nWith 7 years of Ruby expertise..."
    @ai_client.expect(:generate_text, branding_content, [String])

    generator = Jojo::Commands::Branding::Generator.new(@application, @ai_client, config: config, verbose: false)
    result = generator.generate

    assert_equal branding_content, result
    assert File.exist?(@application.branding_path)
    assert_equal branding_content, File.read(@application.branding_path)

    @ai_client.verify
  end

  def test_branding_pipeline_without_optional_files
    FileUtils.rm_f(@application.research_path)
    FileUtils.rm_f(@application.job_details_path)

    config = Object.new
    config.define_singleton_method(:seeker_name) { "Jane Doe" }
    config.define_singleton_method(:voice_and_tone) { "professional" }

    @ai_client.expect(:generate_text, "Branding statement...", [String])

    generator = Jojo::Commands::Branding::Generator.new(@application, @ai_client, config: config, verbose: false)
    result = generator.generate

    assert_equal "Branding statement...", result
    @ai_client.verify
  end
end
