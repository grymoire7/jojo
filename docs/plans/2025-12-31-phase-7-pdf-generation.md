# Phase 7: PDF Generation and Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add PDF generation, improve logging with JSON format, enhance error handling and documentation

**Architecture:** Use Pandoc for PDF conversion, refactor StatusLogger to support both markdown and JSON formats with configuration, add comprehensive error handling and user-friendly messages throughout CLI.

**Tech Stack:** Pandoc (external dependency), Ruby stdlib (JSON), Thor CLI framework

---

## Task 1: Add Pandoc Dependency Check

**Files:**
- Create: `lib/jojo/pandoc_checker.rb`
- Test: `test/unit/pandoc_checker_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/pandoc_checker_test.rb
require "test_helper"
require "jojo/pandoc_checker"

class PandocCheckerTest < Minitest::Test
  def test_pandoc_available_returns_true_when_installed
    # Mock system call
    PandocChecker.stub :system, true do
      assert PandocChecker.available?
    end
  end

  def test_pandoc_available_returns_false_when_not_installed
    PandocChecker.stub :system, false do
      refute PandocChecker.available?
    end
  end

  def test_pandoc_version_returns_version_string
    version_output = "pandoc 3.1.11\n"
    PandocChecker.stub :`, version_output do
      assert_equal "3.1.11", PandocChecker.version
    end
  end

  def test_pandoc_version_returns_nil_when_not_installed
    PandocChecker.stub :`, "" do
      assert_nil PandocChecker.version
    end
  end

  def test_check_raises_error_when_not_installed
    PandocChecker.stub :available?, false do
      error = assert_raises(PandocChecker::PandocNotFoundError) do
        PandocChecker.check!
      end
      assert_includes error.message, "Pandoc is not installed"
    end
  end

  def test_check_returns_true_when_installed
    PandocChecker.stub :available?, true do
      assert PandocChecker.check!
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `./bin/jojo test --unit`
Expected: FAIL with "cannot load such file -- jojo/pandoc_checker"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/pandoc_checker.rb
module Jojo
  class PandocChecker
    class PandocNotFoundError < StandardError; end

    def self.available?
      system("which pandoc > /dev/null 2>&1")
    end

    def self.version
      return nil unless available?

      output = `pandoc --version 2>/dev/null`.lines.first
      return nil unless output

      output[/pandoc ([\d.]+)/, 1]
    end

    def self.check!
      return true if available?

      raise PandocNotFoundError, <<~MSG
        Pandoc is not installed or not in PATH.

        Install Pandoc:
          macOS:   brew install pandoc
          Linux:   apt-get install pandoc  (or yum install pandoc)
          Windows: https://pandoc.org/installing.html

        After installing, verify with: pandoc --version
      MSG
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `./bin/jojo test --unit`
Expected: PASS

**Step 5: Commit**

```bash
git add test/unit/pandoc_checker_test.rb lib/jojo/pandoc_checker.rb
git commit -m "feat: add Pandoc availability checker"
```

---

## Task 2: Create PDF Generator

**Files:**
- Create: `lib/jojo/pdf_generator.rb`
- Test: `test/unit/pdf_generator_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/pdf_generator_test.rb
require "test_helper"
require "jojo/pdf_generator"
require "jojo/employer"
require "tmpdir"

class PdfGeneratorTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @employer = Jojo::Employer.new("test-employer")
    @employer.instance_variable_set(:@base_path, @tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_generate_resume_pdf_creates_pdf_file
    # Create a markdown resume
    File.write(@employer.resume_path, "# My Resume\n\nContent here")

    generator = Jojo::PdfGenerator.new(@employer, verbose: false)

    # Mock Pandoc being available
    Jojo::PandocChecker.stub :check!, true do
      # Mock system call
      generator.stub :system, true do
        generator.generate_resume_pdf

        assert File.exist?(@employer.resume_pdf_path)
      end
    end
  end

  def test_generate_cover_letter_pdf_creates_pdf_file
    # Create a markdown cover letter
    File.write(@employer.cover_letter_path, "# Cover Letter\n\nContent here")

    generator = Jojo::PdfGenerator.new(@employer, verbose: false)

    Jojo::PandocChecker.stub :check!, true do
      generator.stub :system, true do
        generator.generate_cover_letter_pdf

        assert File.exist?(@employer.cover_letter_pdf_path)
      end
    end
  end

  def test_generate_all_creates_both_pdfs
    File.write(@employer.resume_path, "# Resume")
    File.write(@employer.cover_letter_path, "# Cover Letter")

    generator = Jojo::PdfGenerator.new(@employer, verbose: false)

    Jojo::PandocChecker.stub :check!, true do
      generator.stub :system, true do
        result = generator.generate_all

        assert_equal 2, result[:generated].length
        assert_includes result[:generated], :resume
        assert_includes result[:generated], :cover_letter
      end
    end
  end

  def test_generate_all_skips_missing_files
    # Don't create any files

    generator = Jojo::PdfGenerator.new(@employer, verbose: false)

    result = generator.generate_all

    assert_empty result[:generated]
    assert_equal 2, result[:skipped].length
  end

  def test_generate_resume_raises_error_if_markdown_missing
    generator = Jojo::PdfGenerator.new(@employer, verbose: false)

    error = assert_raises(Jojo::PdfGenerator::SourceFileNotFoundError) do
      generator.generate_resume_pdf
    end

    assert_includes error.message, "resume.md not found"
  end

  def test_verbose_mode_outputs_pandoc_command
    File.write(@employer.resume_path, "# Resume")

    output = StringIO.new
    generator = Jojo::PdfGenerator.new(@employer, verbose: true, output: output)

    Jojo::PandocChecker.stub :check!, true do
      generator.stub :system, true do
        generator.generate_resume_pdf

        assert_includes output.string, "pandoc"
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `./bin/jojo test --unit`
Expected: FAIL with "cannot load such file -- jojo/pdf_generator"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/pdf_generator.rb
require_relative "pandoc_checker"

module Jojo
  class PdfGenerator
    class SourceFileNotFoundError < StandardError; end
    class PandocExecutionError < StandardError; end

    attr_reader :employer, :verbose, :output

    def initialize(employer, verbose: false, output: $stdout)
      @employer = employer
      @verbose = verbose
      @output = output
    end

    def generate_all
      PandocChecker.check!

      results = {generated: [], skipped: []}

      # Generate resume PDF
      if File.exist?(employer.resume_path)
        generate_resume_pdf
        results[:generated] << :resume
      else
        results[:skipped] << :resume
      end

      # Generate cover letter PDF
      if File.exist?(employer.cover_letter_path)
        generate_cover_letter_pdf
        results[:generated] << :cover_letter
      else
        results[:skipped] << :cover_letter
      end

      results
    end

    def generate_resume_pdf
      generate_pdf(
        source: employer.resume_path,
        output: employer.resume_pdf_path,
        document_type: "resume"
      )
    end

    def generate_cover_letter_pdf
      generate_pdf(
        source: employer.cover_letter_path,
        output: employer.cover_letter_pdf_path,
        document_type: "cover letter"
      )
    end

    private

    def generate_pdf(source:, output:, document_type:)
      unless File.exist?(source)
        raise SourceFileNotFoundError, "#{document_type}.md not found at #{source}"
      end

      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(output))

      # Build Pandoc command
      cmd = build_pandoc_command(source, output)

      log_verbose("Generating PDF: #{cmd}") if verbose

      success = system(cmd)

      unless success
        raise PandocExecutionError, "Pandoc failed to generate PDF for #{document_type}"
      end

      output
    end

    def build_pandoc_command(source, output)
      [
        "pandoc",
        escape_path(source),
        "-o", escape_path(output),
        "--pdf-engine=pdflatex",
        "-V", "geometry:margin=1in",
        "-V", "fontsize=11pt"
      ].join(" ")
    end

    def escape_path(path)
      # Escape spaces and special characters for shell
      "\"#{path}\""
    end

    def log_verbose(message)
      output.puts message if verbose
    end
  end
