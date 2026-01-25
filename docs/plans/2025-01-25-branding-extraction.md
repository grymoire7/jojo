# Branding Statement Extraction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract branding statement generation from WebsiteGenerator into standalone `jojo branding` command.

**Architecture:** Create BrandingGenerator class mirroring FaqGenerator pattern. Modify WebsiteGenerator to read from `branding.md` file instead of calling AI. Update CLI with new `branding` command and modify `generate` to call it.

**Tech Stack:** Ruby, Thor CLI, Minitest

---

## Task 1: Add branding_path to Employer

**Files:**
- Modify: `lib/jojo/employer.rb:38` (after resume_path)
- Test: `test/unit/employer_test.rb`

**Step 1: Write the failing test**

Add to `test/unit/employer_test.rb`:

```ruby
it "returns branding_path" do
  employer = Jojo::Employer.new("test-company")
  _(employer.branding_path).must_equal "employers/test-company/branding.md"
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/employer_test.rb`
Expected: FAIL with "undefined method `branding_path'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/employer.rb` after `resume_path` method (line 38):

```ruby
def branding_path
  File.join(base_path, "branding.md")
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/employer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/employer.rb test/unit/employer_test.rb
git commit -m "feat(employer): add branding_path method"
```

---

## Task 2: Create BrandingGenerator with basic generate method

**Files:**
- Create: `lib/jojo/generators/branding_generator.rb`
- Create: `test/unit/generators/branding_generator_test.rb`

**Step 1: Write the failing test**

Create `test/unit/generators/branding_generator_test.rb`:

```ruby
require_relative "../../test_helper"
require_relative "../../../lib/jojo/employer"
require_relative "../../../lib/jojo/generators/branding_generator"

class BrandingGeneratorTestConfigStub
  attr_accessor :seeker_name, :voice_and_tone

  def initialize
    @seeker_name = "Jane Doe"
    @voice_and_tone = "professional and friendly"
  end
end

describe Jojo::Generators::BrandingGenerator do
  before do
    @employer = Jojo::Employer.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = BrandingGeneratorTestConfigStub.new
    @generator = Jojo::Generators::BrandingGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    File.write(@employer.job_description_path, "Senior Ruby Developer role...")
    File.write(@employer.resume_path, "# Jane Doe\n\nSenior Ruby developer...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates branding statement and saves to file" do
    expected_branding = "I'm a perfect fit for Acme Corp...\n\nMy experience aligns perfectly..."
    @ai_client.expect(:generate_text, expected_branding, [String])

    result = @generator.generate

    _(result).must_equal expected_branding
    _(File.exist?(@employer.branding_path)).must_equal true
    _(File.read(@employer.branding_path)).must_equal expected_branding

    @ai_client.verify
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/generators/branding_generator_test.rb`
Expected: FAIL with "cannot load such file -- branding_generator"

**Step 3: Write minimal implementation**

Create `lib/jojo/generators/branding_generator.rb`:

```ruby
require "yaml"
require_relative "../prompts/website_prompt"

module Jojo
  module Generators
    class BrandingGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        log "Gathering inputs for branding statement..."
        inputs = gather_inputs

        log "Generating branding statement using AI..."
        branding_statement = generate_branding_statement(inputs)

        log "Saving branding statement to #{employer.branding_path}..."
        save_branding(branding_statement)

        log "Branding statement generation complete!"
        branding_statement
      end

      private

      def gather_inputs
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        unless File.exist?(employer.resume_path)
          raise "Resume not found at #{employer.resume_path}. Run 'jojo resume' first."
        end
        resume = File.read(employer.resume_path)

        research = read_research
        job_details = read_job_details

        {
          job_description: job_description,
          resume: resume,
          research: research,
          job_details: job_details,
          company_name: employer.company_name
        }
      end

      def read_research
        return nil unless File.exist?(employer.research_path)
        log "Warning: Research not found, branding will be less targeted" unless File.exist?(employer.research_path)
        File.read(employer.research_path)
      end

      def read_job_details
        return nil unless File.exist?(employer.job_details_path)
        YAML.load_file(employer.job_details_path)
      rescue => e
        log "Warning: Could not parse job details: #{e.message}"
        nil
      end

      def generate_branding_statement(inputs)
        prompt = Prompts::Website.generate_branding_statement(
          job_description: inputs[:job_description],
          resume: inputs[:resume],
          company_name: inputs[:company_name],
          seeker_name: config.seeker_name,
          voice_and_tone: config.voice_and_tone,
          research: inputs[:research],
          job_details: inputs[:job_details]
        )

        ai_client.generate_text(prompt)
      end

      def save_branding(branding_statement)
        File.write(employer.branding_path, branding_statement)
      end

      def log(message)
        puts "  [BrandingGenerator] #{message}" if verbose
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/generators/branding_generator_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/generators/branding_generator.rb test/unit/generators/branding_generator_test.rb
git commit -m "feat(branding): add BrandingGenerator class"
```

