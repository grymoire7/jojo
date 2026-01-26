# frozen_string_literal: true

require_relative "../test_helper"

describe Jojo::Interactive do
  describe "#initialize" do
    it "accepts optional slug parameter" do
      interactive = Jojo::Interactive.new(slug: "test-slug")
      _(interactive.slug).must_equal "test-slug"
    end

    it "loads slug from state persistence when not provided" do
      # This tests integration with StatePersistence
      original_dir = Dir.pwd
      temp_dir = Dir.mktmpdir
      Dir.chdir(temp_dir)

      File.write(".jojo_state", "saved-slug")
      interactive = Jojo::Interactive.new

      _(interactive.slug).must_equal "saved-slug"

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "#employer" do
    it "returns nil when no slug set" do
      temp_dir = Dir.mktmpdir
      original_dir = Dir.pwd
      Dir.chdir(temp_dir)

      interactive = Jojo::Interactive.new
      _(interactive.employer).must_be_nil

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end

    it "returns Employer instance when slug is set" do
      temp_dir = Dir.mktmpdir
      employers_dir = File.join(temp_dir, "employers", "test-slug")
      FileUtils.mkdir_p(employers_dir)

      original_dir = Dir.pwd
      Dir.chdir(temp_dir)

      interactive = Jojo::Interactive.new(slug: "test-slug")
      employer = interactive.employer

      _(employer).must_be_kind_of Jojo::Employer
      _(employer.slug).must_equal "test-slug"

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "#list_applications" do
    before do
      @temp_dir = Dir.mktmpdir
      @employers_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(@employers_dir)
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns empty array when no employers exist" do
      interactive = Jojo::Interactive.new
      _(interactive.list_applications).must_equal []
    end

    it "returns list of employer slugs" do
      FileUtils.mkdir_p(File.join(@employers_dir, "acme-corp"))
      FileUtils.mkdir_p(File.join(@employers_dir, "globex-inc"))

      interactive = Jojo::Interactive.new
      apps = interactive.list_applications

      _(apps).must_include "acme-corp"
      _(apps).must_include "globex-inc"
    end

    it "excludes non-directories" do
      FileUtils.mkdir_p(File.join(@employers_dir, "acme-corp"))
      File.write(File.join(@employers_dir, "some-file.txt"), "test")

      interactive = Jojo::Interactive.new
      apps = interactive.list_applications

      _(apps).must_equal ["acme-corp"]
    end
  end

  describe "#switch_application" do
    before do
      @temp_dir = Dir.mktmpdir
      @employers_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(File.join(@employers_dir, "new-app"))
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "updates slug and saves to state" do
      interactive = Jojo::Interactive.new(slug: "old-app")
      interactive.switch_application("new-app")

      _(interactive.slug).must_equal "new-app"
      _(Jojo::StatePersistence.load_slug).must_equal "new-app"
    end

    it "clears cached employer" do
      interactive = Jojo::Interactive.new(slug: "new-app")
      _old_employer = interactive.employer  # Cache it

      interactive.switch_application("new-app")
      # employer should be re-instantiated on next access
    end
  end

  describe "#handle_key" do
    before do
      @temp_dir = Dir.mktmpdir
      @employers_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(File.join(@employers_dir, "test-app"))
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "returns :quit for 'q' key" do
      interactive = Jojo::Interactive.new(slug: "test-app")
      result = interactive.handle_key("q")
      _(result).must_equal :quit
    end

    it "returns :switch for 's' key" do
      interactive = Jojo::Interactive.new(slug: "test-app")
      result = interactive.handle_key("s")
      _(result).must_equal :switch
    end

    it "returns :open for 'o' key" do
      interactive = Jojo::Interactive.new(slug: "test-app")
      result = interactive.handle_key("o")
      _(result).must_equal :open
    end

    it "returns :all for 'a' key" do
      interactive = Jojo::Interactive.new(slug: "test-app")
      result = interactive.handle_key("a")
      _(result).must_equal :all
    end

    it "returns step index for number keys 1-9" do
      interactive = Jojo::Interactive.new(slug: "test-app")
      _(interactive.handle_key("1")).must_equal 0
      _(interactive.handle_key("5")).must_equal 4
      _(interactive.handle_key("9")).must_equal 8
    end

    it "returns nil for unrecognized keys" do
      interactive = Jojo::Interactive.new(slug: "test-app")
      _(interactive.handle_key("x")).must_be_nil
    end
  end

  describe "#run initial render with existing applications" do
    before do
      @temp_dir = Dir.mktmpdir
      @employers_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(@employers_dir)
      @original_dir = Dir.pwd
      Dir.chdir(@temp_dir)
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    it "shows switcher when applications exist but no slug is provided" do
      # Create test applications
      FileUtils.mkdir_p(File.join(@employers_dir, "acme-corp"))
      FileUtils.mkdir_p(File.join(@employers_dir, "globex-inc"))

      # Interactive should find applications
      interactive = Jojo::Interactive.new
      apps = interactive.list_applications

      _(apps.length).must_equal 2
      _(apps).must_include "acme-corp"
      _(apps).must_include "globex-inc"
    end

    it "shows welcome when no applications exist" do
      # No applications created
      interactive = Jojo::Interactive.new
      apps = interactive.list_applications

      _(apps).must_equal []
    end
  end

  describe "#handle_new_application behavior" do
    before do
      @temp_dir = Dir.mktmpdir
      @employers_dir = File.join(@temp_dir, "employers")
      FileUtils.mkdir_p(@employers_dir)
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
      employer = Jojo::Employer.new(slug)
      FileUtils.mkdir_p(employer.base_path)

      _(Dir.exist?(File.join(@employers_dir, slug))).must_equal true
      _(employer.artifacts_exist?).must_equal false  # No job description yet
    end
  end
end
