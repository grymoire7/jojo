# test/unit/commands/resume/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/resume/generator"

class Jojo::Commands::Resume::GeneratorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Commands::Resume::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path
    )

    @application.create_directory!

    # Create required fixtures
    File.write(@application.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@application.job_details_path, "company_name: Acme Corp\n")
  end

  def test_generates_resume_using_resume_curation_service
    # Mock config for permissions and base_url
    @config.expect(:dig, {"skills" => ["remove", "reorder"]}, ["resume_data", "permissions"])
    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    # Mock AI calls for transformation
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    result = @generator.generate

    assert_includes result, "# Jane Doe"
    assert_includes result, "Specifically for Acme Corp"
    assert_includes result, "https://example.com/resume/acme-corp"

    @ai_client.verify
  end

  def test_saves_resume_to_file
    @config.expect(:dig, {"skills" => ["remove", "reorder"]}, ["resume_data", "permissions"])
    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    @generator.generate

    assert_equal true, File.exist?(@application.resume_path)
    content = File.read(@application.resume_path)
    assert_includes content, "Specifically for Acme Corp"
  end

  def test_fails_when_resume_data_yml_is_missing
    generator_no_data = Jojo::Commands::Resume::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: fixture_path("nonexistent")
    )

    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      generator_no_data.generate
    end

    assert_includes error.message, "not found"
  end

  def test_resolve_template_path_returns_inputs_override_when_present
    generator = Jojo::Commands::Resume::Generator.new(
      @application, @ai_client,
      config: @config, verbose: false,
      inputs_path: "."
    )
    FileUtils.mkdir_p("templates")
    File.write(File.join("templates", "resume.md.erb"), "override")

    result = generator.send(:resolve_template_path, "resume.md.erb")

    assert_equal File.join(".", "templates", "resume.md.erb"), result
  end

  def test_resolve_template_path_falls_back_to_templates_dir
    generator = Jojo::Commands::Resume::Generator.new(
      @application, @ai_client,
      config: @config, verbose: false,
      inputs_path: "nonexistent_inputs"
    )

    result = generator.send(:resolve_template_path, "resume.md.erb")

    assert_equal File.join("templates", "resume.md.erb"), result
  end
end
