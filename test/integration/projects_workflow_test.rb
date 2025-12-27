require_relative '../test_helper'
require_relative '../../lib/jojo/generators/website_generator'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/config'

describe 'Projects Integration Workflow' do
  before do
    @employer = Jojo::Employer.new('Integration Test Corp')
    @employer.create_directory!

    # Setup all required files
    File.write(@employer.job_description_path, "Looking for Ruby on Rails developer")

    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
      desired_skills:
        - leadership
    YAML

    File.write(@employer.resume_path, "# Generic Resume\n\nExperience with Ruby...")

    File.write('inputs/projects.yml', <<~YAML)
      - title: "E-commerce Platform"
        description: "Built a scalable Rails e-commerce platform"
        year: 2024
        context: "at Previous Corp"
        role: "Lead Developer"
        blog_post_url: "https://example.com/blog/ecommerce"
        github_url: "https://github.com/user/ecommerce"
        skills:
          - Ruby on Rails
          - PostgreSQL
          - web development

      - title: "Team Leadership Award"
        description: "Recognized for exceptional team leadership"
        year: 2023
        skills:
          - leadership
          - teamwork

      - title: "Python Project"
        description: "Unrelated Python work"
        skills:
          - Python
          - Django
    YAML
  end

  after do
    FileUtils.rm_rf('employers/integration-test-corp')
    FileUtils.rm_f('inputs/projects.yml')
  end

  it "generates website with relevant projects only" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')

    mock_ai = Minitest::Mock.new
    mock_ai.expect :generate_text, "Branding statement", [String]

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: config, template: 'default')
    generator.generate

    html = File.read(@employer.index_html_path)

    # Should include matching projects
    _(html).must_include 'E-commerce Platform'
    _(html).must_include 'Team Leadership Award'

    # Should NOT include non-matching project
    _(html).wont_include 'Python Project'

    # Should include project metadata
    _(html).must_include '2024'
    _(html).must_include 'at Previous Corp'

    # Should include links
    _(html).must_include 'https://example.com/blog/ecommerce'
    _(html).must_include 'https://github.com/user/ecommerce'

    mock_ai.verify
  end
end