---

## Task 3: Add error handling tests for BrandingGenerator

**Files:**
- Modify: `test/unit/generators/branding_generator_test.rb`

**Step 1: Add tests for error cases**

Add to `test/unit/generators/branding_generator_test.rb`:

```ruby
it "raises error when job description missing" do
  FileUtils.rm_f(@employer.job_description_path)

  _ { @generator.generate }.must_raise RuntimeError
end

it "raises error when resume missing" do
  FileUtils.rm_f(@employer.resume_path)

  _ { @generator.generate }.must_raise RuntimeError
end

it "handles missing research gracefully" do
  FileUtils.rm_f(@employer.research_path)

  expected_branding = "Branding without research..."
  @ai_client.expect(:generate_text, expected_branding, [String])

  result = @generator.generate
  _(result).must_equal expected_branding

  @ai_client.verify
end

it "handles missing job_details gracefully" do
  FileUtils.rm_f(@employer.job_details_path)

  expected_branding = "Branding without job details..."
  @ai_client.expect(:generate_text, expected_branding, [String])

  result = @generator.generate
  _(result).must_equal expected_branding

  @ai_client.verify
end
```

**Step 2: Run tests to verify they pass**

Run: `bundle exec ruby -Ilib:test test/unit/generators/branding_generator_test.rb`
Expected: PASS (implementation already handles these cases)

**Step 3: Commit**

```bash
git add test/unit/generators/branding_generator_test.rb
git commit -m "test(branding): add error handling tests"
```

---

## Task 4: Add CLI branding command

**Files:**
- Modify: `lib/jojo/cli.rb`
- Create: `test/unit/cli_branding_test.rb`

**Step 1: Write the failing test**

Create `test/unit/cli_branding_test.rb`:

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/cli"

describe "jojo branding command" do
  before do
    @employer = Jojo::Employer.new("test-branding")
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    File.write(@employer.job_description_path, "Job description content")
    File.write(@employer.resume_path, "Resume content")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "fails when employer does not exist" do
    FileUtils.rm_rf(@employer.base_path)

    output, status = capture_subprocess_io do
      system("bundle exec ruby -Ilib -e \"require 'jojo/cli'; Jojo::CLI.start(['branding', '-s', 'test-branding'])\"")
    end

    _(status.success?).must_equal false
    _(output).must_include "not found"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/cli_branding_test.rb`
Expected: FAIL with "Could not find command \"branding\""

**Step 3: Write minimal implementation**

Add to `lib/jojo/cli.rb` after `cover_letter` command (around line 497):

```ruby
desc "branding", "Generate branding statement only"
long_desc <<~DESC, wrap: false
  Generate a branding statement for a specific employer.
  Requires that you've already run 'jojo new' and 'jojo resume' first.

  Examples:
    jojo branding -s acme-corp-senior-dev
    JOJO_EMPLOYER_SLUG=acme-corp jojo branding
DESC
def branding
  slug = resolve_slug
  employer = Jojo::Employer.new(slug)

  unless employer.artifacts_exist?
    say "✗ Employer '#{slug}' not found.", :red
    say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
    exit 1
  end

  # Check for existing branding.md and --overwrite flag
  if File.exist?(employer.branding_path) && !options[:overwrite]
    say "✗ Branding statement already exists at #{employer.branding_path}", :red
    say "  Use --overwrite to regenerate.", :yellow
    exit 1
  end

  config = Jojo::Config.new
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
  status_logger = Jojo::StatusLogger.new(employer)

  say "Generating branding statement for #{employer.company_name}...", :green

  # Check that resume has been generated (REQUIRED)
  unless File.exist?(employer.resume_path)
    say "✗ Resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
    exit 1
  end

  begin
    require_relative "generators/branding_generator"
    generator = Jojo::Generators::BrandingGenerator.new(
      employer,
      ai_client,
      config: config,
      verbose: options[:verbose]
    )
    generator.generate

    say "✓ Branding statement generated and saved to #{employer.branding_path}", :green

    status_logger.log_step("Branding Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete")

    say "\n✓ Branding complete!", :green
  rescue => e
    say "✗ Error generating branding statement: #{e.message}", :red
    status_logger.log_step("Branding Generation", status: "failed", error: e.message)
    exit 1
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/cli_branding_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb test/unit/cli_branding_test.rb
git commit -m "feat(cli): add branding command"
```

---

## Task 5: Modify WebsiteGenerator to read branding from file

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`
- Modify: `test/unit/generators/website_generator_test.rb`

**Step 1: Write the failing test for missing branding.md**

