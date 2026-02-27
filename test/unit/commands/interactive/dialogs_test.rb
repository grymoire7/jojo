# frozen_string_literal: true

require_relative "../../../test_helper"

class Jojo::Commands::Interactive::DialogsTest < JojoTest
  # .blocked_dialog

  def test_blocked_dialog_renders_dialog_showing_missing_prerequisites
    output = Jojo::Commands::Interactive::Dialogs.blocked_dialog("Cover Letter", ["Resume"])

    assert_includes output, "Cover Letter"
    assert_includes output, "Cannot generate yet"
    assert_includes output, "Resume"
    assert_includes output, "[Esc] Back"
  end

  # .ready_dialog

  def test_ready_dialog_renders_dialog_for_ready_item_with_inputs_and_output
    inputs = [
      {name: "resume.md", age: "2 hours ago"},
      {name: "job_description.md", age: nil}
    ]

    output = Jojo::Commands::Interactive::Dialogs.ready_dialog("Cover Letter", inputs, ["cover_letter.md"], paid: true)

    assert_includes output, "Cover Letter"
    assert_includes output, "Generate"
    assert_includes output, "$"
    assert_includes output, "resume.md"
    assert_includes output, "2 hours ago"
    assert_includes output, "cover_letter.md"
    assert_includes output, "[Enter] Generate"
  end

  def test_ready_dialog_shows_all_output_files_for_multi_file_commands
    inputs = [
      {name: "resume.md", age: "1 day ago"},
      {name: "cover_letter.md", age: "1 day ago"}
    ]

    output = Jojo::Commands::Interactive::Dialogs.ready_dialog("PDF", inputs, ["website/resume.pdf", "website/cover_letter.pdf"])

    assert_includes output, "website/resume.pdf"
    assert_includes output, "website/cover_letter.pdf"
  end

  # .generated_dialog

  def test_generated_dialog_renders_dialog_for_already_generated_item
    output = Jojo::Commands::Interactive::Dialogs.generated_dialog("Cover Letter", "1 hour ago", output_files: ["cover_letter.md"], paid: true)

    assert_includes output, "cover_letter.md already exists"
    assert_includes output, "1 hour ago"
    assert_includes output, "[r] Regenerate"
    assert_includes output, "$"
    assert_includes output, "[v] View"
  end

  def test_generated_dialog_shows_all_output_files_for_multi_file_commands
    output = Jojo::Commands::Interactive::Dialogs.generated_dialog("PDF", "3 hours ago", output_files: ["website/resume.pdf", "website/cover_letter.pdf"])

    assert_includes output, "website/resume.pdf already exists"
    assert_includes output, "website/cover_letter.pdf"
  end

  # .error_dialog

  def test_error_dialog_renders_error_dialog_with_message
    output = Jojo::Commands::Interactive::Dialogs.error_dialog("Cover Letter", "API Error: Rate limit exceeded")

    assert_includes output, "Error"
    assert_includes output, "Cover Letter generation failed"
    assert_includes output, "Rate limit exceeded"
    assert_includes output, "[r] Retry"
    assert_includes output, "[Esc] Back"
  end

  # .input_dialog

  def test_input_dialog_renders_input_dialog_with_prompt
    output = Jojo::Commands::Interactive::Dialogs.input_dialog("New Application", "Slug (e.g., acme-corp-senior-dev):")

    assert_includes output, "New Application"
    assert_includes output, "Slug"
    assert_includes output, "> "
  end
end
