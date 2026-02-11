# frozen_string_literal: true

require_relative "../../../test_helper"
require "tmpdir"
require "fileutils"

class Jojo::Commands::Interactive::WorkflowTest < JojoTest
  # STEPS

  def test_defines_all_workflow_steps_in_order
    steps = Jojo::Commands::Interactive::Workflow::STEPS

    _(steps).must_be_kind_of Array
    _(steps.length).must_equal 9
    _(steps.first[:key]).must_equal :job_description
    _(steps.last[:key]).must_equal :pdf
  end

  def test_includes_required_fields_for_each_step
    Jojo::Commands::Interactive::Workflow::STEPS.each do |step|
      _(step).must_include :key
      _(step).must_include :label
      _(step).must_include :dependencies
      _(step).must_include :command
      _(step).must_include :paid
      _(step).must_include :output_file
    end
  end

  # .file_path

  def test_file_path_returns_full_path_for_a_step
    application = Minitest::Mock.new
    application.expect :base_path, "/tmp/test-employer"

    path = Jojo::Commands::Interactive::Workflow.file_path(:resume, application)
    _(path).must_equal "/tmp/test-employer/resume.md"
  end

  def test_file_path_handles_nested_paths_like_website
    application = Minitest::Mock.new
    application.expect :base_path, "/tmp/test-employer"
    application.expect :base_path, "/tmp/test-employer"

    path = Jojo::Commands::Interactive::Workflow.file_path(:website, application)
    _(path).must_equal "/tmp/test-employer/website/index.html"
  end

  def test_file_path_raises_for_unknown_step
    application = Minitest::Mock.new
    _ { Jojo::Commands::Interactive::Workflow.file_path(:unknown, application) }.must_raise ArgumentError
  end

  # .status

  def test_status_returns_blocked_when_dependencies_missing
    application = build_status_application

    # No files exist
    # file_path called for: output + first dependency (fails, returns early)
    application.expect :base_path, @tmpdir

    status = Jojo::Commands::Interactive::Workflow.status(:resume, application)
    _(status).must_equal :blocked
  end

  def test_status_returns_ready_when_dependencies_exist_but_output_missing
    application = build_status_application

    # Create dependencies for resume: job_description and research
    FileUtils.touch(File.join(@tmpdir, "job_description.md"))
    FileUtils.touch(File.join(@tmpdir, "research.md"))

    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir

    status = Jojo::Commands::Interactive::Workflow.status(:resume, application)
    _(status).must_equal :ready
  end

  def test_status_returns_generated_when_output_exists_and_up_to_date
    application = build_status_application

    # Create dependencies older than output
    FileUtils.touch(File.join(@tmpdir, "job_description.md"))
    FileUtils.touch(File.join(@tmpdir, "research.md"))
    sleep 0.01
    FileUtils.touch(File.join(@tmpdir, "resume.md"))

    # file_path called for: output, 2 deps check, 2 deps staleness check = 5 total
    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir

    status = Jojo::Commands::Interactive::Workflow.status(:resume, application)
    _(status).must_equal :generated
  end

  def test_status_returns_stale_when_dependency_is_newer_than_output
    application = build_status_application

    # Create output first
    FileUtils.touch(File.join(@tmpdir, "resume.md"))
    sleep 0.01
    # Then create newer dependencies
    FileUtils.touch(File.join(@tmpdir, "job_description.md"))
    FileUtils.touch(File.join(@tmpdir, "research.md"))

    # file_path called for: output, 2 deps check, 1 dep staleness (stale found) = 4 total
    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir
    application.expect :base_path, @tmpdir

    status = Jojo::Commands::Interactive::Workflow.status(:resume, application)
    _(status).must_equal :stale
  end

  def test_status_returns_ready_for_job_description_with_no_dependencies
    application = Minitest::Mock.new
    application.expect :base_path, @tmpdir

    status = Jojo::Commands::Interactive::Workflow.status(:job_description, application)
    _(status).must_equal :ready
  end

  # .all_statuses

  def test_all_statuses_returns_status_for_all_steps
    application = Minitest::Mock.new
    # Mock base_path for each status call (9 steps, each may call multiple times)
    27.times { application.expect :base_path, @tmpdir }

    statuses = Jojo::Commands::Interactive::Workflow.all_statuses(application)

    _(statuses).must_be_kind_of Hash
    _(statuses.keys.length).must_equal 9
    _(statuses[:job_description]).must_equal :ready
    _(statuses[:resume]).must_equal :blocked
  end

  # .missing_dependencies

  def test_missing_dependencies_returns_list_of_missing_dependency_labels
    application = Minitest::Mock.new
    5.times { application.expect :base_path, @tmpdir }

    missing = Jojo::Commands::Interactive::Workflow.missing_dependencies(:resume, application)

    _(missing).must_include "Job Description"
    _(missing).must_include "Research"
  end

  def test_missing_dependencies_returns_empty_array_when_all_deps_met
    application = Minitest::Mock.new

    FileUtils.touch(File.join(@tmpdir, "job_description.md"))
    FileUtils.touch(File.join(@tmpdir, "research.md"))

    5.times { application.expect :base_path, @tmpdir }

    missing = Jojo::Commands::Interactive::Workflow.missing_dependencies(:resume, application)
    _(missing).must_be_empty
  end

  # .progress

  def test_progress_returns_zero_when_nothing_generated
    application = Minitest::Mock.new
    27.times { application.expect :base_path, @tmpdir }

    progress = Jojo::Commands::Interactive::Workflow.progress(application)
    _(progress).must_equal 0
  end

  def test_progress_returns_percentage_of_generated_non_stale_items
    application = Minitest::Mock.new

    # Create job_description (1 of 9 = ~11%)
    FileUtils.touch(File.join(@tmpdir, "job_description.md"))

    27.times { application.expect :base_path, @tmpdir }

    progress = Jojo::Commands::Interactive::Workflow.progress(application)
    _(progress).must_equal 11  # 1/9 rounded
  end

  private

  def build_status_application
    application = Minitest::Mock.new
    application.expect :base_path, @tmpdir
    application
  end
end
