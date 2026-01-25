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
end
