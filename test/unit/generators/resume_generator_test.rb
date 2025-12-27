require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/resume_generator'
require_relative '../../../lib/jojo/prompts/resume_prompt'

describe Jojo::Generators::ResumeGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::ResumeGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: 'test/fixtures'
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @config.verify if @config
  end

  it "generates resume from all inputs" do
    expected_resume = "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer..."
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    result = @generator.generate

    _(result).must_include "Specifically for Acme Corp"
    _(result).must_include "https://tracyatteberry.com/resume/acme-corp"
    _(result).must_include expected_resume

    @ai_client.verify
    @config.verify
  end

  it "saves resume to file" do
    expected_resume = "# Jane Doe\n\nTailored content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    @generator.generate

    _(File.exist?(@employer.resume_path)).must_equal true
    content = File.read(@employer.resume_path)
    _(content).must_include "Specifically for Acme Corp"
    _(content).must_include expected_resume

    @ai_client.verify
    @config.verify
  end

  it "fails when generic resume is missing" do
    # Create a generator with a nonexistent inputs path
    generator_no_resume = Jojo::Generators::ResumeGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: 'test/fixtures/nonexistent'
    )

    error = assert_raises(RuntimeError) do
      generator_no_resume.generate
    end

    _(error.message).must_include "Generic resume not found"
  end

  it "fails when job description is missing" do
    FileUtils.rm_f(@employer.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  it "continues when research is missing with warning" do
    FileUtils.rm_f(@employer.research_path)

    expected_resume = "# Jane Doe\n\nContent without research..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    # Should not raise error
    result = @generator.generate
    _(result).must_include expected_resume

    @ai_client.verify
    @config.verify
  end

  it "generates correct landing page link" do
    expected_resume = "Resume content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    result = @generator.generate

    _(result).must_include "**Specifically for Acme Corp**: https://tracyatteberry.com/resume/acme-corp"

    @ai_client.verify
    @config.verify
  end
end
