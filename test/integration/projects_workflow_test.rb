require_relative "../test_helper"
require_relative "../../lib/jojo/generators/website_generator"
require_relative "../../lib/jojo/employer"
require_relative "../../lib/jojo/config"

describe "Projects Integration Workflow" do
  before do
    @employer = Jojo::Employer.new("integration-test-corp")
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

  after do
    FileUtils.rm_rf("employers/integration-test-corp")
    FileUtils.rm_rf(@test_fixtures_dir) if @test_fixtures_dir && File.exist?(@test_fixtures_dir)
  end

  it "generates website with projects from resume_data.yml" do
    config = Jojo::Config.new("test/fixtures/valid_config.yml")

    mock_ai = Minitest::Mock.new

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: config, template: "default", inputs_path: @test_fixtures_dir)
    generator.generate

    html = File.read(@employer.index_html_path)

    # Should include all projects from resume_data
    _(html).must_include "E-commerce Platform"
    _(html).must_include "Team Leadership Award"
    _(html).must_include "Python Project"

    # Should include project metadata
    _(html).must_include "2024"
    _(html).must_include "at Previous Corp"

    # Should include links
    _(html).must_include "https://example.com/blog/ecommerce"
    _(html).must_include "https://github.com/user/ecommerce"

    mock_ai.verify
  end
end
