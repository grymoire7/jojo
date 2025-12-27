require_relative '../test_helper'
require_relative '../../lib/jojo/generators/website_generator'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/config'

describe 'WebsiteGenerator with Projects' do
  before do
    @employer = Jojo::Employer.new('Test Corp')
    @employer.create_directory!
    @config = Jojo::Config.new('test/fixtures/valid_config.yml')

    # Create job_details.yml
    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
    YAML

    # Create projects.yml
    File.write('inputs/projects.yml', <<~YAML)
      - title: "Matching Project"
        description: "This project matches job requirements"
        skills:
          - Ruby on Rails
          - PostgreSQL
      - title: "Non-matching Project"
        description: "This does not match"
        skills:
          - Python
    YAML
  end

  after do
    FileUtils.rm_rf('employers/test-corp')
    FileUtils.rm_f('inputs/projects.yml')
  end

  it "loads and selects relevant projects" do
    # Mock AI client (not used in this test)
    mock_ai = Minitest::Mock.new

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: @config)

    # Access private method for testing
    projects = generator.send(:load_projects)

    _(projects).wont_be_empty
    _(projects.first[:title]).must_equal 'Matching Project'
    _(projects.first[:score]).must_be :>, 0
  end

  it "includes projects in template variables" do
    # Create minimal job description for full generation
    File.write(@employer.job_description_path, "Test job description")
    File.write(@employer.resume_path, "# Resume\n\nTest resume content")

    # Mock AI client to avoid real API calls
    mock_ai = Minitest::Mock.new
    mock_ai.expect :generate_text, "Test branding statement", [String]

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: @config)
    generator.generate

    # Read generated HTML
    html = File.read(@employer.index_html_path)

    # Should mention the matching project
    _(html).must_include 'Matching Project'

    mock_ai.verify
  end
end
