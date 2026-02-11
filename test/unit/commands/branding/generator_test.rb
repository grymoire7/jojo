# test/unit/commands/branding/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/branding/generator"

class BrandingGeneratorTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone

  def initialize
    @seeker_name = "Jane Doe"
    @voice_and_tone = "professional and friendly"
  end
end

class Jojo::Commands::Branding::GeneratorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = BrandingGeneratorTestConfigStub.new
    @generator = Jojo::Commands::Branding::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false
    )

    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer role...")
    File.write(@application.resume_path, "# Jane Doe\n\nSenior Ruby developer...")
  end

  def test_generates_branding_statement_and_saves_to_file
    expected_branding = "I'm a perfect fit for Acme Corp...\n\nMy experience aligns perfectly..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    assert_equal expected_branding, result
    assert_equal true, File.exist?(@application.branding_path)
    assert_equal expected_branding, File.read(@application.branding_path)

    @ai_client.verify
  end

  def test_raises_error_when_job_description_missing
    FileUtils.rm_f(@application.job_description_path)

    assert_raises(RuntimeError) { @generator.generate }
  end

  def test_raises_error_when_resume_missing
    FileUtils.rm_f(@application.resume_path)

    assert_raises(RuntimeError) { @generator.generate }
  end

  def test_handles_missing_research_gracefully
    FileUtils.rm_f(@application.research_path)

    expected_branding = "Branding without research..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate
    assert_equal expected_branding, result

    @ai_client.verify
  end

  def test_handles_missing_job_details_gracefully
    FileUtils.rm_f(@application.job_details_path)

    expected_branding = "Branding without job details..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate
    assert_equal expected_branding, result

    @ai_client.verify
  end
end
