require_relative "../test_helper"
require_relative "../../lib/jojo/generators/website_generator"
require_relative "../../lib/jojo/employer"
require_relative "../../lib/jojo/config"

describe "WebsiteGenerator with Projects" do
  before do
    @employer = Jojo::Employer.new("test-corp")
    @employer.create_directory!
    @config = Jojo::Config.new("test/fixtures/valid_config.yml")

    # Create job_details.yml
    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
    YAML

    # Create test fixtures directory and resume_data.yml with projects
    FileUtils.mkdir_p("test/fixtures")
    @resume_data_path = "test/fixtures/test_resume_data.yml"
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
        - name: "Rails Project"
          description: "This project matches job requirements"
          skills:
            - Ruby on Rails
            - PostgreSQL
        - name: "Python Project"
          description: "This does not match"
          skills:
            - Python
    YAML
  end

  after do
    FileUtils.rm_rf("employers/test-corp")
    FileUtils.rm_f(@resume_data_path)
    FileUtils.rm_rf("test/fixtures/images") if File.exist?("test/fixtures/images")
  end

  it "loads projects from resume_data.yml" do
    # Mock AI client (not used in this test)
    mock_ai = Minitest::Mock.new

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: @config, inputs_path: "test/fixtures")

    # Access private method for testing
    projects = generator.send(:load_projects)

    _(projects).wont_be_empty
    _(projects.first[:name]).must_equal "Rails Project"
    _(projects.first[:skills]).must_include "Ruby on Rails"
  end

  it "includes projects in template variables" do
    # Create minimal job description for full generation
    File.write(@employer.job_description_path, "Test job description")
    File.write(@employer.resume_path, "# Resume\n\nTest resume content")

    # Mock AI client to avoid real API calls
    mock_ai = Minitest::Mock.new
    mock_ai.expect :generate_text, "Test branding statement", [String]

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: @config, inputs_path: "test/fixtures")
    generator.generate

    # Read generated HTML
    html = File.read(@employer.index_html_path)

    # Should mention the project
    _(html).must_include "Rails Project"

    mock_ai.verify
  end

  it "copies local project images to website directory" do
    # Create test image
    FileUtils.mkdir_p("test/fixtures/images")
    File.write("test/fixtures/images/test.png", "fake image data")

    # Update resume_data.yml with image
    File.write(@resume_data_path, <<~YAML)
      name: "Jane Doe"
      email: "jane@example.com"
      location: "San Francisco, CA"
      summary: "Test engineer"
      skills:
        - Ruby
      experience: []
      projects:
        - name: "Project with Image"
          description: "Has a local image"
          skills:
            - Ruby on Rails
          image: "test/fixtures/images/test.png"
    YAML

    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
    YAML

    File.write(@employer.job_description_path, "Test job")
    File.write(@employer.resume_path, "# Resume\n\nTest resume content")

    mock_ai = Minitest::Mock.new
    mock_ai.expect :generate_text, "Test branding", [String]

    generator = Jojo::Generators::WebsiteGenerator.new(@employer, mock_ai, config: @config, inputs_path: "test/fixtures")
    generator.generate

    # Check image was copied
    copied_image = File.join(@employer.website_path, "images", "test.png")
    _(File.exist?(copied_image)).must_equal true

    # Check HTML references image correctly
    html = File.read(@employer.index_html_path)
    _(html).must_include 'src="images/test.png"'

    mock_ai.verify
  end
end
