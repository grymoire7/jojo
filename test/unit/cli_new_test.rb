require "test_helper"
require "fileutils"
require "tmpdir"

class CLINewTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # Create minimal config files
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    File.write("config.yml", "seeker:\n  name: Test User\n  base_url: https://example.com\n")

    # Create inputs directory with resume data
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_new_command_requires_slug
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new 2>&1 || true")
    end

    output = out + err
    assert_match(/required.*slug/i, output)
  end

  def test_new_command_creates_employer_directory
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new -s test-employer 2>&1")
    end

    output = out + err
    assert_match(/created/i, output)
    assert Dir.exist?("employers/test-employer")
  end

  def test_new_command_fails_if_directory_already_exists
    FileUtils.mkdir_p("employers/existing-employer")

    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new -s existing-employer 2>&1 || true")
    end

    output = out + err
    assert_match(/already exists/i, output)
  end

  def test_employer_initialize_with_slug
    employer = Jojo::Employer.new("test-slug")
    assert_equal "test-slug", employer.slug
    assert_equal "test-slug", employer.name
  end

  def test_artifacts_exist_returns_false_when_no_artifacts
    employer = Jojo::Employer.new("test-employer")
    refute employer.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_description_exists
    employer = Jojo::Employer.new("test-employer")
    FileUtils.mkdir_p(employer.base_path)
    File.write(employer.job_description_path, "test content")

    assert employer.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_details_exists
    employer = Jojo::Employer.new("test-employer")
    FileUtils.mkdir_p(employer.base_path)
    File.write(employer.job_details_path, "company_name: Test\n")

    assert employer.artifacts_exist?
  end
end
