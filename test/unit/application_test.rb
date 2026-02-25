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

  def test_returns_branding_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/branding.md", app.branding_path
  end

  def test_returns_resume_pdf_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/resume.pdf", app.resume_pdf_path
  end

  def test_returns_cover_letter_pdf_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/cover_letter.pdf", app.cover_letter_pdf_path
  end

  def test_returns_resume_html_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/resume.html", app.resume_html_path
  end

  def test_returns_cover_letter_html_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/cover_letter.html", app.cover_letter_html_path
  end

  def test_returns_status_log_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/status.log", app.status_log_path
  end

  def test_returns_index_html_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/website/index.html", app.index_html_path
  end

  def test_returns_job_description_annotations_path
    app = Jojo::Application.new("test-app")
    assert_equal "applications/test-app/job_description_annotations.json", app.job_description_annotations_path
  end

  def test_job_details_returns_empty_hash_when_file_missing
    app = Jojo::Application.new("test-app")
    assert_equal({}, app.job_details)
  end

  def test_job_details_returns_parsed_yaml
    FileUtils.mkdir_p("applications/test-app")
    File.write("applications/test-app/job_details.yml", "company_name: Test\njob_title: Dev")

    app = Jojo::Application.new("test-app")
    details = app.job_details

    assert_equal "Test", details["company_name"]
    assert_equal "Dev", details["job_title"]
  end

  def test_job_details_returns_empty_hash_on_malformed_yaml
    FileUtils.mkdir_p("applications/test-app")
    File.write("applications/test-app/job_details.yml", "")

    app = Jojo::Application.new("test-app")
    assert_equal({}, app.job_details)
  end

  def test_artifacts_exist_returns_true_when_job_details_exist
    FileUtils.mkdir_p("applications/existing-app")
    File.write("applications/existing-app/job_details.yml", "company_name: Test")

    app = Jojo::Application.new("existing-app")
    assert_equal true, app.artifacts_exist?
  end

  def test_name_defaults_to_slug
    app = Jojo::Application.new("my-slug")
    assert_equal "my-slug", app.name
  end

  def test_status_logger_returns_status_logger_instance
    app = Jojo::Application.new("test-app")
    app.create_directory!

    logger = app.status_logger
    assert_instance_of Jojo::StatusLogger, logger
  end
end
