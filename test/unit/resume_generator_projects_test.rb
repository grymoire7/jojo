require_relative "../test_helper"
require_relative "../../lib/jojo/generators/resume_generator"
require_relative "../../lib/jojo/employer"
require_relative "../../lib/jojo/config"

describe "ResumeGenerator with Projects" do
  before do
    @employer = Jojo::Employer.new("test-corp")
    @employer.create_directory!
    @config = Jojo::Config.new("test/fixtures/valid_config.yml")

    File.write(@employer.job_description_path, "Ruby developer needed")
    FileUtils.mkdir_p("test/fixtures")

    File.write(@employer.job_details_path, <<~YAML)
      company_name: Test Corp
      required_skills:
        - Ruby on Rails
    YAML

    File.write("test/fixtures/projects.yml", <<~YAML)
      - title: "Rails App"
        description: "Built a Rails application"
        skills:
          - Ruby on Rails
    YAML
  end

  after do
    FileUtils.rm_rf("employers/test-corp")
    FileUtils.rm_f("test/fixtures/projects.yml")
  end

  it "generates resume using config-based pipeline" do
    # Note: The new implementation doesn't use project selection in prompts
    # Projects are now part of resume_data.yml and can be filtered/reordered
    # This test now validates the basic generation works

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
    mock_ai.expect(:generate_text, "[0, 1]", [String]) # endorsements: remove

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

    generator = Jojo::Generators::ResumeGenerator.new(@employer, mock_ai, config: @config, inputs_path: "test/fixtures")
    result = generator.generate

    # Verify resume was generated
    _(result).must_include "# Jane Doe"
    _(result).must_include "Test Corp"

    mock_ai.verify
  end
end
