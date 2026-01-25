require_relative "../test_helper"
require_relative "../../lib/jojo/employer"

describe Jojo::Employer do
  it "accepts slug directly" do
    employer = Jojo::Employer.new("acme-corp")
    _(employer.slug).must_equal "acme-corp"
    _(employer.name).must_equal "acme-corp"
  end

  it "uses slug for paths" do
    employer = Jojo::Employer.new("my-test-slug")
    _(employer.slug).must_equal "my-test-slug"
    _(employer.base_path).must_equal "employers/my-test-slug"
  end

  it "provides correct file paths" do
    employer = Jojo::Employer.new("acme-corp")

    _(employer.base_path).must_equal "employers/acme-corp"
    _(employer.job_description_path).must_equal "employers/acme-corp/job_description.md"
    _(employer.job_description_annotations_path).must_equal "employers/acme-corp/job_description_annotations.json"
    _(employer.research_path).must_equal "employers/acme-corp/research.md"
    _(employer.resume_path).must_equal "employers/acme-corp/resume.md"
    _(employer.cover_letter_path).must_equal "employers/acme-corp/cover_letter.md"
    _(employer.status_log_path).must_equal "employers/acme-corp/status.log"
    _(employer.website_path).must_equal "employers/acme-corp/website"
    _(employer.index_html_path).must_equal "employers/acme-corp/website/index.html"
    _(employer.faq_path).must_equal "employers/acme-corp/faq.json"
  end

  it "returns branding_path" do
    employer = Jojo::Employer.new("test-company")
    _(employer.branding_path).must_equal "employers/test-company/branding.md"
  end

  it "creates directory structure" do
    employer = Jojo::Employer.new("test-company")

    # Clean up before test
    FileUtils.rm_rf("employers/test-company") if Dir.exist?("employers/test-company")

    _(Dir.exist?("employers/test-company")).must_equal false
    _(Dir.exist?("employers/test-company/website")).must_equal false

    employer.create_directory!

    _(Dir.exist?("employers/test-company")).must_equal true
    _(Dir.exist?("employers/test-company/website")).must_equal true

    # Clean up after test
    FileUtils.rm_rf("employers/test-company")
  end
end