end
```

**Step 4: Add PDF path methods to Employer class**

```ruby
# In lib/jojo/employer.rb, add these methods:

def resume_pdf_path
  File.join(base_path, "resume.pdf")
end

def cover_letter_pdf_path
  File.join(base_path, "cover_letter.pdf")
end
```

**Step 5: Run test to verify it passes**

Run: `./bin/jojo test --unit`
Expected: PASS

**Step 6: Commit**

```bash
git add test/unit/pdf_generator_test.rb lib/jojo/pdf_generator.rb lib/jojo/employer.rb
git commit -m "feat: add PDF generator with Pandoc"
```

---

## Task 3: Refactor StatusLogger to Support JSON Format

**Files:**
- Modify: `lib/jojo/status_logger.rb`
- Modify: `lib/jojo/config.rb`
- Test: `test/unit/status_logger_test.rb`

**Step 1: Update existing tests and add new ones**

```ruby
# test/unit/status_logger_test.rb
require "test_helper"
require "jojo/status_logger"
require "jojo/employer"
require "jojo/config"
require "tmpdir"
require "json"

class StatusLoggerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @employer = Jojo::Employer.new("test-employer")
    @employer.instance_variable_set(:@base_path, @tmpdir)

    # Create a test config
    @config_path = File.join(@tmpdir, "config.yml")
    File.write(@config_path, "seeker_name: Test User\n")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_log_creates_markdown_entry_by_default
    logger = Jojo::StatusLogger.new(@employer)
    logger.log("Test message")

    log_content = File.read(@employer.status_log_path)
    assert_includes log_content, "Test message"
    assert_match(/\*\*\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\*\*/, log_content)
  end

  def test_log_creates_json_entry_when_configured
    # Create config with JSON format
    config_content = <<~YAML
      seeker_name: Test User
      status_log_format: json
    YAML
    File.write(@config_path, config_content)

    config = Jojo::Config.new(@config_path)
    logger = Jojo::StatusLogger.new(@employer, config: config)

    logger.log("Test message")

    log_content = File.read(@employer.status_log_path)
    entry = JSON.parse(log_content.lines.first)

    assert_equal "Test message", entry["message"]
    assert entry["timestamp"]
  end

  def test_log_step_with_metadata_markdown_format
    logger = Jojo::StatusLogger.new(@employer)
    logger.log_step("Test Step", tokens: 1000, status: "complete")

    log_content = File.read(@employer.status_log_path)
    assert_includes log_content, "Test Step"
    assert_includes log_content, "Tokens: 1000"
    assert_includes log_content, "Status: complete"
  end

  def test_log_step_with_metadata_json_format
    config_content = <<~YAML
      seeker_name: Test User
      status_log_format: json
    YAML
    File.write(@config_path, config_content)

    config = Jojo::Config.new(@config_path)
    logger = Jojo::StatusLogger.new(@employer, config: config)

    logger.log_step("Test Step", tokens: 1000, status: "complete")

    log_content = File.read(@employer.status_log_path)
    entry = JSON.parse(log_content.lines.first)

    assert_equal "Test Step", entry["step"]
    assert_equal 1000, entry["tokens"]
    assert_equal "complete", entry["status"]
    assert entry["timestamp"]
  end

  def test_multiple_json_entries_are_valid_jsonl
    config_content = <<~YAML
      seeker_name: Test User
      status_log_format: json
    YAML
    File.write(@config_path, config_content)

    config = Jojo::Config.new(@config_path)
    logger = Jojo::StatusLogger.new(@employer, config: config)

    logger.log("First message")
    logger.log("Second message")
    logger.log_step("Step", status: "complete")

    log_content = File.read(@employer.status_log_path)
    lines = log_content.lines

    assert_equal 3, lines.length

    # Each line should be valid JSON
    lines.each do |line|
      assert JSON.parse(line)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `./bin/jojo test --unit`
