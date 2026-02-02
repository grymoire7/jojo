# frozen_string_literal: true

require_relative "../../../test_helper"

describe Jojo::Commands::Interactive::Dialogs do
  describe ".blocked_dialog" do
    it "renders dialog showing missing prerequisites" do
      output = Jojo::Commands::Interactive::Dialogs.blocked_dialog("Cover Letter", ["Resume"])

      _(output).must_include "Cover Letter"
      _(output).must_include "Cannot generate yet"
      _(output).must_include "Resume"
      _(output).must_include "[Esc] Back"
    end
  end

  describe ".ready_dialog" do
    it "renders dialog for ready item with inputs and output" do
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
  end

  describe ".generated_dialog" do
    it "renders dialog for already generated item" do
      output = Jojo::Commands::Interactive::Dialogs.generated_dialog("Cover Letter", "1 hour ago", paid: true)

      _(output).must_include "cover_letter.md already exists"
      _(output).must_include "1 hour ago"
      _(output).must_include "[r] Regenerate"
      _(output).must_include "$"
      _(output).must_include "[v] View"
    end
  end

  describe ".error_dialog" do
    it "renders error dialog with message" do
      output = Jojo::Commands::Interactive::Dialogs.error_dialog("Cover Letter", "API Error: Rate limit exceeded")

      _(output).must_include "Error"
      _(output).must_include "Cover Letter generation failed"
      _(output).must_include "Rate limit exceeded"
      _(output).must_include "[r] Retry"
      _(output).must_include "[Esc] Back"
    end
  end

  describe ".input_dialog" do
    it "renders input dialog with prompt" do
      output = Jojo::Commands::Interactive::Dialogs.input_dialog("New Application", "Slug (e.g., acme-corp-senior-dev):")

      _(output).must_include "New Application"
      _(output).must_include "Slug"
      _(output).must_include "> "
    end
  end
end
