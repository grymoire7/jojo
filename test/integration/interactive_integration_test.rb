# frozen_string_literal: true

require_relative "../test_helper"

class InteractiveIntegrationTest < JojoTest
  def setup
    super
    @applications_dir = File.join(@tmpdir, "applications")
  end

  def test_shows_welcome_screen_with_no_applications
    runner = Jojo::Commands::Interactive::Runner.new
    _(runner.application).must_be_nil
    _(runner.list_applications).must_be_empty
  end

  def test_loads_application_state
    setup_existing_application
    Jojo::StatePersistence.save_slug(@slug)

    runner = Jojo::Commands::Interactive::Runner.new
    _(runner.slug).must_equal @slug
    _(runner.application).wont_be_nil
    _(runner.application.company_name).must_equal "Test Company"
  end

  def test_computes_workflow_status_correctly
    setup_existing_application

    runner = Jojo::Commands::Interactive::Runner.new(slug: @slug)
    employer = runner.application

    statuses = Jojo::Commands::Interactive::Workflow.all_statuses(employer)

    _(statuses[:job_description]).must_equal :generated
    _(statuses[:research]).must_equal :ready  # dependency met
    _(statuses[:resume]).must_equal :blocked  # needs research
  end

  def test_detects_when_resume_is_up_to_date
    setup_staleness_detection

    runner = Jojo::Commands::Interactive::Runner.new(slug: @slug)
    status = Jojo::Commands::Interactive::Workflow.status(:resume, runner.application)
    _(status).must_equal :generated
  end

  def test_detects_when_resume_becomes_stale
    setup_staleness_detection

    # Touch job_description to make it newer
    sleep 0.01
    app_dir = File.join(@applications_dir, @slug)
    FileUtils.touch(File.join(app_dir, "job_description.md"))

    runner = Jojo::Commands::Interactive::Runner.new(slug: @slug)
    status = Jojo::Commands::Interactive::Workflow.status(:resume, runner.application)
    _(status).must_equal :stale
  end

  def test_lists_all_available_applications
    setup_multiple_applications

    runner = Jojo::Commands::Interactive::Runner.new
    apps = runner.list_applications

    _(apps.length).must_equal 2
    _(apps).must_include @app1
    _(apps).must_include @app2
  end

  def test_has_no_current_employer_when_slug_not_provided
    setup_multiple_applications

    runner = Jojo::Commands::Interactive::Runner.new
    _(runner.application).must_be_nil
    _(runner.slug).must_be_nil
  end

  def test_can_switch_between_applications
    setup_multiple_applications

    runner = Jojo::Commands::Interactive::Runner.new

    # Switch to first app
    runner.switch_application(@app1)
    _(runner.slug).must_equal @app1
    _(runner.application.slug).must_equal @app1

    # Switch to second app
    runner.switch_application(@app2)
    _(runner.slug).must_equal @app2
    _(runner.application.slug).must_equal @app2
  end

  def test_persists_slug_selection_across_runner_instances
    setup_multiple_applications

    runner1 = Jojo::Commands::Interactive::Runner.new
    runner1.switch_application(@app1)

    # Create new instance - should load saved slug
    runner2 = Jojo::Commands::Interactive::Runner.new
    _(runner2.slug).must_equal @app1
  end

  private

  def setup_existing_application
    @slug = "test-company-dev"
    app_dir = File.join(@applications_dir, @slug)
    FileUtils.mkdir_p(app_dir)
    File.write(File.join(app_dir, "job_description.md"), "Test job")
    File.write(File.join(app_dir, "job_details.yml"), "company_name: Test Company\njob_title: Developer")
  end

  def setup_staleness_detection
    @slug = "stale-test"
    app_dir = File.join(@applications_dir, @slug)
    FileUtils.mkdir_p(app_dir)

    # Create job_description first
    File.write(File.join(app_dir, "job_description.md"), "Job")
    sleep 0.01

    # Create research
    File.write(File.join(app_dir, "research.md"), "Research")
    sleep 0.01

    # Create resume
    File.write(File.join(app_dir, "resume.md"), "Resume")
  end

  def setup_multiple_applications
    @app1 = "acme-corp"
    @app2 = "globex-inc"

    [@app1, @app2].each do |slug|
      app_dir = File.join(@applications_dir, slug)
      FileUtils.mkdir_p(app_dir)
      File.write(File.join(app_dir, "job_description.md"), "Job for #{slug}")
      File.write(File.join(app_dir, "job_details.yml"), "company_name: #{slug}\njob_title: Developer")
    end
  end
end