Expected: FAIL - tests fail because StatusLogger doesn't support JSON format yet

**Step 3: Update Config class to support status_log_format**

```ruby
# In lib/jojo/config.rb, add this method:

def status_log_format
  @data.dig("status_log_format") || "markdown"
end
```

**Step 4: Refactor StatusLogger implementation**

```ruby
# lib/jojo/status_logger.rb
require "json"

module Jojo
  class StatusLogger
    attr_reader :employer, :config

    def initialize(employer, config: nil)
      @employer = employer
      @config = config
    end

    def log(message)
      entry = format == "json" ? json_entry(message) : markdown_entry(message)

      File.open(employer.status_log_path, "a") do |f|
        f.write(entry)
      end
    end

    def log_step(step_name, metadata = {})
      if format == "json"
        json_log_step(step_name, metadata)
      else
        markdown_log_step(step_name, metadata)
      end
    end

    private

    def format
      config&.status_log_format || "markdown"
    end

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    def markdown_entry(message)
      "**#{timestamp}**: #{message}\n\n"
    end

    def json_entry(message)
      {
        timestamp: timestamp,
        message: message
      }.to_json + "\n"
    end

    def markdown_log_step(step_name, metadata)
      message_parts = [step_name]

      metadata.each do |key, value|
        message_parts << "#{key.to_s.capitalize}: #{value}"
      end

      log(message_parts.join(" | "))
    end

    def json_log_step(step_name, metadata)
      entry = {
        timestamp: timestamp,
        step: step_name
      }.merge(metadata)

      File.open(employer.status_log_path, "a") do |f|
        f.write(entry.to_json + "\n")
      end
    end
  end
end
```

**Step 5: Run test to verify it passes**

Run: `./bin/jojo test --unit`
Expected: PASS

**Step 6: Update templates/config.yml.erb with new option**

```yaml
# Add this line to templates/config.yml.erb after voice_and_tone:

# Status log format: 'markdown' or 'json' (default: markdown)
# JSON format is better for parsing, markdown is more human-readable
status_log_format: markdown
```

**Step 7: Commit**

```bash
git add lib/jojo/status_logger.rb lib/jojo/config.rb test/unit/status_logger_test.rb templates/config.yml.erb
git commit -m "feat: add JSON format support to StatusLogger"
```

---

## Task 4: Update CLI to Pass Config to StatusLogger

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Update all StatusLogger instantiations**

Update each command that uses StatusLogger to pass the config:

```ruby
# In generate command (around line 189):
status_logger = Jojo::StatusLogger.new(employer, config: config)

# In research command (around line 315):
status_logger = Jojo::StatusLogger.new(employer, config: config)

# In resume command (around line 358):
status_logger = Jojo::StatusLogger.new(employer, config: config)

# In cover_letter command (around line 413):
status_logger = Jojo::StatusLogger.new(employer, config: config)

# In website command (around line 475):
status_logger = Jojo::StatusLogger.new(employer, config: config)
```

**Step 2: Run tests to verify no regressions**

Run: `./bin/jojo test --unit --integration`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "refactor: pass config to StatusLogger in all commands"
```

---

## Task 5: Add PDF Command to CLI

**Files:**
- Modify: `lib/jojo/cli.rb`
- Require: `lib/jojo/pdf_generator.rb` at top of file

**Step 1: Add require statement**

```ruby
# At top of lib/jojo/cli.rb, add:
require_relative "pdf_generator"
```

**Step 2: Add pdf command**

```ruby
# Add this command to lib/jojo/cli.rb after the website command:

