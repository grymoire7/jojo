# frozen_string_literal: true

require_relative "../../../test_helper"

class Jojo::Commands::Interactive::DialogsTest < JojoTest
  # .blocked_dialog

  def test_blocked_dialog_renders_dialog_showing_missing_prerequisites
    output = Jojo::Commands::Interactive::Dialogs.blocked_dialog("Cover Letter", ["Resume"])

    _(output).must_include "Cover Letter"
    _(output).must_include "Cannot generate yet"
    _(output).must_include "Resume"
    _(output).must_include "[Esc] Back"
  end

  # .ready_dialog

  def test_ready_dialog_renders_dialog_for_ready_item_with_inputs_and_output
    inputs = [
      {name: "resume.md", age: "2 hours ago"},
      {name: "job_description.md", age: nil}
    ]

    output = Jojo::Commands::Interactive::Dialogs.ready_dialog("Cover Letter", inputs, "cover_letter.md", paid: true)

    _(output).must_include "Cover Letter"
    _(output).must_include "Generate"
    _(output).must_include "$"
    _(output).must_include "resume.md"
    _(output).must_include "2 hours ago"
    _(output).must_include "cover_letter.md"
    _(output).must_include "[Enter] Generate"
  end

  # .generated_dialog

  def test_generated_dialog_renders_dialog_for_already_generated_item
    output = Jojo::Commands::Interactive::Dialogs.generated_dialog("Cover Letter", "1 hour ago", paid: true)

    _(output).must_include "cover_letter.md already exists"
    _(output).must_include "1 hour ago"
    _(output).must_include "[r] Regenerate"
    _(output).must_include "$"
    _(output).must_include "[v] View"
  end

  # .error_dialog

  def test_error_dialog_renders_error_dialog_with_message
    output = Jojo::Commands::Interactive::Dialogs.error_dialog("Cover Letter", "API Error: Rate limit exceeded")

    _(output).must_include "Error"
    _(output).must_include "Cover Letter generation failed"
    _(output).must_include "Rate limit exceeded"
    _(output).must_include "[r] Retry"
    _(output).must_include "[Esc] Back"
  end

  # .input_dialog

  def test_input_dialog_renders_input_dialog_with_prompt
    output = Jojo::Commands::Interactive::Dialogs.input_dialog("New Application", "Slug (e.g., acme-corp-senior-dev):")

    _(output).must_include "New Application"
    _(output).must_include "Slug"
    _(output).must_include "> "
  end
end
