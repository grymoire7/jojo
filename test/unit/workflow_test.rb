# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

describe Jojo::Workflow do
  describe "STEPS" do
    it "defines all workflow steps in order" do
      steps = Jojo::Workflow::STEPS

      _(steps).must_be_kind_of Array
      _(steps.length).must_equal 9
      _(steps.first[:key]).must_equal :job_description
      _(steps.last[:key]).must_equal :pdf
    end

    it "includes required fields for each step" do
      Jojo::Workflow::STEPS.each do |step|
        _(step).must_include :key
        _(step).must_include :label
        _(step).must_include :dependencies
        _(step).must_include :command
        _(step).must_include :paid
        _(step).must_include :output_file
      end
    end
  end

  describe ".file_path" do
    before do
      @employer = Minitest::Mock.new
      @employer.expect :base_path, "/tmp/test-employer"
    end

    it "returns full path for a step" do
      path = Jojo::Workflow.file_path(:resume, @employer)
      _(path).must_equal "/tmp/test-employer/resume.md"
    end

    it "handles nested paths like website" do
      @employer.expect :base_path, "/tmp/test-employer"
      path = Jojo::Workflow.file_path(:website, @employer)
      _(path).must_equal "/tmp/test-employer/website/index.html"
    end

    it "raises for unknown step" do
      _ { Jojo::Workflow.file_path(:unknown, @employer) }.must_raise ArgumentError
    end
  end

  describe ".status" do
    before do
      @temp_dir = Dir.mktmpdir
      @employer = Minitest::Mock.new
      @employer.expect :base_path, @temp_dir
    end

    after do
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns :blocked when dependencies missing" do
      # No files exist
      # file_path called for: output + first dependency (fails, returns early)
      @employer.expect :base_path, @temp_dir

      status = Jojo::Workflow.status(:resume, @employer)
      _(status).must_equal :blocked
    end

    it "returns :ready when dependencies exist but output missing" do
      # Create dependencies for resume: job_description and research
      FileUtils.touch(File.join(@temp_dir, "job_description.md"))
      FileUtils.touch(File.join(@temp_dir, "research.md"))

      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir

      status = Jojo::Workflow.status(:resume, @employer)
      _(status).must_equal :ready
    end

    it "returns :generated when output exists and up-to-date" do
      # Create dependencies older than output
      FileUtils.touch(File.join(@temp_dir, "job_description.md"))
      FileUtils.touch(File.join(@temp_dir, "research.md"))
      sleep 0.01
      FileUtils.touch(File.join(@temp_dir, "resume.md"))

      # file_path called for: output, 2 deps check, 2 deps staleness check = 5 total
      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir

      status = Jojo::Workflow.status(:resume, @employer)
      _(status).must_equal :generated
    end

    it "returns :stale when dependency is newer than output" do
      # Create output first
      FileUtils.touch(File.join(@temp_dir, "resume.md"))
      sleep 0.01
      # Then create newer dependencies
      FileUtils.touch(File.join(@temp_dir, "job_description.md"))
      FileUtils.touch(File.join(@temp_dir, "research.md"))

      # file_path called for: output, 2 deps check, 1 dep staleness (stale found) = 4 total
      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir
      @employer.expect :base_path, @temp_dir

      status = Jojo::Workflow.status(:resume, @employer)
      _(status).must_equal :stale
    end

    it "returns :ready for job_description (no dependencies)" do
      status = Jojo::Workflow.status(:job_description, @employer)
      _(status).must_equal :ready
    end
  end

  describe ".all_statuses" do
    before do
      @temp_dir = Dir.mktmpdir
      @employer = Minitest::Mock.new
    end

    after do
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns status for all steps" do
      # Mock base_path for each status call (9 steps, each may call multiple times)
      27.times { @employer.expect :base_path, @temp_dir }

      statuses = Jojo::Workflow.all_statuses(@employer)

      _(statuses).must_be_kind_of Hash
      _(statuses.keys.length).must_equal 9
      _(statuses[:job_description]).must_equal :ready
      _(statuses[:resume]).must_equal :blocked
    end
  end

  describe ".missing_dependencies" do
    before do
      @temp_dir = Dir.mktmpdir
      @employer = Minitest::Mock.new
    end

    after do
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns list of missing dependency labels" do
      5.times { @employer.expect :base_path, @temp_dir }

      missing = Jojo::Workflow.missing_dependencies(:resume, @employer)

      _(missing).must_include "Job Description"
      _(missing).must_include "Research"
    end

    it "returns empty array when all deps met" do
      FileUtils.touch(File.join(@temp_dir, "job_description.md"))
      FileUtils.touch(File.join(@temp_dir, "research.md"))

      5.times { @employer.expect :base_path, @temp_dir }

      missing = Jojo::Workflow.missing_dependencies(:resume, @employer)
      _(missing).must_be_empty
    end
  end

  describe ".progress" do
    before do
      @temp_dir = Dir.mktmpdir
      @employer = Minitest::Mock.new
    end

    after do
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns 0 when nothing generated" do
      27.times { @employer.expect :base_path, @temp_dir }

      progress = Jojo::Workflow.progress(@employer)
      _(progress).must_equal 0
    end

    it "returns percentage of generated (non-stale) items" do
      # Create job_description (1 of 9 = ~11%)
      FileUtils.touch(File.join(@temp_dir, "job_description.md"))

      27.times { @employer.expect :base_path, @temp_dir }

      progress = Jojo::Workflow.progress(@employer)
      _(progress).must_equal 11  # 1/9 rounded
    end
  end
end