Add to `test/unit/generators/website_generator_test.rb`:

```ruby
it "fails when branding.md is missing" do
  FileUtils.rm_f(@employer.branding_path)

  error = assert_raises(RuntimeError) do
    @generator.generate
  end

  _(error.message).must_include "branding.md not found"
  _(error.message).must_include "jojo branding"
end

it "fails when branding.md is empty" do
  File.write(@employer.branding_path, "")

  error = assert_raises(RuntimeError) do
    @generator.generate
  end

  _(error.message).must_include "branding.md not found"
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec ruby -Ilib:test test/unit/generators/website_generator_test.rb -n '/branding.md/'`
Expected: FAIL (current implementation generates branding inline)

**Step 3: Modify WebsiteGenerator implementation**

In `lib/jojo/generators/website_generator.rb`:

1. Remove `generate_branding_statement` method (lines 114-126)

2. Replace in `generate` method (line 29):
```ruby
# OLD:
log "Generating personalized branding statement using AI..."
branding_statement = generate_branding_statement(inputs)

# NEW:
log "Loading branding statement from file..."
branding_statement = load_branding_statement
```

3. Add new private method `load_branding_statement`:
```ruby
def load_branding_statement
  unless File.exist?(employer.branding_path) && !File.read(employer.branding_path).strip.empty?
    raise "branding.md not found for '#{employer.slug}'\nRun 'jojo branding -s #{employer.slug}' first to generate branding statement."
  end

  File.read(employer.branding_path)
end
```

4. Remove the `require_relative "../prompts/website_prompt"` line since it's no longer needed (line 5)

**Step 4: Update existing tests to create branding.md**

In `test/unit/generators/website_generator_test.rb`, add to `before` block:

```ruby
File.write(@employer.branding_path, "I'm a perfect fit for Acme Corp...\n\nMy experience aligns perfectly...")
```

Remove all `@ai_client.expect(:generate_text, ...)` lines and `@ai_client.verify` calls from all tests since WebsiteGenerator no longer calls AI.

**Step 5: Run all website generator tests**

Run: `bundle exec ruby -Ilib:test test/unit/generators/website_generator_test.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/website_generator.rb test/unit/generators/website_generator_test.rb
git commit -m "refactor(website): read branding from file instead of generating"
```

---

## Task 6: Update jojo generate to call branding first

**Files:**
- Modify: `lib/jojo/cli.rb` (generate method)

**Step 1: Modify generate command**

In `lib/jojo/cli.rb`, in the `generate` method, add branding generation after FAQ generation and before website generation (around line 283):

```ruby
# Generate branding statement
begin
  require_relative "generators/branding_generator"

  # Skip if branding exists and --overwrite not set
  if File.exist?(employer.branding_path) && !options[:overwrite]
    say "✓ Using existing branding statement", :green
  else
    generator = Jojo::Generators::BrandingGenerator.new(
      employer,
      ai_client,
      config: config,
      verbose: options[:verbose]
    )
    generator.generate

    say "✓ Branding statement generated and saved", :green
    status_logger.log_step("Branding Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete")
  end
rescue => e
  say "✗ Error generating branding statement: #{e.message}", :red
  status_logger.log_step("Branding Generation", status: "failed", error: e.message)
  exit 1
end
```

**Step 2: Run tests**

Run: `bundle exec ruby -Ilib:test test/unit/**/*_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat(cli): generate branding as part of jojo generate"
```

---

## Task 7: Run full test suite and verify

**Step 1: Run all tests**

Run: `bundle exec ruby -Ilib:test -e 'Dir.glob("test/unit/**/*_test.rb").each { |f| require f.sub(/^test\//, "") }'`
Expected: All tests PASS

**Step 2: Run Standard Ruby**

Run: `bundle exec standardrb`
Expected: No offenses

**Step 3: Manual verification**

```bash
# Test branding command standalone
jojo branding -s cybercoders

# Check file exists
cat employers/cybercoders/branding.md

# Test website regeneration (no API call)
jojo website -s cybercoders

# Verify no errors and website generated
```

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: cleanup after branding extraction"
```

---

## Summary of Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/jojo/employer.rb` | Modify | Add `branding_path` method |
| `lib/jojo/generators/branding_generator.rb` | Create | New generator class |
| `lib/jojo/generators/website_generator.rb` | Modify | Read branding from file, remove AI call |
| `lib/jojo/cli.rb` | Modify | Add `branding` command, update `generate` |
| `test/unit/employer_test.rb` | Modify | Add branding_path test |
| `test/unit/generators/branding_generator_test.rb` | Create | Tests for BrandingGenerator |
| `test/unit/generators/website_generator_test.rb` | Modify | Update to use branding.md fixture |
| `test/unit/cli_branding_test.rb` | Create | CLI command tests |
