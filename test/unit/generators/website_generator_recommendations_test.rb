require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/website_generator'
require_relative '../../../lib/jojo/config'
require 'tmpdir'
require 'fileutils'

describe 'WebsiteGenerator with Recommendations' do
  # Simple config stub to avoid complex mock expectations
  class TestConfigStub
    attr_accessor :seeker_name, :voice_and_tone, :website_cta_text, :website_cta_link, :base_url

    def initialize
      @seeker_name = "Test User"
      @voice_and_tone = "professional"
      @website_cta_text = "Get in touch"
      @website_cta_link = nil
      @base_url = "https://example.com"
    end
  end

  before do
    @employer = Jojo::Employer.new('Test Corp')

    # Create required files
    FileUtils.mkdir_p(@employer.base_path)
    File.write(@employer.job_description_path, "Job description")
    File.write(@employer.resume_path, "Resume content")

    # Mock AI client
    @ai_client = Minitest::Mock.new
    @ai_client.expect(:generate_text, "Branding statement", [String])

    # Config stub
    @config = TestConfigStub.new
  end

  after do
    FileUtils.rm_rf(@employer.base_path)
    FileUtils.rm_rf('inputs') if File.exist?('inputs')
  end

  it "includes recommendations in template vars when file exists" do
    # Create recommendations file in inputs
    inputs_path = 'inputs'
    FileUtils.mkdir_p(inputs_path)
    File.write(
      File.join(inputs_path, 'recommendations.md'),
      File.read('test/fixtures/recommendations.md')
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    html = generator.generate

    # Should include recommendations in output
    _(html).must_include 'Jane Smith'
    _(html).must_include 'excellent engineer'
  end

  it "handles missing recommendations file gracefully" do
    inputs_path = 'inputs'
    FileUtils.mkdir_p(inputs_path)
    # No recommendations.md file

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    # Should not raise error
    html = generator.generate
    _(html).wont_be_nil
  end
end
