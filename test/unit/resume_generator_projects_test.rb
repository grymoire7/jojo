require_relative "../test_helper"
require_relative "../../lib/jojo/commands/resume/generator"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"

describe "Jojo::Commands::Resume::Generator with Projects" do
  before do
    @application = Jojo::Application.new("test-corp")
    @application.create_directory!
    @config = Jojo::Config.new("test/fixtures/valid_config.yml")

    File.write(@application.job_description_path, "Ruby developer needed")
    FileUtils.mkdir_p("test/fixtures")

    File.write(@application.job_details_path, <<~YAML)
      company_name: Test Corp
      required_skills:
        - Ruby on Rails
    YAML

    # Use existing resume_data.yml fixture which has projects
  end

  after do
    FileUtils.rm_rf("applications/test-corp")
  end

  it "generates resume using config-based pipeline" do
    # Note: Projects are now part of resume_data.yml and can be filtered/reordered
    # This test validates the basic generation works with projects in resume_data

    mock_ai = Minitest::Mock.new
    # Mock AI calls for all transformations based on permissions config
    # Top-level array fields
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
    mock_ai.expect(:generate_text, "[0, 1, 2]", [String]) # projects.skills: reorder (3 skills in first project)
    mock_ai.expect(:generate_text, "Tailored description", [String]) # experience.description: rewrite
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience.technologies: remove
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # experience.technologies: reorder
    mock_ai.expect(:generate_text, "[0]", [String]) # experience.tags: remove
    mock_ai.expect(:generate_text, "[0]", [String]) # experience.tags: reorder
    mock_ai.expect(:generate_text, "Tailored education description", [String]) # education.description: rewrite

    generator = Jojo::Commands::Resume::Generator.new(@application, mock_ai, config: @config, inputs_path: "test/fixtures")
    result = generator.generate

    # Verify resume was generated
    _(result).must_include "# Jane Doe"
    _(result).must_include "Test Corp"

    mock_ai.verify
  end
end
