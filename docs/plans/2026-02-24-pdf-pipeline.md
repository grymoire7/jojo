# PDF Pipeline Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the pandoc+pdflatex PDF pipeline with a two-step pandoc→HTML + wkhtmltopdf→PDF pipeline that produces both `resume.html` and `resume.pdf` (and cover letter equivalents) as permanent build artifacts.

**Architecture:** The `Converter` class gains a two-step private pipeline — `build_pandoc_html_command` and `build_wkhtmltopdf_command` — replacing `build_pandoc_command`. A new `WkhtmltopdfChecker` class mirrors `PandocChecker`. HTML artifacts are saved alongside PDFs in the application directory.

**Tech Stack:** Ruby minitest, pandoc (markdown→HTML), wkhtmltopdf (HTML→PDF), CSS (pdf-stylesheet.css)

---

### Task 1: Add WkhtmltopdfChecker

**Files:**
- Create: `lib/jojo/commands/pdf/wkhtmltopdf_checker.rb`
- Create: `test/unit/commands/pdf/wkhtmltopdf_checker_test.rb`

**Step 1: Write the failing tests**

```ruby
# test/unit/commands/pdf/wkhtmltopdf_checker_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/wkhtmltopdf_checker"

class Jojo::Commands::Pdf::WkhtmltopdfCheckerTest < JojoTest
  # -- .available? --

  def test_available_returns_true_when_wkhtmltopdf_is_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:system, true) do
      assert_equal true, Jojo::Commands::Pdf::WkhtmltopdfChecker.available?
    end
  end

  def test_available_returns_false_when_wkhtmltopdf_is_not_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:system, false) do
      assert_equal false, Jojo::Commands::Pdf::WkhtmltopdfChecker.available?
    end
  end

  # -- .version --

  def test_version_returns_version_string_when_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, true) do
      Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:`, "wkhtmltopdf 0.12.6\n") do
        assert_equal "0.12.6", Jojo::Commands::Pdf::WkhtmltopdfChecker.version
      end
    end
  end

  def test_version_returns_nil_when_not_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, false) do
      assert_nil Jojo::Commands::Pdf::WkhtmltopdfChecker.version
    end
  end

  # -- .check! --

  def test_check_raises_error_when_not_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, false) do
      error = assert_raises(Jojo::Commands::Pdf::WkhtmltopdfChecker::WkhtmltopdfNotFoundError) do
        Jojo::Commands::Pdf::WkhtmltopdfChecker.check!
      end
      assert_includes error.message, "wkhtmltopdf is not installed"
    end
  end

  def test_check_returns_true_when_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, true) do
      assert_equal true, Jojo::Commands::Pdf::WkhtmltopdfChecker.check!
    end
  end
end
```

**Step 2: Run test to verify it fails**

```
./bin/test test/unit/commands/pdf/wkhtmltopdf_checker_test.rb
```

Expected: `LoadError` — file doesn't exist yet.

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/commands/pdf/wkhtmltopdf_checker.rb
module Jojo
  module Commands
    module Pdf
      class WkhtmltopdfChecker
        class WkhtmltopdfNotFoundError < StandardError; end

        def self.available?
          system("which wkhtmltopdf > /dev/null 2>&1")
        end

        def self.version
          return nil unless available?

          output = `wkhtmltopdf --version 2>/dev/null`.lines.first
          return nil unless output

          output[/wkhtmltopdf ([\d.]+)/, 1]
        end

        def self.check!
          return true if available?

          raise WkhtmltopdfNotFoundError, <<~MSG
            wkhtmltopdf is not installed or not in PATH.

            Install wkhtmltopdf:
              macOS:   brew install --cask wkhtmltopdf
              Linux:   apt-get install wkhtmltopdf  (or yum install wkhtmltopdf)
              Windows: https://wkhtmltopdf.org/downloads.html

            After installing, verify with: wkhtmltopdf --version
          MSG
        end
      end
    end
  end
end
```

**Step 4: Run tests to verify they pass**

```
./bin/test test/unit/commands/pdf/wkhtmltopdf_checker_test.rb
```

Expected: 5 tests, 0 failures.

**Step 5: Commit**

