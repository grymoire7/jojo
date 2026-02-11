# frozen_string_literal: true

require "test_helper"
require "jojo/application"

class ApplicationTest < JojoTest
  def test_sets_slug_and_base_path
    app = Jojo::Application.new("acme-corp")

    _(app.slug).must_equal "acme-corp"
    _(app.base_path).must_equal "applications/acme-corp"
  end

  def test_returns_job_description_raw_path
    app = Jojo::Application.new("test-app")
    _(app.job_description_raw_path).must_equal "applications/test-app/job_description_raw.md"
  end

  def test_returns_job_description_path
    app = Jojo::Application.new("test-app")
    _(app.job_description_path).must_equal "applications/test-app/job_description.md"
  end

  def test_returns_job_details_path
    app = Jojo::Application.new("test-app")
    _(app.job_details_path).must_equal "applications/test-app/job_details.yml"
  end

  def test_returns_resume_path
    app = Jojo::Application.new("test-app")
    _(app.resume_path).must_equal "applications/test-app/resume.md"
  end

  def test_returns_cover_letter_path
    app = Jojo::Application.new("test-app")
    _(app.cover_letter_path).must_equal "applications/test-app/cover_letter.md"
  end

  def test_returns_research_path
    app = Jojo::Application.new("test-app")
    _(app.research_path).must_equal "applications/test-app/research.md"
  end

  def test_returns_website_path
    app = Jojo::Application.new("test-app")
    _(app.website_path).must_equal "applications/test-app/website"
  end

  def test_returns_faq_path
    app = Jojo::Application.new("test-app")
    _(app.faq_path).must_equal "applications/test-app/faq.json"
  end

  def test_returns_slug_when_job_details_yml_does_not_exist
    app = Jojo::Application.new("acme-corp")
    _(app.company_name).must_equal "acme-corp"
  end

  def test_returns_company_name_from_job_details_yml_when_it_exists
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_details.yml", "company_name: Acme Corporation")

    app = Jojo::Application.new("acme-corp")
    _(app.company_name).must_equal "Acme Corporation"
  end

  def test_artifacts_exist_returns_false_when_no_artifacts_exist
    app = Jojo::Application.new("new-app")
    _(app.artifacts_exist?).must_equal false
  end

  def test_artifacts_exist_returns_true_when_job_description_exists
    FileUtils.mkdir_p("applications/existing-app")
    File.write("applications/existing-app/job_description.md", "# Job")

    app = Jojo::Application.new("existing-app")
    _(app.artifacts_exist?).must_equal true
  end

  def test_creates_base_path_and_website_path_directories
    app = Jojo::Application.new("new-app")
    app.create_directory!

    _(File.directory?("applications/new-app")).must_equal true
    _(File.directory?("applications/new-app/website")).must_equal true
  end
end
