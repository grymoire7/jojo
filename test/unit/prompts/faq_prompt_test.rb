require_relative '../../test_helper'
require_relative '../../../lib/jojo/prompts/faq_prompt'

describe Jojo::Prompts::Faq do
  it "includes job description in prompt" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "We need a Python developer with 5+ years experience.",
      resume: "# John Doe\nPython developer...",
      research: nil,
      job_details: { 'job_title' => 'Senior Python Developer', 'company_name' => 'Acme Corp' },
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional and friendly"
    )

    _(prompt).must_include "We need a Python developer with 5+ years experience."
  end
end
