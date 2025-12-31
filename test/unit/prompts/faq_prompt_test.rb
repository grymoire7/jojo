require_relative "../../test_helper"
require_relative "../../../lib/jojo/prompts/faq_prompt"

describe Jojo::Prompts::Faq do
  it "includes job description in prompt" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "We need a Python developer with 5+ years experience.",
      resume: "# John Doe\nPython developer...",
      research: nil,
      job_details: {"job_title" => "Senior Python Developer", "company_name" => "Acme Corp"},
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional and friendly"
    )

    _(prompt).must_include "We need a Python developer with 5+ years experience."
  end

  it "includes resume in prompt" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "Python developer needed",
      resume: "# John Doe\nSenior developer with expertise...",
      research: nil,
      job_details: {},
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "# John Doe"
    _(prompt).must_include "Senior developer with expertise"
  end

  it "includes research when available" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "Python developer",
      resume: "Resume content",
      research: "Acme Corp is a fintech startup...",
      job_details: {},
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Acme Corp is a fintech startup"
  end

  it "includes base URL for PDF links" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "Developer needed",
      resume: "Resume",
      research: nil,
      job_details: {"company_name" => "Acme"},
      base_url: "https://johndoe.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "https://johndoe.com"
  end

  it "specifies required FAQ categories" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "Developer needed",
      resume: "Resume",
      research: nil,
      job_details: {},
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Tech stack"
    _(prompt).must_include "Remote work"
    _(prompt).must_include "AI philosophy"
    _(prompt).must_include "why this company"
  end

  it "handles missing research gracefully" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "Developer needed",
      resume: "Resume",
      research: nil,
      job_details: {},
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional"
    )

    _(prompt).wont_be_nil
    _(prompt).must_be_kind_of String
  end
end
