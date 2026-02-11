require_relative "../test_helper"
require_relative "../../lib/jojo/commands/website/generator"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"

class WebsiteGeneratorProjectsTest < JojoTest
  def setup
    super
    copy_templates
    @application = Jojo::Application.new("test-corp")
    @application.create_directory!
    @config = Jojo::Config.new(fixture_path("valid_config.yml"))

    File.write(@application.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
    YAML

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

  def teardown
    FileUtils.rm_rf(@test_fixtures_dir) if @test_fixtures_dir && File.exist?(@test_fixtures_dir)
    super
  end

  def test_loads_projects_from_resume_data_yml
    mock_ai = Minitest::Mock.new

    generator = Jojo::Commands::Website::Generator.new(@application, mock_ai, config: @config, inputs_path: @test_fixtures_dir)

    projects = generator.send(:load_projects)

    refute_empty projects
    assert_equal "Rails Project", projects.first[:name]
    assert_includes projects.first[:skills], "Ruby on Rails"
  end

  def test_includes_projects_in_template_variables
    File.write(@application.job_description_path, "Test job description")
    File.write(@application.resume_path, "# Resume\n\nTest resume content")
    File.write(@application.branding_path, "Test branding statement")

    mock_ai = Minitest::Mock.new

    generator = Jojo::Commands::Website::Generator.new(@application, mock_ai, config: @config, inputs_path: @test_fixtures_dir)
    generator.generate

    html = File.read(@application.index_html_path)

    assert_includes html, "Rails Project"
  end

  def test_copies_local_project_images_to_website_directory
    test_images_dir = File.join(@test_fixtures_dir, "images")
    FileUtils.mkdir_p(test_images_dir)
    File.write(File.join(test_images_dir, "test.png"), "fake image data")

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
          image: "images/test.png"
    YAML

    File.write(@application.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
    YAML

    File.write(@application.job_description_path, "Test job")
    File.write(@application.resume_path, "# Resume\n\nTest resume content")
    File.write(@application.branding_path, "Test branding")

    mock_ai = Minitest::Mock.new

    generator = Jojo::Commands::Website::Generator.new(@application, mock_ai, config: @config, inputs_path: @test_fixtures_dir)
    generator.generate

    copied_image = File.join(@application.website_path, "images", "test.png")
    assert_equal true, File.exist?(copied_image)

    html = File.read(@application.index_html_path)
    assert_includes html, 'src="images/test.png"'
  end
end
