require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/annotation_generator'

describe Jojo::Generators::AnnotationGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @generator = Jojo::Generators::AnnotationGenerator.new(
      @employer,
      @ai_client,
      verbose: false
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "We need 5+ years of Python and distributed systems experience.")
    File.write(@employer.resume_path, "# John Doe\n\nSenior Python developer with 7 years experience...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates annotations from job description and resume" do
    ai_response = JSON.generate([
      { text: "5+ years of Python", match: "Built Python apps for 7 years", tier: "strong" },
      { text: "distributed systems", match: "Designed fault-tolerant queue", tier: "strong" }
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
      { text: "5+ years of Python", match: "Built Python apps for 7 years", tier: "strong" }
    ])

    @ai_client.expect(:reason, ai_response, [String])

    @generator.generate

    _(File.exist?(@employer.job_description_annotations_path)).must_equal true

    saved_data = JSON.parse(File.read(@employer.job_description_annotations_path), symbolize_names: true)
    _(saved_data.length).must_equal 1
    _(saved_data[0][:text]).must_equal "5+ years of Python"

    @ai_client.verify
  end
end
