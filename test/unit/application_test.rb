# frozen_string_literal: true

require "test_helper"
require "jojo/application"

describe Jojo::Application do
  describe "#initialize" do
    it "sets slug and base_path" do
      app = Jojo::Application.new("acme-corp")

      _(app.slug).must_equal "acme-corp"
      _(app.base_path).must_equal "applications/acme-corp"
    end
  end

  describe "path accessors" do
    let(:app) { Jojo::Application.new("test-app") }

    it "returns job_description_raw_path" do
      _(app.job_description_raw_path).must_equal "applications/test-app/job_description_raw.md"
    end

    it "returns job_description_path" do
      _(app.job_description_path).must_equal "applications/test-app/job_description.md"
    end

    it "returns job_details_path" do
      _(app.job_details_path).must_equal "applications/test-app/job_details.yml"
    end

    it "returns resume_path" do
      _(app.resume_path).must_equal "applications/test-app/resume.md"
    end

    it "returns cover_letter_path" do
      _(app.cover_letter_path).must_equal "applications/test-app/cover_letter.md"
    end

    it "returns research_path" do
      _(app.research_path).must_equal "applications/test-app/research.md"
    end

    it "returns website_path" do
      _(app.website_path).must_equal "applications/test-app/website"
    end

    it "returns faq_path" do
      _(app.faq_path).must_equal "applications/test-app/faq.json"
    end
  end

  describe "#company_name" do
    it "returns slug when job_details.yml does not exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          app = Jojo::Application.new("acme-corp")
          _(app.company_name).must_equal "acme-corp"
        end
      end
    end

    it "returns company_name from job_details.yml when it exists" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("applications/acme-corp")
          File.write("applications/acme-corp/job_details.yml", "company_name: Acme Corporation")

          app = Jojo::Application.new("acme-corp")
          _(app.company_name).must_equal "Acme Corporation"
        end
      end
    end
  end

  describe "#artifacts_exist?" do
    it "returns false when no artifacts exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          app = Jojo::Application.new("new-app")
          _(app.artifacts_exist?).must_equal false
        end
      end
    end

    it "returns true when job_description.md exists" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("applications/existing-app")
          File.write("applications/existing-app/job_description.md", "# Job")

          app = Jojo::Application.new("existing-app")
          _(app.artifacts_exist?).must_equal true
        end
      end
    end
  end

  describe "#create_directory!" do
    it "creates base_path and website_path directories" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          app = Jojo::Application.new("new-app")
          app.create_directory!

          _(File.directory?("applications/new-app")).must_equal true
          _(File.directory?("applications/new-app/website")).must_equal true
        end
      end
    end
  end
end
