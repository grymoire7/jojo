require_relative "../../test_helper"
require_relative "../../../lib/jojo/prompts/website_prompt"

describe Jojo::Prompts::Website do
  it "generates branding statement prompt with all inputs" do
    job_description = "Senior Ruby Developer role at Acme Corp..."
    research = "# Company Profile\n\nAcme Corp is a leading tech company..."
    resume = "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer..."
    job_details = {"job_title" => "Senior Ruby Developer", "company_name" => "Acme Corp"}
    company_name = "Acme Corp"
    seeker_name = "Jane Doe"
    voice_and_tone = "professional and friendly"

    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: job_description,
      research: research,
      resume: resume,
      job_details: job_details,
      company_name: company_name,
      seeker_name: seeker_name,
      voice_and_tone: voice_and_tone
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "Jane Doe"
    _(prompt).must_include "professional and friendly"
    _(prompt).must_include "Senior Ruby Developer"
    _(prompt).must_include "150-250 words"
    _(prompt).must_include "2-3 paragraphs"
  end

  it "generates prompt without research (graceful degradation)" do
    job_description = "Ruby Developer role..."
    resume = "# Jane Doe\n\nExperienced developer..."
    company_name = "Tech Corp"
    seeker_name = "Jane Doe"
    voice_and_tone = "professional"

    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: job_description,
      research: nil,
      resume: resume,
      job_details: nil,
      company_name: company_name,
      seeker_name: seeker_name,
      voice_and_tone: voice_and_tone
    )

    _(prompt).must_include "Jane Doe"
    _(prompt).must_include "Ruby Developer"
    _(prompt).must_include "No company research available"
    _(prompt).wont_include "## Company Research"
  end

  it "includes voice and tone in prompt" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Developer role",
      resume: "Resume content",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "casual and enthusiastic"
    )

    _(prompt).must_include "casual and enthusiastic"
  end

  it "specifies output format requirements" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job",
      resume: "Resume",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Plain text paragraphs"
    _(prompt).must_include "NO markdown headers"
    _(prompt).must_include "First person perspective"
  end

  it "includes seeker name in question" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Job",
      resume: "Resume",
      company_name: "Awesome Company",
      seeker_name: "John Smith",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "John Smith"
    _(prompt).must_include "Why is"
    _(prompt).must_include "perfect for THIS company"
  end

  it "includes job details when provided" do
    job_details = {"job_title" => "Lead Developer", "location" => "Remote"}

    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Developer role",
      resume: "Resume",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "professional",
      job_details: job_details
    )

    _(prompt).must_include "Lead Developer"
    _(prompt).must_include "Remote"
    _(prompt).must_include "Structured Job Details"
  end

  it "excludes job details section when not provided" do
    prompt = Jojo::Prompts::Website.generate_branding_statement(
      job_description: "Developer role",
      resume: "Resume",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "professional",
      job_details: nil
    )

    _(prompt).wont_include "Structured Job Details"
  end
end
