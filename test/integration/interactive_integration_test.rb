# frozen_string_literal: true

require_relative "../test_helper"

describe "Interactive Mode Integration" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe "with no applications" do
    it "shows welcome screen" do
      interactive = Jojo::Interactive.new
      _(interactive.employer).must_be_nil
      _(interactive.list_applications).must_be_empty
    end
  end

  describe "with existing application" do
    before do
      @slug = "test-company-dev"
      app_dir = File.join(@employers_dir, @slug)
      FileUtils.mkdir_p(app_dir)
      File.write(File.join(app_dir, "job_description.md"), "Test job")
      File.write(File.join(app_dir, "job_details.yml"), "company_name: Test Company\njob_title: Developer")
    end

    it "loads application state" do
      Jojo::StatePersistence.save_slug(@slug)

      interactive = Jojo::Interactive.new
      _(interactive.slug).must_equal @slug
      _(interactive.employer).wont_be_nil
      _(interactive.employer.company_name).must_equal "Test Company"
    end

    it "computes workflow status correctly" do
      interactive = Jojo::Interactive.new(slug: @slug)
      employer = interactive.employer

      statuses = Jojo::Workflow.all_statuses(employer)

      _(statuses[:job_description]).must_equal :generated
      _(statuses[:research]).must_equal :ready  # dependency met
      _(statuses[:resume]).must_equal :blocked  # needs research
    end
  end

  describe "staleness detection" do
    before do
      @slug = "stale-test"
      app_dir = File.join(@employers_dir, @slug)
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

    it "detects when resume is up-to-date" do
      interactive = Jojo::Interactive.new(slug: @slug)
      status = Jojo::Workflow.status(:resume, interactive.employer)
      _(status).must_equal :generated
    end

    it "detects when resume becomes stale" do
      # Touch job_description to make it newer
      sleep 0.01
      app_dir = File.join(@employers_dir, @slug)
      FileUtils.touch(File.join(app_dir, "job_description.md"))

      interactive = Jojo::Interactive.new(slug: @slug)
      status = Jojo::Workflow.status(:resume, interactive.employer)
      _(status).must_equal :stale
    end
  end

  describe "with multiple applications but no employer selected" do
    before do
      # Create multiple applications
      @app1 = "acme-corp"
      @app2 = "globex-inc"

      [@app1, @app2].each do |slug|
        app_dir = File.join(@employers_dir, slug)
        FileUtils.mkdir_p(app_dir)
        File.write(File.join(app_dir, "job_description.md"), "Job for #{slug}")
        File.write(File.join(app_dir, "job_details.yml"), "company_name: #{slug}\njob_title: Developer")
      end
    end

    it "lists all available applications" do
      interactive = Jojo::Interactive.new
      apps = interactive.list_applications

      _(apps.length).must_equal 2
      _(apps).must_include @app1
      _(apps).must_include @app2
    end

    it "has no current employer when slug not provided" do
      interactive = Jojo::Interactive.new
      _(interactive.employer).must_be_nil
      _(interactive.slug).must_be_nil
    end

    it "can switch between applications" do
      interactive = Jojo::Interactive.new

      # Switch to first app
      interactive.switch_application(@app1)
      _(interactive.slug).must_equal @app1
      _(interactive.employer.slug).must_equal @app1

      # Switch to second app
      interactive.switch_application(@app2)
      _(interactive.slug).must_equal @app2
      _(interactive.employer.slug).must_equal @app2
    end

    it "persists slug selection across Interactive instances" do
      interactive1 = Jojo::Interactive.new
      interactive1.switch_application(@app1)

      # Create new instance - should load saved slug
      interactive2 = Jojo::Interactive.new
      _(interactive2.slug).must_equal @app1
    end
  end
end
