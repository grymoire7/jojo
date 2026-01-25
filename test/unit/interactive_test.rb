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
      interactive = Jojo::Interactive.new
      _(interactive.employer).must_be_nil
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
end
