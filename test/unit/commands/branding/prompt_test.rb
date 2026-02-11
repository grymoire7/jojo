# test/unit/commands/branding/prompt_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/branding/prompt"

class Jojo::Commands::Branding::PromptTest < JojoTest
  def test_generates_branding_statement_prompt_with_all_inputs
    job_description = "Senior Ruby Developer role at Acme Corp..."
    research = "# Company Profile\n\nAcme Corp is a leading tech company..."
    resume = "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer..."
    job_details = {"job_title" => "Senior Ruby Developer", "company_name" => "Acme Corp"}
    company_name = "Acme Corp"
    seeker_name = "Jane Doe"
    voice_and_tone = "professional and friendly"

    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: job_description,
      research: research,
      resume: resume,
      job_details: job_details,
      company_name: company_name,
      seeker_name: seeker_name,
      voice_and_tone: voice_and_tone
    )

    assert_includes prompt, "Acme Corp"
    assert_includes prompt, "Jane Doe"
    assert_includes prompt, "professional and friendly"
    assert_includes prompt, "Senior Ruby Developer"
    assert_includes prompt, "150-250 words"
    assert_includes prompt, "2-3 paragraphs"
  end

  def test_generates_prompt_without_research
    job_description = "Ruby Developer role..."
    resume = "# Jane Doe\n\nExperienced developer..."
    company_name = "Tech Corp"
    seeker_name = "Jane Doe"
    voice_and_tone = "professional"

    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: job_description,
      research: nil,
      resume: resume,
      job_details: nil,
      company_name: company_name,
      seeker_name: seeker_name,
      voice_and_tone: voice_and_tone
    )

    assert_includes prompt, "Jane Doe"
    assert_includes prompt, "Ruby Developer"
    assert_includes prompt, "No company research available"
    refute_includes prompt, "## Company Research"
  end

  def test_includes_voice_and_tone_in_prompt
    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: "Developer role",
      resume: "Resume content",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "casual and enthusiastic"
    )

    assert_includes prompt, "casual and enthusiastic"
  end

  def test_specifies_output_format_requirements
    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: "Job",
      resume: "Resume",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "professional"
    )

    assert_includes prompt, "Plain text paragraphs"
    assert_includes prompt, "NO markdown headers"
    assert_includes prompt, "First person perspective"
  end

  def test_includes_seeker_name_in_question
    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: "Job",
      resume: "Resume",
      company_name: "Awesome Company",
      seeker_name: "John Smith",
      voice_and_tone: "professional"
    )

    assert_includes prompt, "John Smith"
    assert_includes prompt, "Why is"
    assert_includes prompt, "perfect for THIS company"
  end

  def test_includes_job_details_when_provided
    job_details = {"job_title" => "Lead Developer", "location" => "Remote"}

    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: "Developer role",
      resume: "Resume",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "professional",
      job_details: job_details
    )

    assert_includes prompt, "Lead Developer"
    assert_includes prompt, "Remote"
    assert_includes prompt, "Structured Job Details"
  end

  def test_excludes_job_details_section_when_not_provided
    prompt = Jojo::Commands::Branding::Prompt.generate_prompt(
      job_description: "Developer role",
      resume: "Resume",
      company_name: "Company",
      seeker_name: "Seeker",
      voice_and_tone: "professional",
      job_details: nil
    )

    refute_includes prompt, "Structured Job Details"
  end
end
