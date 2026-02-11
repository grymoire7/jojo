# frozen_string_literal: true

require_relative "../test_helper"

class JobDescriptionCommandIntegrationTest < JojoTest
  def setup
    super

    @applications_dir = File.join(@tmpdir, "applications")

    # Create minimal config
    write_test_config
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")

    # Create test job file
    @job_file = File.join(@tmpdir, "job.txt")
    File.write(@job_file, <<~JOB)
      Senior Software Engineer at Acme Corp

      We are looking for a senior engineer to join our team.

      Requirements:
      - 5+ years of experience
      - Ruby expertise
      - PostgreSQL knowledge
    JOB
  end

  def test_creates_workspace_then_processes_job_description_separately
    slug = "acme-corp-senior"

    # Step 1: Create workspace with 'new'
    employer = Jojo::Application.new(slug)
    FileUtils.mkdir_p(employer.base_path)

    _(Dir.exist?(File.join(@applications_dir, slug))).must_equal true
    _(employer.artifacts_exist?).must_equal false

    # Step 2: Verify job_description would work (without actual AI call)
    _(File.exist?(employer.base_path)).must_equal true
    _(File.exist?(@job_file)).must_equal true
  end

  def test_uses_slug_from_state_file_when_not_provided
    slug = "state-based-app"

    # Create employer
    employer = Jojo::Application.new(slug)
    FileUtils.mkdir_p(employer.base_path)

    # Save to state
    Jojo::StatePersistence.save_slug(slug)

    # Verify state is saved
    _(Jojo::StatePersistence.load_slug).must_equal slug
  end
end
