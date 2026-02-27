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

    # Nested fields (dot notation) - each employer/project processed independently
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # projects.skills[0]: reorder (Open Source CLI Tool)
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # projects.skills[1]: reorder (E-commerce Platform)
    mock_ai.expect(:generate_text, "Tailored description 1", [String]) # experience[0].description: rewrite
    mock_ai.expect(:generate_text, "Tailored description 2", [String]) # experience[1].description: rewrite
    mock_ai.expect(:generate_text, "Tailored description 3", [String]) # experience[2].description: rewrite
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience[0].technologies: remove (TechCorp)
    mock_ai.expect(:generate_text, "[0, 2]", [String]) # experience[1].technologies: remove (StartupXYZ)
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience[2].technologies: remove (ConsultingCo)
    mock_ai.expect(:generate_text, "[1, 0]", [String]) # experience[0].technologies: reorder (TechCorp, 2 items)
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience[1].technologies: reorder (StartupXYZ, 2 items)
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience[2].technologies: reorder (ConsultingCo, 2 items)
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience[0].tags: remove (TechCorp, 3 items)
    mock_ai.expect(:generate_text, "[0]", [String])    # experience[1].tags: remove (StartupXYZ, 2 items)
    mock_ai.expect(:generate_text, "[0]", [String])    # experience[2].tags: remove (ConsultingCo, 2 items)
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience[0].tags: reorder (TechCorp, 2 items)
    mock_ai.expect(:generate_text, "[0]", [String])    # experience[1].tags: reorder (StartupXYZ, 1 item)
    mock_ai.expect(:generate_text, "[0]", [String])    # experience[2].tags: reorder (ConsultingCo, 1 item)
    mock_ai.expect(:generate_text, "Tailored education description", [String]) # education.description: rewrite

    generator = Jojo::Commands::Resume::Generator.new(@application, mock_ai, config: @config, inputs_path: fixture_path)
    result = generator.generate

    assert_includes result, "# Jane Doe"
    assert_includes result, "Test Corp"

    mock_ai.verify
  end
end
