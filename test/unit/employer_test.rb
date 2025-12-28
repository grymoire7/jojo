require_relative '../test_helper'
require_relative '../../lib/jojo/employer'

describe Jojo::Employer do
  it "slugifies company name with spaces" do
    employer = Jojo::Employer.new('Acme Corp')
    _(employer.slug).must_equal 'acme-corp'
  end

  it "slugifies special characters" do
    employer = Jojo::Employer.new('AT&T Inc.')
    _(employer.slug).must_equal 'at-t-inc'
  end

  it "slugifies multiple spaces" do
    employer = Jojo::Employer.new('Example  Company   LLC')
    _(employer.slug).must_equal 'example-company-llc'
  end

  it "slugifies leading and trailing special characters" do
    employer = Jojo::Employer.new('!Company!')
    _(employer.slug).must_equal 'company'
  end

  it "provides correct file paths" do
    employer = Jojo::Employer.new('Acme Corp')

    _(employer.base_path).must_equal 'employers/acme-corp'
    _(employer.job_description_path).must_equal 'employers/acme-corp/job_description.md'
    _(employer.job_description_annotations_path).must_equal 'employers/acme-corp/job_description_annotations.json'
    _(employer.research_path).must_equal 'employers/acme-corp/research.md'
    _(employer.resume_path).must_equal 'employers/acme-corp/resume.md'
    _(employer.cover_letter_path).must_equal 'employers/acme-corp/cover_letter.md'
    _(employer.status_log_path).must_equal 'employers/acme-corp/status_log.md'
    _(employer.website_path).must_equal 'employers/acme-corp/website'
    _(employer.index_html_path).must_equal 'employers/acme-corp/website/index.html'
    _(employer.faq_path).must_equal 'employers/acme-corp/faq.json'
  end

  it "creates directory structure" do
    employer = Jojo::Employer.new('Test Company')

    # Clean up before test
    FileUtils.rm_rf('employers/test-company') if Dir.exist?('employers/test-company')

    _(Dir.exist?('employers/test-company')).must_equal false
    _(Dir.exist?('employers/test-company/website')).must_equal false

    employer.create_directory!

    _(Dir.exist?('employers/test-company')).must_equal true
    _(Dir.exist?('employers/test-company/website')).must_equal true

    # Clean up after test
    FileUtils.rm_rf('employers/test-company')
  end
end
