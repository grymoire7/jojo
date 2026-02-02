# test/unit/commands/resume/generator_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/employer"
require_relative "../../../../lib/jojo/commands/resume/generator"

describe Jojo::Commands::Resume::Generator do
  before do
    @employer = Jojo::Employer.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Commands::Resume::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures"
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.job_details_path, "company_name: Acme Corp\n")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates resume using ResumeCurationService" do
    # Mock config for permissions and base_url
    @config.expect(:dig, {"skills" => ["remove", "reorder"]}, ["resume_data", "permissions"])
    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    # Mock AI calls for transformation
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    result = @generator.generate

    _(result).must_include "# Jane Doe"
    _(result).must_include "Specifically for Acme Corp"
    _(result).must_include "https://example.com/resume/acme-corp"

    @ai_client.verify
  end

  it "saves resume to file" do
    @config.expect(:dig, {"skills" => ["remove", "reorder"]}, ["resume_data", "permissions"])
    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    @generator.generate

    _(File.exist?(@employer.resume_path)).must_equal true
    content = File.read(@employer.resume_path)
    _(content).must_include "Specifically for Acme Corp"
  end

  it "fails when resume_data.yml is missing" do
    generator_no_data = Jojo::Commands::Resume::Generator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures/nonexistent"
    )

    @config.expect(:resume_template, nil)

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      generator_no_data.generate
    end

    _(error.message).must_include "not found"
  end
end
