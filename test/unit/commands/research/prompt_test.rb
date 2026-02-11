# test/unit/commands/research/prompt_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/research/prompt"

class Jojo::Commands::Research::PromptTest < JojoTest
  def test_generates_research_prompt_with_all_inputs
    job_description = "Senior Ruby Developer at Acme Corp..."
    company_name = "Acme Corp"
    web_results = "Acme Corp recently raised Series B funding..."
    resume = "## Experience\n\n### Software Engineer at Previous Co..."

    prompt = Jojo::Commands::Research::Prompt.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: web_results,
      resume: resume
    )

    assert_includes prompt, "Acme Corp"
    assert_includes prompt, "Senior Ruby Developer"
    assert_includes prompt, "Series B funding"
    assert_includes prompt, "Software Engineer at Previous Co"
    assert_includes prompt, "Company Profile"
    assert_includes prompt, "Role Analysis"
    assert_includes prompt, "Strategic Positioning"
    assert_includes prompt, "Tailoring Recommendations"
  end

  def test_generates_prompt_without_web_results
    job_description = "Senior Ruby Developer..."
    company_name = "Acme Corp"
    resume = "## Experience..."

    prompt = Jojo::Commands::Research::Prompt.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: nil,
      resume: resume
    )

    assert_includes prompt, "Acme Corp"
    assert_includes prompt, "no additional web research available"
  end

  def test_generates_prompt_without_resume
    job_description = "Senior Ruby Developer..."
    company_name = "Acme Corp"
    web_results = "Acme Corp info..."

    prompt = Jojo::Commands::Research::Prompt.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: web_results,
      resume: nil
    )

    assert_includes prompt, "Acme Corp"
    refute_includes prompt, "Strategic Positioning"
    assert_includes prompt, "generic recommendations"
  end
end
