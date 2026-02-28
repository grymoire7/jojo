require_relative "../test_helper"
require_relative "../../lib/jojo/commands/cover_letter/generator"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"

class CoverLetterGeneratorProjectsTest < JojoTest
  def setup
    super
    copy_templates
    @application = Jojo::Application.new("test-corp")
    @application.create_directory!
    @config = Jojo::Config.new(fixture_path("valid_config.yml"))

    File.write(@application.job_description_path, "Ruby developer needed")
    File.write(@application.resume_path, "# Resume\n\nTailored resume...")

    File.write(@application.job_details_path, <<~YAML)
      company_name: Test Corp
      required_skills:
        - Ruby on Rails
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
      experience: []
      projects:
        - name: "Rails App"
          description: "Built a Rails application"
          skills:
            - Ruby on Rails
    YAML
  end

  def teardown
    FileUtils.rm_rf(@test_fixtures_dir) if @test_fixtures_dir && File.exist?(@test_fixtures_dir)
    super
  end

  def test_includes_relevant_projects_in_cover_letter_prompt
    prompt_received = nil

    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "Generated cover letter with projects") do |prompt|
      prompt_received = prompt
      true
    end

    generator = Jojo::Commands::CoverLetter::Generator.new(@application, mock_ai, config: @config, inputs_path: @test_fixtures_dir)
    generator.generate

    assert_includes prompt_received, "Rails App"
    assert_includes prompt_received, "Projects to Highlight"

    mock_ai.verify
  end
end