```bash
git add lib/jojo/commands/pdf/wkhtmltopdf_checker.rb \
        test/unit/commands/pdf/wkhtmltopdf_checker_test.rb
git commit -m "feat(pdf): add WkhtmltopdfChecker"
```

---

### Task 2: Add HTML paths to Application

**Files:**
- Modify: `lib/jojo/application.rb:22-23`
- Modify: `test/unit/application_test.rb` (after line 101)

**Step 1: Write the failing tests**

Add after the `test_returns_cover_letter_pdf_path` test in `test/unit/application_test.rb`:

```ruby
def test_returns_resume_html_path
  app = Jojo::Application.new("test-app")
  assert_equal "applications/test-app/resume.html", app.resume_html_path
end

def test_returns_cover_letter_html_path
  app = Jojo::Application.new("test-app")
  assert_equal "applications/test-app/cover_letter.html", app.cover_letter_html_path
end
```

**Step 2: Run tests to verify they fail**

```
./bin/test test/unit/application_test.rb
```

Expected: `NoMethodError: undefined method 'resume_html_path'`

**Step 3: Write minimal implementation**

Add these two lines to `lib/jojo/application.rb` after `cover_letter_pdf_path`:

```ruby
def resume_html_path = File.join(base_path, "resume.html")
def cover_letter_html_path = File.join(base_path, "cover_letter.html")
```

**Step 4: Run tests to verify they pass**

```
./bin/test test/unit/application_test.rb
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/jojo/application.rb test/unit/application_test.rb
git commit -m "feat(pdf): add resume_html_path and cover_letter_html_path to Application"
```

---

### Task 3: Add pdf-stylesheet.css

**Files:**
- Create: `templates/pdf-stylesheet.css`

No tests required — this is a static asset.

**Step 1: Copy the stylesheet from mdresume**

```bash
cp ~/projects/mdresume/resume-stylesheet.css templates/pdf-stylesheet.css
```

**Step 2: Commit**

```bash
git add templates/pdf-stylesheet.css
git commit -m "feat(pdf): add pdf-stylesheet.css (copied from mdresume)"
```

---

### Task 4: Update Converter to two-step pipeline

**Files:**
- Modify: `lib/jojo/commands/pdf/converter.rb`
- Modify: `test/unit/commands/pdf/converter_test.rb`

**Step 1: Replace the converter tests**

Replace the full contents of `test/unit/commands/pdf/converter_test.rb`:

```ruby
# test/unit/commands/pdf/converter_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/converter"
require_relative "../../../../lib/jojo/application"

class Jojo::Commands::Pdf::ConverterTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-employer")
    @application.instance_variable_set(:@base_path, @tmpdir)
  end

  # -- generate_resume_pdf --

  def test_generate_resume_pdf_creates_html_and_pdf_files
    File.write(@application.resume_path, "# My Resume\n\nContent here")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      FileUtils.touch(@application.resume_html_path) if call_count == 1
      FileUtils.touch(@application.resume_pdf_path)  if call_count == 2
      true
    }) do
      generator.generate_resume_pdf
      assert File.exist?(@application.resume_html_path)
      assert File.exist?(@application.resume_pdf_path)
    end
  end

  def test_generate_resume_pdf_raises_error_if_markdown_missing
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    error = assert_raises(Jojo::Commands::Pdf::Converter::SourceFileNotFoundError) do
      generator.generate_resume_pdf
    end

    assert_includes error.message, "resume.md not found"
  end

  def test_generate_resume_pdf_raises_pandoc_error_if_pandoc_fails
    File.write(@application.resume_path, "# My Resume")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    generator.stub(:system, false) do
      assert_raises(Jojo::Commands::Pdf::Converter::PandocExecutionError) do
        generator.generate_resume_pdf
      end
    end
  end

  def test_generate_resume_pdf_raises_wkhtmltopdf_error_if_wkhtmltopdf_fails
    File.write(@application.resume_path, "# My Resume")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      call_count == 1  # true on first call (pandoc), false on second (wkhtmltopdf)
    }) do
      assert_raises(Jojo::Commands::Pdf::Converter::WkhtmltopdfExecutionError) do
        generator.generate_resume_pdf
      end
    end
  end

  # -- generate_cover_letter_pdf --

  def test_generate_cover_letter_pdf_creates_html_and_pdf_files
    File.write(@application.cover_letter_path, "# Cover Letter\n\nContent here")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      FileUtils.touch(@application.cover_letter_html_path) if call_count == 1
      FileUtils.touch(@application.cover_letter_pdf_path)  if call_count == 2
      true
    }) do
      generator.generate_cover_letter_pdf
      assert File.exist?(@application.cover_letter_html_path)
      assert File.exist?(@application.cover_letter_pdf_path)
    end
  end

  def test_generate_cover_letter_pdf_raises_error_if_markdown_missing
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    error = assert_raises(Jojo::Commands::Pdf::Converter::SourceFileNotFoundError) do
      generator.generate_cover_letter_pdf
    end

    assert_includes error.message, "cover letter.md not found"
  end

  # -- generate_all --

  def test_generate_all_creates_html_and_pdf_for_both_documents
    File.write(@application.resume_path, "# Resume")
    File.write(@application.cover_letter_path, "# Cover Letter")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      case call_count
      when 1 then FileUtils.touch(@application.resume_html_path)
      when 2 then FileUtils.touch(@application.resume_pdf_path)
      when 3 then FileUtils.touch(@application.cover_letter_html_path)
      when 4 then FileUtils.touch(@application.cover_letter_pdf_path)
      end
      true
    }) do
      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:check!, true) do
          result = generator.generate_all
          assert_equal 2, result[:generated].length
          assert_includes result[:generated], :resume
          assert_includes result[:generated], :cover_letter
        end
      end
    end
  end

  def test_generate_all_skips_missing_files
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
      Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:check!, true) do
        result = generator.generate_all
        assert_empty result[:generated]
        assert_equal 2, result[:skipped].length
      end
    end
  end

  # -- verbose mode --

  def test_verbose_mode_outputs_both_pandoc_and_wkhtmltopdf_commands
    File.write(@application.resume_path, "# Resume")
    output = StringIO.new
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: true, output: output)

    generator.stub(:system, true) do
      generator.generate_resume_pdf
      assert_includes output.string, "pandoc"
      assert_includes output.string, "wkhtmltopdf"
    end
  end
end
```

**Step 2: Run tests to verify they fail**

```
./bin/test test/unit/commands/pdf/converter_test.rb
```

Expected: failures referencing missing methods (`resume_html_path`, `WkhtmltopdfChecker`, `WkhtmltopdfExecutionError`, etc.).

**Step 3: Replace the converter implementation**

Replace the full contents of `lib/jojo/commands/pdf/converter.rb`:

```ruby
# lib/jojo/commands/pdf/converter.rb
require_relative "pandoc_checker"
require_relative "wkhtmltopdf_checker"

module Jojo
  module Commands
    module Pdf
      class Converter
        class SourceFileNotFoundError < StandardError; end
        class PandocExecutionError < StandardError; end
        class WkhtmltopdfExecutionError < StandardError; end

        CSS_PATH = File.expand_path("../../../../templates/pdf-stylesheet.css", __dir__)

        attr_reader :application, :verbose, :output

        def initialize(application, verbose: false, output: $stdout)
          @application = application
          @verbose = verbose
          @output = output
        end

        def generate_all
          PandocChecker.check!
          WkhtmltopdfChecker.check!

          results = {generated: [], skipped: []}

          if File.exist?(application.resume_path)
            generate_resume_pdf
            results[:generated] << :resume
          else
            results[:skipped] << :resume
          end

          if File.exist?(application.cover_letter_path)
            generate_cover_letter_pdf
            results[:generated] << :cover_letter
          else
            results[:skipped] << :cover_letter
          end

          results
        end

        def generate_resume_pdf
          generate_html_and_pdf(
            source: application.resume_path,
            html_output: application.resume_html_path,
            pdf_output: application.resume_pdf_path,
            document_type: "resume"
          )
        end

        def generate_cover_letter_pdf
          generate_html_and_pdf(
            source: application.cover_letter_path,
            html_output: application.cover_letter_html_path,
            pdf_output: application.cover_letter_pdf_path,
            document_type: "cover letter"
          )
        end

        private

        def generate_html_and_pdf(source:, html_output:, pdf_output:, document_type:)
          unless File.exist?(source)
            raise SourceFileNotFoundError, "#{document_type}.md not found at #{source}"
          end

          FileUtils.mkdir_p(File.dirname(pdf_output))

          html_cmd = build_pandoc_html_command(source, html_output)
          log_verbose("Generating HTML: #{html_cmd}")

          unless system(html_cmd)
            raise PandocExecutionError, "Pandoc failed to generate HTML for #{document_type}"
          end

          pdf_cmd = build_wkhtmltopdf_command(html_output, pdf_output)
          log_verbose("Generating PDF: #{pdf_cmd}")

          unless system(pdf_cmd)
            raise WkhtmltopdfExecutionError, "wkhtmltopdf failed to generate PDF for #{document_type}"
          end

          pdf_output
        end

        def build_pandoc_html_command(source, html_output)
          [
            "pandoc",
            escape_path(source),
            "-f", "markdown",
            "-t", "html",
            "--embed-resources",
            "--standalone",
            "-c", escape_path(CSS_PATH),
            "-o", escape_path(html_output)
          ].join(" ")
        end

        def build_wkhtmltopdf_command(html_input, pdf_output)
          [
            "wkhtmltopdf",
            escape_path(html_input),
            escape_path(pdf_output)
          ].join(" ")
        end

        def escape_path(path)
          "\"#{path}\""
        end

        def log_verbose(message)
          output.puts message if verbose
        end
      end
    end
  end
end
```

**Step 4: Run tests to verify they pass**

```
./bin/test test/unit/commands/pdf/converter_test.rb
```

Expected: all tests pass.

**Step 5: Run full test suite**

```
./bin/test
```

Expected: no regressions.

**Step 6: Commit**

```bash
git add lib/jojo/commands/pdf/converter.rb \
        test/unit/commands/pdf/converter_test.rb
git commit -m "feat(pdf): implement two-step pandoc→HTML + wkhtmltopdf→PDF pipeline"
```

---

### Task 5: Update command.rb reporting and error handling

**Files:**
- Modify: `lib/jojo/commands/pdf/command.rb`
- Modify: `test/unit/commands/pdf/command_test.rb`

**Step 1: Update the expected messages in command_test.rb**

In `test_reports_generated_pdfs`, change:
```ruby
@mock_cli.expect(:say, nil, ["Resume PDF generated", :green])
@mock_cli.expect(:say, nil, ["Cover_letter PDF generated", :green])
```
to:
```ruby
@mock_cli.expect(:say, nil, ["Resume HTML and PDF generated", :green])
@mock_cli.expect(:say, nil, ["Cover_letter HTML and PDF generated", :green])
```

In `test_reports_skipped_pdfs`, change:
```ruby
@mock_cli.expect(:say, nil, ["Resume PDF generated", :green])
```
to:
```ruby
@mock_cli.expect(:say, nil, ["Resume HTML and PDF generated", :green])
```

Then add a new test for `WkhtmltopdfNotFoundError` after `test_handles_pandoc_not_found_error`:

```ruby
def test_handles_wkhtmltopdf_not_found_error
  setup_error_recovery_mocks

  @mock_converter.expect(:generate_all, nil) do
    raise Jojo::Commands::Pdf::WkhtmltopdfChecker::WkhtmltopdfNotFoundError, "wkhtmltopdf is not installed"
  end
  @mock_status_logger.expect(:log, nil, [], step: :pdf, status: "failed", error: "wkhtmltopdf is not installed")

  @mock_cli.expect(:say, nil, [String, :green])
  @mock_cli.expect(:say, nil, ["wkhtmltopdf is not installed", :red])

  command = Jojo::Commands::Pdf::Command.new(
    @mock_cli,
    slug: "acme-corp",
    application: @mock_application,
    converter: @mock_converter
  )

  error = assert_raises(SystemExit) { command.execute }
  assert_equal 1, error.status
  @mock_cli.verify
end
```

**Step 2: Run tests to verify they fail**

```
./bin/test test/unit/commands/pdf/command_test.rb
```

