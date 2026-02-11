# frozen_string_literal: true

require "test_helper"
require "jojo/application"

class ApplicationTest < JojoTest
  def test_sets_slug_and_base_path
    app = Jojo::Application.new("acme-corp")

    assert_equal "acme-corp", app.slug
    assert_equal "applications/acme-corp", app.base_path
  end

  def test_returns_job_description_raw_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/job_description_raw.md", app.job_description_raw_path
  end

  def test_returns_job_description_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/job_description.md", app.job_description_path
  end

  def test_returns_job_details_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/job_details.yml", app.job_details_path
  end

  def test_returns_resume_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/resume.md", app.resume_path
  end

  def test_returns_cover_letter_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/cover_letter.md", app.cover_letter_path
  end

  def test_returns_research_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/research.md", app.research_path
  end

  def test_returns_website_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/website", app.website_path
  end

  def test_returns_faq_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/faq.json", app.faq_path
  end

  def test_returns_slug_when_job_details_yml_does_not_exist
    app = Jojo::Application.new("acme-corp")
    assert_equal "acme-corp", app.company_name
  end

  def test_returns_company_name_from_job_details_yml_when_it_exists
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_details.yml", "company_name: Acme Corporation")

    app = Jojo::Application.new("acme-corp")
    assert_equal "Acme Corporation", app.company_name
  end

  def test_artifacts_exist_returns_false_when_no_artifacts_exist
    app = Jojo::Application.new("new-app")
    assert_equal false, app.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_description_exists
    FileUtils.mkdir_p("applications/existing-app")
    File.write("applications/existing-app/job_description.md", "# Job")

    app = Jojo::Application.new("existing-app")
    assert_equal true, app.artifacts_exist?
  end

  def test_creates_base_path_and_website_path_directories
    app = Jojo::Application.new("new-app")
    app.create_directory!

    assert_equal true, File.directory?("applications/new-app")
    assert_equal true, File.directory?("applications/new-app/website")
  end
end