desc "pdf", "Generate PDF versions of resume and cover letter"
long_desc <<~DESC, wrap: false
  Generate PDF files from markdown resume and cover letter.
  Requires Pandoc to be installed.

  Examples:
    jojo pdf -s acme-corp-senior-dev
    JOJO_EMPLOYER_SLUG=acme-corp jojo pdf
DESC
def pdf
  slug = resolve_slug
  employer = Jojo::Employer.new(slug)

  unless employer.artifacts_exist?
    say "✗ Employer '#{slug}' not found.", :red
    say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
    exit 1
  end

  config = Jojo::Config.new
  status_logger = Jojo::StatusLogger.new(employer, config: config)

  say "Generating PDFs for #{employer.company_name}...", :green

  begin
    generator = Jojo::PdfGenerator.new(employer, verbose: options[:verbose])
    results = generator.generate_all

    # Report what was generated
    results[:generated].each do |doc_type|
      say "✓ #{doc_type.to_s.capitalize} PDF generated", :green
    end

    # Report what was skipped
    results[:skipped].each do |doc_type|
      say "⚠ Skipped #{doc_type}: markdown file not found", :yellow
    end

    if results[:generated].any?
      status_logger.log_step("PDF Generation",
        status: "complete",
        generated: results[:generated].length)
      say "\n✓ PDF generation complete!", :green
    else
      say "\n⚠ No PDFs generated. Generate resume and cover letter first.", :yellow
      exit 1
    end
  rescue Jojo::PandocChecker::PandocNotFoundError => e
    say "✗ #{e.message}", :red
    status_logger.log_step("PDF Generation", status: "failed", error: "Pandoc not installed")
    exit 1
  rescue => e
    say "✗ Error generating PDFs: #{e.message}", :red
    status_logger.log_step("PDF Generation", status: "failed", error: e.message)
    exit 1
  end
end
```

**Step 3: Test the command manually**

Run: `./bin/jojo help pdf`
Expected: Shows help for pdf command

**Step 4: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add pdf command to generate PDF files"
```

---

## Task 6: Integrate PDF Generation into Generate Workflow

**Files:**
- Modify: `lib/jojo/cli.rb` (generate command)

**Step 1: Add PDF generation to generate command**

```ruby
# In the generate command, after website generation and before final success message:

# Generate PDFs
begin
  generator = Jojo::PdfGenerator.new(employer, verbose: options[:verbose])
  results = generator.generate_all

  if results[:generated].any?
    results[:generated].each do |doc_type|
      say "✓ #{doc_type.to_s.capitalize} PDF generated", :green
    end

    status_logger.log_step("PDF Generation",
      status: "complete",
      generated: results[:generated].length)
  else
    say "⚠ Warning: No PDFs generated (markdown files not found)", :yellow
  end
rescue Jojo::PandocChecker::PandocNotFoundError => e
  say "⚠ Warning: Skipping PDF generation - #{e.message.lines.first.strip}", :yellow
  status_logger.log_step("PDF Generation", status: "skipped", reason: "Pandoc not installed")
rescue => e
  say "⚠ Warning: PDF generation failed - #{e.message}", :yellow
  status_logger.log_step("PDF Generation", status: "failed", error: e.message)
  # Don't exit - PDFs are optional
end
```

**Step 2: Test with real workflow**

Run: `./bin/jojo generate -s test-employer` (after setting up test data)
Expected: Generates all files including PDFs if Pandoc is installed

