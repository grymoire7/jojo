require_relative '../test_helper'
require_relative '../../lib/jojo/prompts/website_prompt'

describe Jojo::Prompts::Website do
  it "generates branding statement prompt with all required parameters" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Senior Ruby Developer position...",
      resume: "# John Doe\n\nExperienced Ruby developer...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional and friendly"
    )

    _(prompt).must_be_kind_of String
    _(prompt).must_include "Senior Ruby Developer position"
    _(prompt).must_include "John Doe"
    _(prompt).must_include "Experienced Ruby developer"
    _(prompt).must_include "professional and friendly"
  end

  it "includes research when available" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional",
      research: "Company mission: Innovative tech solutions..."
    )

    _(prompt).must_include "Company Research"
    _(prompt).must_include "Innovative tech solutions"
  end

  it "handles missing research gracefully" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional",
      research: nil
    )

    _(prompt).must_include "No company research available"
    _(prompt).wont_include "Company Research"
  end

  it "includes job details when available" do
    job_details = { 'job_title' => 'Senior Ruby Developer', 'location' => 'Remote' }

    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional",
      job_details: job_details
    )

    _(prompt).must_include "Structured Job Details"
    _(prompt).must_include "Senior Ruby Developer"
    _(prompt).must_include "Remote"
  end

  it "handles missing job details gracefully" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional",
      job_details: nil
    )

    _(prompt).wont_include "Structured Job Details"
  end

  it "specifies output format requirements" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Output Requirements"
    _(prompt).must_include "Plain text paragraphs"
    _(prompt).must_include "NO markdown"
    _(prompt).must_include "150-250 words"
  end

  it "includes voice and tone instructions" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "casual and friendly"
    )

    _(prompt).must_include "VOICE AND TONE"
    _(prompt).must_include "casual and friendly"
  end

  it "emphasizes specificity to company" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job description...",
      resume: "Resume content...",
      company_name: "Acme Corp",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Why is John Doe perfect for THIS company"
    _(prompt).must_include "Specific to THIS company and role (not generic)"
  end
end
