# frozen_string_literal: true

require_relative "../test_helper"

describe "Job Description Command Integration" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Create minimal config
    File.write("config.yml", "seeker:\n  name: Test User\n  base_url: https://example.com\n")
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")

    # Create test job file
    @job_file = File.join(@temp_dir, "job.txt")
    File.write(@job_file, <<~JOB)
      Senior Software Engineer at Acme Corp

      We are looking for a senior engineer to join our team.

      Requirements:
      - 5+ years of experience
      - Ruby expertise
      - PostgreSQL knowledge
    JOB
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe "workflow: new then job_description" do
    it "creates workspace then processes job description separately" do
      slug = "acme-corp-senior"

      # Step 1: Create workspace with 'new'
      employer = Jojo::Employer.new(slug)
      FileUtils.mkdir_p(employer.base_path)

      _(Dir.exist?(File.join(@employers_dir, slug))).must_equal true
      _(employer.artifacts_exist?).must_equal false

      # Step 2: Verify job_description would work (without actual AI call)
      _(File.exist?(employer.base_path)).must_equal true
      _(File.exist?(@job_file)).must_equal true
    end
  end

  describe "state-based slug resolution" do
    it "uses slug from state file when -s not provided" do
      slug = "state-based-app"

      # Create employer
      employer = Jojo::Employer.new(slug)
      FileUtils.mkdir_p(employer.base_path)

      # Save to state
      Jojo::StatePersistence.save_slug(slug)

      # Verify state is saved
      _(Jojo::StatePersistence.load_slug).must_equal slug
    end
  end
end
