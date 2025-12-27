require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/cover_letter_generator'
require_relative '../../../lib/jojo/prompts/cover_letter_prompt'

describe Jojo::Generators::CoverLetterGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::CoverLetterGenerator.new(@employer, @ai_client, config: @config, verbose: false)

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.resume_path, "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer...") # REQUIRED for cover letter
    File.write(@employer.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
    FileUtils.mkdir_p('inputs')

    # Backup user's generic_resume.md if it exists
    @backup_generic_resume = File.read('inputs/generic_resume.md') if File.exist?('inputs/generic_resume.md')

    File.write('inputs/generic_resume.md', "# Jane Doe\n\n## Professional Summary\n\nExperienced developer with 10 years...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)

    # Restore user's generic_resume.md if it existed, otherwise clean up test file
    if @backup_generic_resume
      File.write('inputs/generic_resume.md', @backup_generic_resume)
    else
      FileUtils.rm_f('inputs/generic_resume.md')
    end

    @config.verify if @config
  end

  it "generates cover letter from all inputs" do
    expected_cover_letter = "Dear Hiring Manager,\n\nI am genuinely excited about the opportunity..."
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    result = @generator.generate

    _(result).must_include "Specifically for Acme Corp"
    _(result).must_include "https://tracyatteberry.com/resume/acme-corp"
    _(result).must_include expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  it "saves cover letter to file" do
    expected_cover_letter = "Dear Hiring Manager,\n\nTailored content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    @generator.generate

    _(File.exist?(@employer.cover_letter_path)).must_equal true
    content = File.read(@employer.cover_letter_path)
    _(content).must_include "Specifically for Acme Corp"
    _(content).must_include expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  it "fails when tailored resume is missing" do
    FileUtils.rm_f(@employer.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Tailored resume not found"
  end

  it "fails when generic resume is missing" do
    FileUtils.rm_f('inputs/generic_resume.md')

    error = assert_raises(RuntimeError) do
      @generator.generate
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

    expected_cover_letter = "Cover letter without research insights..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    # Should not raise error
    result = @generator.generate
    _(result).must_include expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  it "generates correct landing page link" do
    expected_cover_letter = "Cover letter content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    result = @generator.generate

    _(result).must_include "**Specifically for Acme Corp**: https://tracyatteberry.com/resume/acme-corp"

    @ai_client.verify
    @config.verify
  end
end
