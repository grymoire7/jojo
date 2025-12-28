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
end
