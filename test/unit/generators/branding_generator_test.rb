require_relative "../../test_helper"
require_relative "../../../lib/jojo/employer"
require_relative "../../../lib/jojo/generators/branding_generator"

class BrandingGeneratorTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone

  def initialize
    @seeker_name = "Jane Doe"
    @voice_and_tone = "professional and friendly"
  end
end

describe Jojo::Generators::BrandingGenerator do
  before do
    @employer = Jojo::Employer.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = BrandingGeneratorTestConfigStub.new
    @generator = Jojo::Generators::BrandingGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    File.write(@employer.job_description_path, "Senior Ruby Developer role...")
    File.write(@employer.resume_path, "# Jane Doe\n\nSenior Ruby developer...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates branding statement and saves to file" do
    expected_branding = "I'm a perfect fit for Acme Corp...\n\nMy experience aligns perfectly..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    _(result).must_equal expected_branding
    _(File.exist?(@employer.branding_path)).must_equal true
    _(File.read(@employer.branding_path)).must_equal expected_branding

    @ai_client.verify
  end
end
