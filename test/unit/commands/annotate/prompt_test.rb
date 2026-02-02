# test/unit/commands/annotate/prompt_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/annotate/prompt"

describe Jojo::Commands::Annotate::Prompt do
  it "generates prompt with all required context" do
    job_description = "We need 5+ years of Python experience and knowledge of distributed systems."
    resume = "# John Doe\n\nSenior Python developer with 7 years experience..."
    research = "Acme Corp values technical expertise..."

    prompt = Jojo::Commands::Annotate::Prompt.generate_annotations_prompt(
      job_description: job_description,
      resume: resume,
      research: research
    )

    _(prompt).must_include job_description
    _(prompt).must_include resume
    _(prompt).must_include research
    _(prompt).must_include "strong"
    _(prompt).must_include "moderate"
    _(prompt).must_include "mention"
    _(prompt).must_include "JSON"
    _(prompt).must_include "EXACTLY as it appears"
  end

  it "generates prompt without research (graceful degradation)" do
    job_description = "We need 5+ years of Python experience."
    resume = "# John Doe\n\nSenior Python developer..."

    prompt = Jojo::Commands::Annotate::Prompt.generate_annotations_prompt(
      job_description: job_description,
      resume: resume,
      research: nil
    )

    _(prompt).must_include job_description
    _(prompt).must_include resume
    _(prompt).wont_include "## Company Research"
  end
end
