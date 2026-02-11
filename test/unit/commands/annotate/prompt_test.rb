# test/unit/commands/annotate/prompt_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/annotate/prompt"

class Jojo::Commands::Annotate::PromptTest < JojoTest
  def test_generates_prompt_with_all_required_context
    job_description = "We need 5+ years of Python experience and knowledge of distributed systems."
    resume = "# John Doe\n\nSenior Python developer with 7 years experience..."
    research = "Acme Corp values technical expertise..."

    prompt = Jojo::Commands::Annotate::Prompt.generate_annotations_prompt(
      job_description: job_description,
      resume: resume,
      research: research
    )

    assert_includes prompt, job_description
    assert_includes prompt, resume
    assert_includes prompt, research
    assert_includes prompt, "strong"
    assert_includes prompt, "moderate"
    assert_includes prompt, "mention"
    assert_includes prompt, "JSON"
    assert_includes prompt, "EXACTLY as it appears"
  end

  def test_generates_prompt_without_research
    job_description = "We need 5+ years of Python experience."
    resume = "# John Doe\n\nSenior Python developer..."

    prompt = Jojo::Commands::Annotate::Prompt.generate_annotations_prompt(
      job_description: job_description,
      resume: resume,
      research: nil
    )

    assert_includes prompt, job_description
    assert_includes prompt, resume
    refute_includes prompt, "## Company Research"
  end
end
