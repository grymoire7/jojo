require "test_helper"
require "fileutils"
require "tmpdir"

class CLIJobDescriptionTest < JojoTest
  def setup
    super

    # Create minimal config files
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    File.write("config.yml", "seeker:\n  name: Test User\n  base_url: https://example.com\n")

    # Create inputs directory with resume data
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")

    # Create test job description file
    @job_file = File.join(@tmpdir, "job.txt")
    File.write(@job_file, "Test job description\nSenior Engineer at Acme Corp\n")

    # Create applications directory
    FileUtils.mkdir_p("applications")
  end

  def test_job_description_command_requires_job_parameter
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} job_description -s test-employer 2>&1 || true")
    end

    output = out + err
    assert_match(/required.*job/i, output)
  end

  def test_job_description_command_fails_when_employer_does_not_exist
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} job_description -s nonexistent -j #{@job_file} 2>&1 || true")
    end

    output = out + err
    assert_match(/does not exist/i, output)
  end

  def test_job_description_command_uses_slug_from_state_when_not_provided
    FileUtils.mkdir_p("applications/state-test")
    File.write(".jojo_state", "state-test")

    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} job_description -j #{@job_file} 2>&1 || true")
    end

    output = out + err
    refute_match(/no application specified/i, output)
  end

  def test_job_description_command_fails_when_no_slug_available
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} job_description -j #{@job_file} 2>&1 || true")
    end

    output = out + err
    assert_match(/no application specified/i, output)
  end
end
