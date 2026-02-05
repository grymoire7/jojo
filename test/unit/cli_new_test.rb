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

  def test_new_command_creates_application_directory
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new -s test-application 2>&1")
    end

    output = out + err
    assert_match(/created/i, output)
    assert Dir.exist?("applications/test-application")
  end

  def test_new_command_fails_if_directory_already_exists
    FileUtils.mkdir_p("applications/existing-application")

    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new -s existing-application 2>&1 || true")
    end

    output = out + err
    assert_match(/already exists/i, output)
  end

  def test_application_initialize_with_slug
    app = Jojo::Application.new("test-slug")
    assert_equal "test-slug", app.slug
    assert_equal "test-slug", app.name
  end

  def test_artifacts_exist_returns_false_when_no_artifacts
    app = Jojo::Application.new("test-application")
    refute app.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_description_exists
    app = Jojo::Application.new("test-application")
    FileUtils.mkdir_p(app.base_path)
    File.write(app.job_description_path, "test content")

    assert app.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_details_exists
    app = Jojo::Application.new("test-application")
    FileUtils.mkdir_p(app.base_path)
    File.write(app.job_details_path, "company_name: Test\n")

    assert app.artifacts_exist?
  end
end
