# frozen_string_literal: true

require_relative "../test_helper"

describe Jojo::StatePersistence do
  before do
    @temp_dir = Dir.mktmpdir
    @state_file = File.join(@temp_dir, ".jojo_state")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe ".save_slug" do
    it "saves slug to .jojo_state file" do
      Jojo::StatePersistence.save_slug("acme-corp-dev")

      _(File.exist?(@state_file)).must_equal true
      _(File.read(@state_file).strip).must_equal "acme-corp-dev"
    end
  end

  describe ".load_slug" do
    it "returns nil when no state file exists" do
      slug = Jojo::StatePersistence.load_slug
      _(slug).must_be_nil
    end

    it "returns saved slug when state file exists" do
      File.write(@state_file, "acme-corp-dev")

      slug = Jojo::StatePersistence.load_slug
      _(slug).must_equal "acme-corp-dev"
    end

    it "strips whitespace from saved slug" do
      File.write(@state_file, "  acme-corp-dev  \n")

      slug = Jojo::StatePersistence.load_slug
      _(slug).must_equal "acme-corp-dev"
    end
  end

  describe ".clear" do
    it "removes the state file" do
      File.write(@state_file, "acme-corp-dev")

      Jojo::StatePersistence.clear

      _(File.exist?(@state_file)).must_equal false
    end

    it "does nothing if no state file exists" do
      Jojo::StatePersistence.clear  # Should not raise
    end
  end
end
