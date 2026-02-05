# test/unit/commands/annotate/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/application"
require_relative "../../../../lib/jojo/commands/annotate/generator"

describe Jojo::Commands::Annotate::Generator do
  before do
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

  after do
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
  end

  it "generates annotations from job description and resume" do
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

  it "saves annotations to JSON file" do
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

  it "raises error when job description missing" do
    FileUtils.rm_f(@application.job_description_path)

    _ { @generator.generate }.must_raise RuntimeError
  end

  it "raises error when resume missing" do
    FileUtils.rm_f(@application.resume_path)

    _ { @generator.generate }.must_raise RuntimeError
  end

  it "handles missing research gracefully" do
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

  it "raises error when AI returns invalid JSON" do
    @ai_client.expect(:reason, "This is not JSON", [String])

    _ { @generator.generate }.must_raise RuntimeError
  end

  it "handles JSON wrapped in markdown code fences" do
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
