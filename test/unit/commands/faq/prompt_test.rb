# test/unit/commands/faq/prompt_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/faq/prompt"

class Jojo::Commands::Faq::PromptTest < JojoTest
  def test_includes_job_description_in_prompt
    prompt = Jojo::Commands::Faq::Prompt.generate_prompt(
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

  def test_includes_resume_in_prompt
    prompt = Jojo::Commands::Faq::Prompt.generate_prompt(
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

  def test_includes_research_when_available
    prompt = Jojo::Commands::Faq::Prompt.generate_prompt(
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

  def test_includes_base_url_for_pdf_links
    prompt = Jojo::Commands::Faq::Prompt.generate_prompt(
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

  def test_specifies_required_faq_categories
    prompt = Jojo::Commands::Faq::Prompt.generate_prompt(
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
    _(prompt).must_include "Why this company"
  end

  def test_handles_missing_research_gracefully
    prompt = Jojo::Commands::Faq::Prompt.generate_prompt(
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
