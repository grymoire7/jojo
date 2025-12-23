require_relative '../test_helper'
require_relative '../../lib/jojo/prompts/research_prompt'

describe Jojo::Prompts::Research do
  it "generates research prompt with all inputs" do
    job_description = "Senior Ruby Developer at Acme Corp..."
    company_name = "Acme Corp"
    web_results = "Acme Corp recently raised Series B funding..."
    resume = "## Experience\n\n### Software Engineer at Previous Co..."

    prompt = Jojo::Prompts::Research.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: web_results,
      resume: resume
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "Senior Ruby Developer"
    _(prompt).must_include "Series B funding"
    _(prompt).must_include "Software Engineer at Previous Co"
    _(prompt).must_include "Company Profile"
    _(prompt).must_include "Role Analysis"
    _(prompt).must_include "Strategic Positioning"
    _(prompt).must_include "Tailoring Recommendations"
  end

  it "generates prompt without web results" do
    job_description = "Senior Ruby Developer..."
    company_name = "Acme Corp"
    resume = "## Experience..."

    prompt = Jojo::Prompts::Research.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: nil,
      resume: resume
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "no additional web research available"
  end

  it "generates prompt without resume" do
    job_description = "Senior Ruby Developer..."
    company_name = "Acme Corp"
    web_results = "Acme Corp info..."

    prompt = Jojo::Prompts::Research.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: web_results,
      resume: nil
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).wont_include "Strategic Positioning"
    _(prompt).must_include "generic recommendations"
  end
end
