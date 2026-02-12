# test/integration/annotate_generator_integration_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/annotate/generator"

class AnnotateGeneratorIntegrationTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @application.create_directory!

    File.write(@application.job_description_path, <<~MD)
      # Senior Ruby Developer at Acme Corp

      ## Requirements
      - 5+ years of Ruby on Rails experience
      - Strong PostgreSQL knowledge
      - Experience with Docker and containerization
      - CI/CD pipeline experience
    MD

    File.write(@application.resume_path, <<~MD)
      # Jane Doe
      Senior Ruby developer with 7 years of experience building scalable web applications.

      ## Experience
      - TechCorp: Led Rails development for 3 years
      - Built Docker-based deployment pipelines
    MD

    File.write(@application.research_path, <<~MD)
      # Acme Corp Research
      Acme Corp is a SaaS company focused on developer tools.
    MD
  end

  def test_full_annotation_pipeline_with_research
    ai_response = JSON.generate([
      {text: "5+ years of Ruby on Rails experience", match: "7 years of experience building scalable web applications", tier: "strong"},
      {text: "Strong PostgreSQL knowledge", match: "No direct mention", tier: "gap"},
      {text: "Docker and containerization", match: "Built Docker-based deployment pipelines", tier: "strong"},
      {text: "CI/CD pipeline experience", match: "Built Docker-based deployment pipelines", tier: "partial"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    generator = Jojo::Commands::Annotate::Generator.new(@application, @ai_client, verbose: false)
    result = generator.generate

    assert_kind_of Array, result
    assert_equal 4, result.length
    assert_equal "strong", result[0][:tier]
    assert_equal "gap", result[1][:tier]

    # Verify file was saved
    assert File.exist?(@application.job_description_annotations_path)
    saved = JSON.parse(File.read(@application.job_description_annotations_path), symbolize_names: true)
    assert_equal 4, saved.length

    @ai_client.verify
  end

  def test_annotation_pipeline_without_research
    FileUtils.rm_f(@application.research_path)

    ai_response = JSON.generate([
      {text: "Ruby on Rails", match: "7 years experience", tier: "strong"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    generator = Jojo::Commands::Annotate::Generator.new(@application, @ai_client, verbose: false)
    result = generator.generate

    assert_equal 1, result.length
    @ai_client.verify
  end
end