Expected: failures on message mismatch and missing `WkhtmltopdfNotFoundError` rescue.

**Step 3: Update command.rb**

Add `require_relative "wkhtmltopdf_checker"` at line 4 (after `require_relative "pandoc_checker"`).

Change the generated reporting message from:
```ruby
say "#{doc_type.to_s.capitalize} PDF generated", :green
```
to:
```ruby
say "#{doc_type.to_s.capitalize} HTML and PDF generated", :green
```

Add a rescue for `WkhtmltopdfChecker::WkhtmltopdfNotFoundError` after the `PandocChecker::PandocNotFoundError` rescue block:

```ruby
rescue WkhtmltopdfChecker::WkhtmltopdfNotFoundError => e
  say e.message, :red
  begin
    log(step: :pdf, status: "failed", error: e.message)
  rescue
    # Ignore logging errors
  end
  exit 1
```

**Step 4: Run tests to verify they pass**

```
./bin/test test/unit/commands/pdf/command_test.rb
```

Expected: all tests pass.

**Step 5: Run full test suite**

```
./bin/test
```

Expected: no regressions.

**Step 6: Commit**

```bash
git add lib/jojo/commands/pdf/command.rb \
        test/unit/commands/pdf/command_test.rb
git commit -m "feat(pdf): update command reporting and error handling for two-step pipeline"
```

---

### Task 6: Remove deprecated LaTeX YAML front-matter from resume template

**Files:**
- Modify: `templates/default_resume.md.erb:1-11`

No tests needed — this is template cleanup with no logic change.

**Step 1: Remove the YAML front-matter block**

Delete lines 1–11 from `templates/default_resume.md.erb`. These are the lines from `---` through the closing `---` that set LaTeX-specific variables:

```
---
margin-left: 2cm
margin-right: 2cm
margin-top: 1cm
margin-bottom: 2cm
title: <%= name %>
description-meta: 'Resume for <%= name %>'
author:
- <%= name %>
subject: 'Resume'
---
```

The file should now begin with the `######` contact line.

**Step 2: Run the full test suite**

```
./bin/test
```

Expected: no failures.

**Step 3: Commit**

```bash
git add templates/default_resume.md.erb
git commit -m "chore(pdf): remove deprecated LaTeX YAML front-matter from resume template"
```

---

### Task 7: Update documentation

**Files:**
- Modify: `docs/commands/pdf.md`
- Modify: `docs/getting-started/installation.md`

**Step 1: Update docs/commands/pdf.md**

Replace the Outputs table with:

```markdown
## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/resume.html` | Resume as standalone HTML (CSS embedded) |
| `applications/<slug>/resume.pdf` | Resume as PDF |
| `applications/<slug>/cover_letter.html` | Cover letter as standalone HTML (CSS embedded) |
| `applications/<slug>/cover_letter.pdf` | Cover letter as PDF |
```

Replace the "Pandoc requirement" section with:

```markdown
## Requirements

PDF generation requires both [Pandoc](https://pandoc.org/) and [wkhtmltopdf](https://wkhtmltopdf.org/).

### Pandoc

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc

# Verify
pandoc --version
```

### wkhtmltopdf

```bash
# macOS
brew install --cask wkhtmltopdf

# Ubuntu/Debian
sudo apt-get install wkhtmltopdf

# Verify
wkhtmltopdf --version
```

{: .note }
If either tool is not installed, `jojo pdf` will warn and exit gracefully. When run as part of `jojo generate`, PDF generation is skipped with a warning but all other steps complete normally.
```

**Step 2: Update docs/getting-started/installation.md**

Replace the Pandoc prerequisite line:

```markdown
- **Pandoc** (optional) — For PDF generation: `brew install pandoc` on macOS
```

with:

```markdown
- **Pandoc** (optional) — For PDF generation: `brew install pandoc` on macOS
- **wkhtmltopdf** (optional) — For PDF generation: `brew install --cask wkhtmltopdf` on macOS
```

**Step 3: Commit**

```bash
git add docs/commands/pdf.md docs/getting-started/installation.md
git commit -m "docs(pdf): update docs to reflect two-step pipeline and wkhtmltopdf requirement"
```
