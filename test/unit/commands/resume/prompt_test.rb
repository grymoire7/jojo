# test/unit/commands/resume/prompt_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/prompt"

class Jojo::Commands::Resume::PromptTest < JojoTest
  def test_generates_prompt_with_all_inputs
    job_description = "Senior Ruby Developer role..."
    research = "# Company Profile\n\nAcme Corp..."
    generic_resume = "# Jane Doe\n\n## Experience..."
    job_details = {"job_title" => "Senior Ruby Developer", "company_name" => "Acme Corp"}
    voice_and_tone = "professional and friendly"

    prompt = Jojo::Commands::Resume::Prompt.generate_prompt(
      job_description: job_description,
      research: research,
      generic_resume: generic_resume,
      job_details: job_details,
      voice_and_tone: voice_and_tone
    )

    _(prompt).must_include "Senior Ruby Developer"
    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "Jane Doe"
    _(prompt).must_include "professional and friendly"
    _(prompt).must_include "PRESERVE"
    _(prompt).must_include "PRUNE"
  end

  def test_generates_prompt_without_optional_inputs
    job_description = "Ruby Developer role..."
    generic_resume = "# Jane Doe..."

    prompt = Jojo::Commands::Resume::Prompt.generate_prompt(
      job_description: job_description,
      research: nil,
      generic_resume: generic_resume,
      job_details: nil,
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Ruby Developer"
    _(prompt).must_include "Jane Doe"
    _(prompt).wont_include "# Company Profile"
  end
end
