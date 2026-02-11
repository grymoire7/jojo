require_relative "../test_helper"
require_relative "../../lib/jojo/commands/resume/generator"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"

class ResumeGeneratorProjectsTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-corp")
    @application.create_directory!
    @config = Jojo::Config.new(fixture_path("valid_config.yml"))

    File.write(@application.job_description_path, "Ruby developer needed")

    File.write(@application.job_details_path, <<~YAML)
      company_name: Test Corp
      required_skills:
        - Ruby on Rails
    YAML
  end

  def test_generates_resume_using_config_based_pipeline
    mock_ai = Minitest::Mock.new
    # Mock AI calls for all transformations based on permissions config
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # skills: remove
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # skills: reorder
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # languages: reorder
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # databases: remove
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # databases: reorder
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # tools: remove
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # tools: reorder
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # projects: reorder
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # experience: reorder
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # recommendations: remove

    # Scalar/text fields
    mock_ai.expect(:generate_text, "Tailored summary", [String]) # summary: rewrite

    # Nested fields (dot notation)
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # projects.skills: reorder
    mock_ai.expect(:generate_text, "Tailored description", [String]) # experience.description: rewrite
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience.technologies: remove
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience.technologies: reorder
    mock_ai.expect(:generate_text, "[0]", [String]) # experience.tags: remove
    mock_ai.expect(:generate_text, "[0]", [String]) # experience.tags: reorder
    mock_ai.expect(:generate_text, "Tailored education description", [String]) # education.description: rewrite

    generator = Jojo::Commands::Resume::Generator.new(@application, mock_ai, config: @config, inputs_path: fixture_path)
    result = generator.generate

    _(result).must_include "# Jane Doe"
    _(result).must_include "Test Corp"

    mock_ai.verify
  end
end
