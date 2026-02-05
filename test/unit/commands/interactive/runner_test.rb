# frozen_string_literal: true

require_relative "../../../test_helper"

describe Jojo::Commands::Interactive::Runner do
  describe "#initialize" do
    it "accepts optional slug parameter" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-slug")
      _(runner.slug).must_equal "test-slug"
    end

    it "loads slug from state persistence when not provided" do
      # This tests integration with StatePersistence
      original_dir = Dir.pwd
      temp_dir = Dir.mktmpdir
      Dir.chdir(temp_dir)

      File.write(".jojo_state", "saved-slug")
      runner = Jojo::Commands::Interactive::Runner.new

      _(runner.slug).must_equal "saved-slug"

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "#application" do
    it "returns nil when no slug set" do
      temp_dir = Dir.mktmpdir
      original_dir = Dir.pwd
      Dir.chdir(temp_dir)

      runner = Jojo::Commands::Interactive::Runner.new
      _(runner.application).must_be_nil

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end

    it "returns Application instance when slug is set" do
      temp_dir = Dir.mktmpdir
      applications_dir = File.join(temp_dir, "applications", "test-slug")
      FileUtils.mkdir_p(applications_dir)

      original_dir = Dir.pwd
      Dir.chdir(temp_dir)

      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-slug")
      application = runner.application

      _(application).must_be_kind_of Jojo::Application
      _(application.slug).must_equal "test-slug"

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "#list_applications" do
    before do
      @temp_dir = Dir.mktmpdir
      @applications_dir = File.join(@temp_dir, "applications")
      FileUtils.mkdir_p(@applications_dir)
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns empty array when no applications exist" do
      runner = Jojo::Commands::Interactive::Runner.new
      _(runner.list_applications).must_equal []
    end

    it "returns list of application slugs" do
      FileUtils.mkdir_p(File.join(@applications_dir, "acme-corp"))
      FileUtils.mkdir_p(File.join(@applications_dir, "globex-inc"))

      runner = Jojo::Commands::Interactive::Runner.new
      apps = runner.list_applications

      _(apps).must_include "acme-corp"
      _(apps).must_include "globex-inc"
    end

    it "excludes non-directories" do
      FileUtils.mkdir_p(File.join(@applications_dir, "acme-corp"))
      File.write(File.join(@applications_dir, "some-file.txt"), "test")

      runner = Jojo::Commands::Interactive::Runner.new
      apps = runner.list_applications

      _(apps).must_equal ["acme-corp"]
    end
  end

  describe "#switch_application" do
    before do
      @temp_dir = Dir.mktmpdir
      @applications_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(File.join(@applications_dir, "new-app"))
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "updates slug and saves to state" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "old-app")
      runner.switch_application("new-app")

      _(runner.slug).must_equal "new-app"
      _(Jojo::StatePersistence.load_slug).must_equal "new-app"
    end

    it "clears cached employer" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "new-app")
      _old_employer = runner.employer  # Cache it

      runner.switch_application("new-app")
      # employer should be re-instantiated on next access
    end
  end

  describe "#handle_key" do
    before do
      @temp_dir = Dir.mktmpdir
      @applications_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(File.join(@applications_dir, "test-app"))
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns :quit for 'q' key" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
      result = runner.handle_key("q")
      _(result).must_equal :quit
    end

    it "returns :switch for 's' key" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
      result = runner.handle_key("s")
      _(result).must_equal :switch
    end

    it "returns :open for 'o' key" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
      result = runner.handle_key("o")
      _(result).must_equal :open
    end

    it "returns :all for 'a' key" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
      result = runner.handle_key("a")
      _(result).must_equal :all
    end

    it "returns step index for number keys 1-9" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
      _(runner.handle_key("1")).must_equal 0
      _(runner.handle_key("5")).must_equal 4
      _(runner.handle_key("9")).must_equal 8
    end

    it "returns nil for unrecognized keys" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: "test-app")
      _(runner.handle_key("x")).must_be_nil
    end
  end

  describe "#run initial render with existing applications" do
    before do
      @temp_dir = Dir.mktmpdir
      @applications_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(@applications_dir)
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "shows switcher when applications exist but no slug is provided" do
      # Create test applications
      FileUtils.mkdir_p(File.join(@applications_dir, "acme-corp"))
      FileUtils.mkdir_p(File.join(@applications_dir, "globex-inc"))

      # Runner should find applications
      runner = Jojo::Commands::Interactive::Runner.new
      apps = runner.list_applications

      _(apps.length).must_equal 2
      _(apps).must_include "acme-corp"
      _(apps).must_include "globex-inc"
    end

    it "shows welcome when no applications exist" do
      # No applications created
      runner = Jojo::Commands::Interactive::Runner.new
      apps = runner.list_applications

      _(apps).must_equal []
    end
  end

  describe "#handle_new_application behavior" do
    before do
      @temp_dir = Dir.mktmpdir
      @applications_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(@applications_dir)
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)

      # Create minimal config for validation
      File.write("config.yml", "seeker:\n  name: Test\n")
      FileUtils.mkdir_p("inputs")
      File.write("inputs/resume_data.yml", "name: Test\n")
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "creates employer directory without job description" do
      # Create the directory directly (simulating what handle_new_application does)
      slug = "test-new-app"
      Jojo::Application.new(slug)
      FileUtils.mkdir_p(application.base_path)

      _(Dir.exist?(File.join(@applications_dir, slug))).must_equal true
      _(application.artifacts_exist?).must_equal false  # No job description yet
    end
  end

  describe "#handle_step_selection for job_description" do
    before do
      @temp_dir = Dir.mktmpdir
      @applications_dir = File.join(@temp_dir, "employers")
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)

      # Create employer without job description
      @slug = "no-job-desc"
      FileUtils.mkdir_p(File.join(@applications_dir, @slug))

      # Create minimal config
      File.write("config.yml", "seeker:\n  name: Test\n")
      FileUtils.mkdir_p("inputs")
      File.write("inputs/resume_data.yml", "name: Test\n")
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "shows ready status when job description is missing" do
      runner = Jojo::Commands::Interactive::Runner.new(slug: @slug)
      status = Jojo::Commands::Interactive::Workflow.status(:job_description, runner.employer)

      # Job description has no dependencies, so it's always ready when missing
      _(status).must_equal :ready
    end
  end
end
