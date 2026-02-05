# test/unit/commands/branding/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/employer"
require_relative "../../../../lib/jojo/commands/branding/generator"

class BrandingGeneratorTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone

  def initialize
    @seeker_name = "Jane Doe"
    @voice_and_tone = "professional and friendly"
  end
end

describe Jojo::Commands::Branding::Generator do
  before do
    @application = Jojo::Application.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = BrandingGeneratorTestConfigStub.new
    @generator = Jojo::Commands::Branding::Generator.new(
      @application,
      @ai_client,
      config: @config,
      verbose: false
    )

    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer role...")
    File.write(@application.resume_path, "# Jane Doe\n\nSenior Ruby developer...")
  end

  after do
    FileUtils.rm_rf(@application.base_path) if Dir.exist?(@application.base_path)
  end

  it "generates branding statement and saves to file" do
    expected_branding = "I'm a perfect fit for Acme Corp...\n\nMy experience aligns perfectly..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    _(result).must_equal expected_branding
    _(File.exist?(@application.branding_path)).must_equal true
    _(File.read(@application.branding_path)).must_equal expected_branding

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

    expected_branding = "Branding without research..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate
    _(result).must_equal expected_branding

    @ai_client.verify
  end

  it "handles missing job_details gracefully" do
    FileUtils.rm_f(@application.job_details_path)

    expected_branding = "Branding without job details..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate
    _(result).must_equal expected_branding

    @ai_client.verify
  end
end
