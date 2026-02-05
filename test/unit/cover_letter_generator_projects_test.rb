require_relative "../test_helper"
require_relative "../../lib/jojo/commands/cover_letter/generator"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/config"

describe "Jojo::Commands::CoverLetter::Generator with Projects" do
  before do
    @application = Jojo::Application.new("test-corp")
    @application.create_directory!
    @config = Jojo::Config.new("test/fixtures/valid_config.yml")

    File.write(@application.job_description_path, "Ruby developer needed")
    File.write(@application.resume_path, "# Resume\n\nTailored resume...")

    File.write(@application.job_details_path, <<~YAML)
      company_name: Test Corp
      required_skills:
        - Ruby on Rails
    YAML

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
      experience: []
      projects:
        - name: "Rails App"
          description: "Built a Rails application"
          skills:
            - Ruby on Rails
    YAML
  end

  after do
    FileUtils.rm_rf("applications/test-corp")
    FileUtils.rm_rf(@test_fixtures_dir) if @test_fixtures_dir && File.exist?(@test_fixtures_dir)
  end

  it "includes relevant projects in cover letter prompt" do
    prompt_received = nil

    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "Generated cover letter with projects") do |prompt|
      prompt_received = prompt
      true
    end

    generator = Jojo::Commands::CoverLetter::Generator.new(@application, mock_ai, config: @config, inputs_path: @test_fixtures_dir)
    generator.generate

    # Verify the prompt includes project information
    _(prompt_received).must_include "Rails App"
    _(prompt_received).must_include "Projects to Highlight"

    mock_ai.verify
  end
end
