# frozen_string_literal: true

require_relative "../../../test_helper"

class Jojo::Commands::Interactive::RunnerTest < JojoTest
  # #initialize

  def test_accepts_optional_slug_parameter
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-slug")
    _(runner.slug).must_equal "test-slug"
  end

  def test_loads_slug_from_state_persistence_when_not_provided
    File.write(".jojo_state", "saved-slug")
    runner = Jojo::Commands::Interactive::Runner.new

    _(runner.slug).must_equal "saved-slug"
  end

  # #application

  def test_application_returns_nil_when_no_slug_set
    runner = Jojo::Commands::Interactive::Runner.new
    _(runner.application).must_be_nil
  end

  def test_application_returns_application_instance_when_slug_is_set
    FileUtils.mkdir_p("applications/test-slug")

    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-slug")
    application = runner.application

    _(application).must_be_kind_of Jojo::Application
    _(application.slug).must_equal "test-slug"
  end

  # #list_applications

  def test_list_applications_returns_empty_array_when_no_applications_exist
    FileUtils.mkdir_p("applications")

    runner = Jojo::Commands::Interactive::Runner.new
    _(runner.list_applications).must_equal []
  end

  def test_list_applications_returns_list_of_application_slugs
    FileUtils.mkdir_p("applications/acme-corp")
    FileUtils.mkdir_p("applications/globex-inc")

    runner = Jojo::Commands::Interactive::Runner.new
    apps = runner.list_applications

    _(apps).must_include "acme-corp"
    _(apps).must_include "globex-inc"
  end

  def test_list_applications_excludes_non_directories
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/some-file.txt", "test")

    runner = Jojo::Commands::Interactive::Runner.new
    apps = runner.list_applications

    _(apps).must_equal ["acme-corp"]
  end

  # #switch_application

  def test_switch_application_updates_slug_and_saves_to_state
    FileUtils.mkdir_p("applications/new-app")

    runner = Jojo::Commands::Interactive::Runner.new(slug: "old-app")
    runner.switch_application("new-app")

    _(runner.slug).must_equal "new-app"
    _(Jojo::StatePersistence.load_slug).must_equal "new-app"
  end

  def test_switch_application_clears_cached_application
    FileUtils.mkdir_p("applications/new-app")

    runner = Jojo::Commands::Interactive::Runner.new(slug: "new-app")
    _old_application = runner.application  # Cache it

    runner.switch_application("new-app")
    # application should be re-instantiated on next access
  end

  # #handle_key

  def test_handle_key_returns_quit_for_q_key
    setup_test_app
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
    result = runner.handle_key("q")
    _(result).must_equal :quit
  end

  def test_handle_key_returns_switch_for_s_key
    setup_test_app
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
    result = runner.handle_key("s")
    _(result).must_equal :switch
  end

  def test_handle_key_returns_open_for_o_key
    setup_test_app
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
    result = runner.handle_key("o")
    _(result).must_equal :open
  end

  def test_handle_key_returns_all_for_a_key
    setup_test_app
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
    result = runner.handle_key("a")
    _(result).must_equal :all
  end

  def test_handle_key_returns_step_index_for_number_keys
    setup_test_app
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
    _(runner.handle_key("1")).must_equal 0
    _(runner.handle_key("5")).must_equal 4
    _(runner.handle_key("9")).must_equal 8
  end

  def test_handle_key_returns_nil_for_unrecognized_keys
    setup_test_app
    runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
    _(runner.handle_key("x")).must_be_nil
  end

  # #run initial render with existing applications

  def test_shows_switcher_when_applications_exist_but_no_slug_provided
    FileUtils.mkdir_p("applications/acme-corp")
    FileUtils.mkdir_p("applications/globex-inc")

    runner = Jojo::Commands::Interactive::Runner.new
    apps = runner.list_applications

    _(apps.length).must_equal 2
    _(apps).must_include "acme-corp"
    _(apps).must_include "globex-inc"
  end

  def test_shows_welcome_when_no_applications_exist
    FileUtils.mkdir_p("applications")

    runner = Jojo::Commands::Interactive::Runner.new
    apps = runner.list_applications

    _(apps).must_equal []
  end

  # #handle_new_application behavior

  def test_creates_application_directory_without_job_description
    FileUtils.mkdir_p("applications")
    File.write("config.yml", "seeker:\n  name: Test\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test\n")

    slug = "test-new-app"
    app = Jojo::Application.new(slug)
    FileUtils.mkdir_p(app.base_path)

    _(Dir.exist?(File.join("applications", slug))).must_equal true
    _(app.artifacts_exist?).must_equal false
  end

  # #handle_step_selection for job_description

  def test_shows_ready_status_when_job_description_is_missing
    slug = "no-job-desc"
    FileUtils.mkdir_p("applications/#{slug}")
    File.write("config.yml", "seeker:\n  name: Test\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test\n")

    runner = Jojo::Commands::Interactive::Runner.new(slug: slug)
    status = Jojo::Commands::Interactive::Workflow.status(:job_description, runner.application)

    _(status).must_equal :ready
  end

  private

  def setup_test_app
    FileUtils.mkdir_p("applications/test-app")
  end
end
