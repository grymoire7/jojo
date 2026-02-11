# test/unit/commands/annotate/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/annotate/generator"

class Jojo::Commands::Annotate::GeneratorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @generator = Jojo::Commands::Annotate::Generator.new(
      @application,
      @ai_client,
      verbose: false
    )

    # Clean up and create directories
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
    @application.create_directory!

    # Create required fixtures
    File.write(@application.job_description_path, "We need 5+ years of Python and distributed systems experience.")
    File.write(@application.resume_path, "# John Doe\n\nSenior Python developer with 7 years experience...")
  end

  def test_generates_annotations_from_job_description_and_resume
    ai_response = JSON.generate([
      {text: "5+ years of Python", match: "Built Python apps for 7 years", tier: "strong"},
      {text: "distributed systems", match: "Designed fault-tolerant queue", tier: "strong"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    _(result).must_be_kind_of Array
    _(result.length).must_equal 2
    _(result[0][:text]).must_equal "5+ years of Python"
    _(result[0][:tier]).must_equal "strong"

    @ai_client.verify
  end

  def test_saves_annotations_to_json_file
    ai_response = JSON.generate([
      {text: "5+ years of Python", match: "Built Python apps for 7 years", tier: "strong"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    @generator.generate

    _(File.exist?(@application.job_description_annotations_path)).must_equal true

    saved_data = JSON.parse(File.read(@application.job_description_annotations_path), symbolize_names: true)
    _(saved_data.length).must_equal 1
    _(saved_data[0][:text]).must_equal "5+ years of Python"

    @ai_client.verify
  end

  def test_raises_error_when_job_description_missing
    FileUtils.rm_f(@application.job_description_path)

    _ { @generator.generate }.must_raise RuntimeError
  end

  def test_raises_error_when_resume_missing
    FileUtils.rm_f(@application.resume_path)

    _ { @generator.generate }.must_raise RuntimeError
  end

  def test_handles_missing_research_gracefully
    FileUtils.rm_f(@application.research_path)

    ai_response = JSON.generate([
      {text: "Python", match: "7 years experience", tier: "strong"}
    ])

    @ai_client.expect(:reason, ai_response, [String])

    # Should not raise error
    result = @generator.generate
    _(result).must_be_kind_of Array

    @ai_client.verify
  end

  def test_raises_error_when_ai_returns_invalid_json
    @ai_client.expect(:reason, "This is not JSON", [String])

    _ { @generator.generate }.must_raise RuntimeError
  end

  def test_handles_json_wrapped_in_markdown_code_fences
    # AI returns JSON wrapped in markdown code fences (common behavior)
    ai_response = <<~RESPONSE.strip
      ```json
      [
        {
          "text": "5+ years of Python",
          "match": "Built Python apps for 7 years",
          "tier": "strong"
        }
      ]
      ```
    RESPONSE

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    _(result).must_be_kind_of Array
    _(result.length).must_equal 1
    _(result[0][:text]).must_equal "5+ years of Python"

    @ai_client.verify
  end
end
