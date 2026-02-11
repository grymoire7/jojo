require_relative "../test_helper"
require_relative "../../lib/jojo/commands/website/generator"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"

class ProjectsIntegrationWorkflowTest < JojoTest
  def setup
    super
    copy_templates
    @employer = Jojo::Application.new("integration-test-corp")
    @employer.create_directory!

    # Setup all required files
    File.write(@employer.job_description_path, "Looking for Ruby on Rails developer")

    File.write(@employer.job_details_path, <<~YAML)
      company_name: Integration Test Corp
      required_skills:
        - Ruby on Rails
        - PostgreSQL
      desired_skills:
        - leadership
    YAML

    File.write(@employer.resume_path, "# Generic Resume\n\nExperience with Ruby...")
    File.write(@employer.branding_path, "I'm excited about this opportunity because of my Ruby experience.")

    # Create separate test directory to avoid conflicts
    @test_fixtures_dir = Dir.mktmpdir("jojo-test-fixtures-")
    @resume_data_path = File.join(@test_fixtures_dir, "resume_data.yml")
    File.write(@resume_data_path, <<~YAML)
      name: "Jane Doe"
      email: "jane@example.com"
      location: "San Francisco, CA"
      summary: "Test engineer"
      skills:
        - Ruby
        - Python
      experience: []
      projects:
        - name: "E-commerce Platform"
          description: "Built a scalable Rails e-commerce platform"
          year: 2024
          context: "at Previous Corp"
          role: "Lead Developer"
          blog_post_url: "https://example.com/blog/ecommerce"
          url: "https://github.com/user/ecommerce"
          skills:
            - Ruby on Rails
            - PostgreSQL
            - web development

        - name: "Team Leadership Award"
          description: "Recognized for exceptional team leadership"
          year: 2023
          skills:
            - leadership
            - teamwork

        - name: "Python Project"
          description: "Python work"
          skills:
            - Python
            - Django
    YAML
  end

  def teardown
    FileUtils.rm_rf(@employer.base_path) if @employer
    FileUtils.rm_rf(@test_fixtures_dir) if @test_fixtures_dir && File.exist?(@test_fixtures_dir)
    super
  end

  def test_generates_website_with_projects_from_resume_data
    config = Jojo::Config.new(fixture_path("valid_config.yml"))

    mock_ai = Minitest::Mock.new

    generator = Jojo::Commands::Website::Generator.new(@employer, mock_ai, config: config, template: "default", inputs_path: @test_fixtures_dir)
    generator.generate

    html = File.read(@employer.index_html_path)

    # Should include all projects from resume_data
    assert_includes html, "E-commerce Platform"
    assert_includes html, "Team Leadership Award"
    assert_includes html, "Python Project"

    # Should include project metadata
    assert_includes html, "2024"
    assert_includes html, "at Previous Corp"

    # Should include links
    assert_includes html, "https://example.com/blog/ecommerce"
    assert_includes html, "https://github.com/user/ecommerce"

    mock_ai.verify
  end
end