**Step 3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: integrate PDF generation into generate workflow"
```

---

## Task 7: Enhance Verbose Logging Throughout

**Files:**
- Modify: `lib/jojo/generators/*.rb` (all generators)

**Step 1: Add verbose logging to ResearchGenerator**

```ruby
# In lib/jojo/generators/research_generator.rb, add verbose output:

def generate
  log_verbose "Starting research generation for #{employer.company_name}"

  # ... existing code ...

  if search_results
    log_verbose "Received #{search_results.length} search results"
  end

  log_verbose "Building research prompt (#{prompt.length} characters)"
  log_verbose "Calling AI for research generation..."

  research = ai_client.generate_text(prompt)

  log_verbose "Received research (#{research.length} characters)"
  log_verbose "Saving to #{employer.research_path}"

  # ... rest of existing code ...
end

private

def log_verbose(message)
  return unless @verbose
  puts "[Research] #{message}"
end
```

**Step 2: Add verbose logging to ResumeGenerator**

```ruby
# In lib/jojo/generators/resume_generator.rb, add similar verbose logging:

def generate
  log_verbose "Starting resume generation for #{employer.company_name}"

  # ... add verbose logging at key steps ...

  log_verbose "Loading generic resume from inputs/"
  log_verbose "Loading job description and research"
  log_verbose "Building resume prompt (#{prompt.length} characters)"
  log_verbose "Calling AI for resume generation..."
  log_verbose "Received resume (#{resume.length} characters)"
  log_verbose "Saving to #{employer.resume_path}"
end

private

def log_verbose(message)
  return unless @verbose
  puts "[Resume] #{message}"
end
```

**Step 3: Add verbose logging to CoverLetterGenerator**

```ruby
# In lib/jojo/generators/cover_letter_generator.rb:

def generate
  log_verbose "Starting cover letter generation for #{employer.company_name}"
  # ... similar pattern ...
end

private

def log_verbose(message)
  return unless @verbose
  puts "[CoverLetter] #{message}"
end
```

**Step 4: Add verbose logging to WebsiteGenerator**

```ruby
# In lib/jojo/generators/website_generator.rb:

def generate
  log_verbose "Starting website generation for #{employer.company_name}"
  log_verbose "Using template: #{template}"
  # ... similar pattern ...
end

private

def log_verbose(message)
  return unless @verbose
  puts "[Website] #{message}"
end
```

**Step 5: Test verbose mode**

Run: `./bin/jojo generate -s test-employer --verbose`
Expected: Detailed output showing each step

**Step 6: Commit**

```bash
git add lib/jojo/generators/*.rb
git commit -m "feat: add comprehensive verbose logging to all generators"
```

---

## Task 8: Improve Error Messages and Handling

**Files:**
- Modify: `lib/jojo/ai_client.rb`
- Modify: `lib/jojo/job_description_processor.rb`

**Step 1: Enhance AIClient error handling**

```ruby
# In lib/jojo/ai_client.rb, improve error messages:

def generate_text(prompt)
  log_verbose "Generating text with #{text_generation_ai} (#{prompt.length} chars)"

  begin
    response = llm_client.chat(
      messages: [{role: "user", content: prompt}],
      model: text_generation_ai
    )

    @total_tokens_used += response.dig("usage", "total_tokens") || 0
    response.dig("choices", 0, "message", "content")
  rescue => e
    raise AIError, "Text generation failed: #{e.message}\n\nThis might be due to:\n- Invalid API key\n- Network connection issues\n- Rate limiting\n- Model unavailability"
  end
end

def reason(prompt)
  log_verbose "Reasoning with #{reasoning_ai} (#{prompt.length} chars)"

  begin
    response = llm_client.chat(
      messages: [{role: "user", content: prompt}],
      model: reasoning_ai
    )

    @total_tokens_used += response.dig("usage", "total_tokens") || 0
    response.dig("choices", 0, "message", "content")
  rescue => e
    raise AIError, "Reasoning failed: #{e.message}\n\nThis might be due to:\n- Invalid API key\n- Network connection issues\n- Rate limiting\n- Model unavailability"
  end
end

class AIError < StandardError; end
```

**Step 2: Enhance JobDescriptionProcessor error handling**

```ruby
# In lib/jojo/job_description_processor.rb, add better error messages:

def process(job_source)
  # ... existing code ...

rescue URI::InvalidURIError => e
  raise ProcessingError, "Invalid URL: #{job_source}\n\nPlease provide a valid URL or file path."
rescue Errno::ENOENT => e
  raise ProcessingError, "File not found: #{job_source}\n\nPlease check the path and try again."
rescue => e
  raise ProcessingError, "Failed to process job description: #{e.message}"
end

class ProcessingError < StandardError; end
```

**Step 3: Update CLI to handle new error types gracefully**

No code changes needed - existing error handling in CLI will catch these.

**Step 4: Test error scenarios**

Test with:
- Invalid API key
- Missing file
- Invalid URL

Expected: Clear, helpful error messages

**Step 5: Commit**

```bash
git add lib/jojo/ai_client.rb lib/jojo/job_description_processor.rb
git commit -m "feat: improve error messages and handling"
```

---

## Task 9: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Expand README with comprehensive documentation**

```markdown
# Add these sections to README.md:

## Prerequisites

- Ruby 3.4.5 or higher
- Bundler (`gem install bundler`)
- **Pandoc** (for PDF generation)
  - macOS: `brew install pandoc`
  - Linux: `apt-get install pandoc` or `yum install pandoc`
  - Windows: https://pandoc.org/installing.html
- Anthropic API key (get one at https://console.anthropic.com/)

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd jojo
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Run setup:
   ```bash
   ./bin/jojo setup
   ```

4. Configure your inputs:
   - Copy `templates/generic_resume.md` to `inputs/` and customize
   - Copy `templates/recommendations.md` to `inputs/` and customize
   - Copy `templates/projects.yml` to `inputs/` and customize

## Quick Start

```bash
# Create new employer workspace and process job description
./bin/jojo new -s acme-corp-senior-dev -j job_description.txt

# Generate all application materials
./bin/jojo generate -s acme-corp-senior-dev

# Or run steps individually
./bin/jojo research -s acme-corp-senior-dev
./bin/jojo resume -s acme-corp-senior-dev
./bin/jojo cover_letter -s acme-corp-senior-dev
./bin/jojo website -s acme-corp-senior-dev
./bin/jojo pdf -s acme-corp-senior-dev
```

## Commands

| Command | Description |
|---------|-------------|
| `jojo setup` | Initial configuration setup |
| `jojo new -s SLUG -j JOB` | Create employer workspace |
| `jojo generate -s SLUG` | Generate all materials |
| `jojo research -s SLUG` | Generate company research |
| `jojo resume -s SLUG` | Generate tailored resume |
| `jojo cover_letter -s SLUG` | Generate cover letter |
| `jojo annotate -s SLUG` | Generate job description annotations |
| `jojo website -s SLUG` | Generate landing page |
| `jojo pdf -s SLUG` | Generate PDF files |
| `jojo test` | Run tests |
| `jojo version` | Show version |

## Configuration

Edit `config.yml` to customize:

```yaml
seeker_name: Your Name
base_url: https://yourwebsite.com  # For landing page links

reasoning_ai:
  service: anthropic
  model: sonnet  # or opus for better quality

text_generation_ai:
  service: anthropic
  model: haiku  # or sonnet for better quality

voice_and_tone: professional and friendly

# Status log format: 'markdown' or 'json'
status_log_format: markdown

# Web search configuration (optional but recommended)
search_provider:
  service: serper  # or tavily, searxng, duckduckgo

# Website CTA configuration
website:
  cta_text: "Let's talk!"
  cta_link: https://calendly.com/yourname
```

## Options

- `-v, --verbose`: Show detailed output
- `-q, --quiet`: Suppress output
- `-s, --slug SLUG`: Employer slug (or set JOJO_EMPLOYER_SLUG env var)
- `-t, --template NAME`: Website template (default: default)
- `--overwrite`: Overwrite existing files without prompting

## Environment Variables

```bash
# Set default employer slug
export JOJO_EMPLOYER_SLUG=acme-corp-senior-dev

# Now you can omit -s flag
jojo generate
jojo pdf
```

## Troubleshooting

### Pandoc not found

If you see "Pandoc is not installed", install it:

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc

# Verify installation
pandoc --version
```

### API errors

- Check your `ANTHROPIC_API_KEY` in `.env`
- Verify you have API credits at https://console.anthropic.com/
- Check your internet connection

### Tests failing

```bash
# Run different test categories
./bin/jojo test --unit           # Fast unit tests
./bin/jojo test --integration    # Integration tests
./bin/jojo test --all            # All tests
```

## Testing

Jojo uses a categorized test suite:

- **Unit tests** (`test/unit/`): Fast, no external dependencies
- **Integration tests** (`test/integration/`): Mocked external services
- **Service tests** (`test/service/`): Real API calls (cost money)

```bash
./bin/jojo test                    # Unit tests only (default, fast)
./bin/jojo test --all              # All tests and style checks
./bin/jojo test --standard         # Ruby style checks
./bin/jojo test --service          # Service tests (requires confirmation)
```

## Development

### Running locally

```bash
# Run a command
./bin/jojo [command] [options]

# Run with verbose output
./bin/jojo generate -s test-employer --verbose
```

### Code style

This project uses [Standard Ruby](https://github.com/standardrb/standard) for code formatting:

```bash
# Check style
bundle exec standardrb

# Auto-fix issues
bundle exec standardrb --fix

# Or use the test command
./bin/jojo test --standard
```

### Conventional Commits

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug"
git commit -m "docs: update README"
git commit -m "test: add test coverage"
git commit -m "refactor: improve code structure"
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README documentation"
```

---

## Task 10: Update Implementation Plan

**Files:**
- Modify: `docs/plans/implementation_plan.md`

**Step 1: Mark Phase 7 tasks as complete**

Update the Phase 7 section:

```markdown
## Phase 7: PDF Generation and Polish ✅

**Goal**: Convert markdown to PDF, finalize workflow

**Status**: COMPLETED

### Tasks:

- [x] Create `lib/jojo/pdf_generator.rb`
  - Use Pandoc to convert resume.md → resume.pdf
  - Use Pandoc to convert cover_letter.md → cover_letter.pdf
  - Handle Pandoc errors gracefully
  - Log to status_log

- [x] Create `lib/jojo/pandoc_checker.rb`
  - Check if Pandoc is installed
  - Provide helpful installation instructions
  - Validate Pandoc availability

- [x] Add PDF generation to `generate` workflow
  - Integrate into main generate command
  - Make PDF generation optional (don't fail if Pandoc missing)
  - Add standalone `pdf` command

- [x] Improve `status_log` formatting
  - Add JSON format support (JSONL)
  - Make format configurable in config.yml
  - Maintain backward compatibility with markdown format

- [x] Add verbose mode logging throughout
  - Enhanced output in all generators
  - Show progress and token usage
  - Help with debugging

- [x] Error handling and user-friendly messages
  - Better error messages for common failures
  - Helpful suggestions for resolution
  - Graceful degradation

- [x] Create comprehensive README.md updates
  - Installation instructions
  - Usage examples
  - Configuration guide
  - Troubleshooting section
  - Development guide

**Validation**: ✅ `./bin/jojo generate -s "Test Corp" -j test_job.txt` creates complete application package with PDFs. JSON logging works. Verbose mode provides detailed output. Error messages are clear and actionable.
```

**Step 2: Commit**

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 7 as complete in implementation plan"
```

---

## Plan Complete

Plan complete and saved to `docs/plans/2025-12-31-phase-7-pdf-generation.md`.

## Execution Options

**1. Subagent-Driven (this session)** - I dispatch a fresh subagent per task, review between tasks, fast iteration. Good for staying in this conversation and having oversight.

**2. Parallel Session (separate)** - Open new session with executing-plans skill, batch execution with checkpoints. Good for working independently while you do other things.

Which approach would you like to use?
