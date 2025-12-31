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

  it "includes relevant projects in resume prompt" do
    prompt_received = nil

    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "Generated resume with projects") do |prompt|
      prompt_received = prompt
      true  # Accept any prompt for now
    end

    generator = Jojo::Generators::ResumeGenerator.new(@employer, mock_ai, config: @config, inputs_path: "test/fixtures")
    generator.generate

    # Verify the prompt includes project information
    _(prompt_received).must_include "Rails App"
    _(prompt_received).must_include "Relevant Projects and Achievements"

    mock_ai.verify
  end
end
