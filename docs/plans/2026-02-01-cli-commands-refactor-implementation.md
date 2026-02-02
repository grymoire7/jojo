# CLI Commands Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor the 877-line `cli.rb` into self-contained command classes under `lib/jojo/commands/`, creating a thin CLI router and eliminating the circular dependency in interactive mode.

**Architecture:** Extract each CLI command into a `Commands::<CommandName>::Command` class inheriting from `Commands::Base`. The base class provides common patterns (slug resolution, validation, output helpers). Interactive mode uses `ConsoleOutput` adapter instead of `CLI.invoke()`.

**Tech Stack:** Ruby, Thor, Minitest, TTY gems (unchanged)

**Design Document:** `docs/plans/2026-02-01-cli-commands-refactor-design.md`

---

## Task 1: Create Commands::Base Class

**Files:**
- Create: `lib/jojo/commands/base.rb`
- Test: `test/unit/commands/base_test.rb`

**Step 1: Write the failing test**

Create test file with basic tests for the base class:

```ruby
# test/unit/commands/base_test.rb
require_relative "../../test_helper"
require_relative "../../../lib/jojo/commands/base"

describe Jojo::Commands::Base do
  before do
    @mock_cli = Minitest::Mock.new
  end

  describe "#initialize" do
    it "stores cli and options" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme", verbose: true)

      _(base.cli).must_equal @mock_cli
      _(base.options[:slug]).must_equal "acme"
      _(base.options[:verbose]).must_equal true
    end
  end

  describe "#execute" do
    it "raises NotImplementedError" do
      base = Jojo::Commands::Base.new(@mock_cli)

      _ { base.execute }.must_raise NotImplementedError
    end
  end

  describe "option accessors" do
    it "returns slug from options" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")
      _(base.send(:slug)).must_equal "acme-corp"
    end

    it "returns verbose? from options with default false" do
      base = Jojo::Commands::Base.new(@mock_cli)
      _(base.send(:verbose?)).must_equal false
    end

    it "returns overwrite? from options with default false" do
      base = Jojo::Commands::Base.new(@mock_cli)
      _(base.send(:overwrite?)).must_equal false
    end

    it "returns quiet? from options with default false" do
      base = Jojo::Commands::Base.new(@mock_cli)
      _(base.send(:quiet?)).must_equal false
    end
  end

  describe "output helpers" do
    it "delegates say to cli" do
      @mock_cli.expect(:say, nil, ["Hello", :green])
      base = Jojo::Commands::Base.new(@mock_cli)

      base.send(:say, "Hello", :green)

      @mock_cli.verify
    end

    it "delegates yes? to cli" do
      @mock_cli.expect(:yes?, true, ["Continue?"])
      base = Jojo::Commands::Base.new(@mock_cli)

      result = base.send(:yes?, "Continue?")

      _(result).must_equal true
      @mock_cli.verify
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: FAIL with "cannot load such file -- jojo/commands/base"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/commands/base.rb
module Jojo
  module Commands
    class Base
      attr_reader :cli, :options

      def initialize(cli, options = {})
        @cli = cli
        @options = options
      end

      def execute
        raise NotImplementedError, "Subclasses must implement #execute"
      end

      protected

      # Common options
      def slug = options[:slug]
      def verbose? = options[:verbose] || false
      def overwrite? = options[:overwrite] || false
      def quiet? = options[:quiet] || false

      # Output helpers (delegate to injected CLI)
      def say(message, color = nil) = cli.say(message, color)
      def yes?(prompt) = cli.yes?(prompt)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/base.rb test/unit/commands/base_test.rb
git commit -m "$(cat <<'EOF'
feat(commands): add Base class for command extraction

Introduces Commands::Base with common patterns:
- Option accessors (slug, verbose?, overwrite?, quiet?)
- Output delegation (say, yes?)
- Abstract execute method for subclasses
EOF
)"
```

---

## Task 2: Add Shared Setup to Commands::Base

**Files:**
- Modify: `lib/jojo/commands/base.rb`
- Modify: `test/unit/commands/base_test.rb`

**Step 1: Write the failing test**

Add tests for lazy-loaded shared objects:

```ruby
# Add to test/unit/commands/base_test.rb

describe "shared setup (lazy-loaded)" do
  before do
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Create minimal config
    File.write("config.yml", <<~YAML)
      seeker_name: "Test User"
      base_url: "https://example.com"
      reasoning_ai_service: openai
      reasoning_ai_model: gpt-4
      text_generation_ai_service: openai
      text_generation_ai_model: gpt-4
    YAML

    # Create employer directory
    FileUtils.mkdir_p("employers/acme-corp")
    File.write("employers/acme-corp/job_description.md", "Test job")
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  it "creates employer from slug" do
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    employer = base.send(:employer)

    _(employer).must_be_kind_of Jojo::Employer
    _(employer.slug).must_equal "acme-corp"
  end

  it "caches employer instance" do
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    employer1 = base.send(:employer)
    employer2 = base.send(:employer)

    _(employer1).must_be_same_as employer2
  end

  it "creates config" do
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    config = base.send(:config)

    _(config).must_be_kind_of Jojo::Config
  end

  it "creates status_logger for employer" do
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    logger = base.send(:status_logger)

    _(logger).must_be_kind_of Jojo::StatusLogger
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: FAIL with "undefined method `employer'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/commands/base.rb` in the protected section:

```ruby
# Add requires at top of file
require_relative "../employer"
require_relative "../config"
require_relative "../ai_client"
require_relative "../status_logger"

# Add in protected section:
      # Shared setup (lazy-loaded)
      def employer
        @employer ||= Jojo::Employer.new(slug)
      end

      def config
        @config ||= Jojo::Config.new
      end

      def ai_client
        @ai_client ||= Jojo::AIClient.new(config, verbose: verbose?)
      end

      def status_logger
        @status_logger ||= Jojo::StatusLogger.new(employer)
      end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/base.rb test/unit/commands/base_test.rb
git commit -m "$(cat <<'EOF'
feat(commands): add lazy-loaded shared setup to Base

Adds employer, config, ai_client, and status_logger
as lazy-loaded protected methods for command reuse.
EOF
)"
```

---

## Task 3: Add Validation Helpers to Commands::Base

**Files:**
- Modify: `lib/jojo/commands/base.rb`
- Modify: `test/unit/commands/base_test.rb`

**Step 1: Write the failing test**

Add tests for validation helpers:

```ruby
# Add to test/unit/commands/base_test.rb

describe "validation helpers" do
  before do
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
    FileUtils.mkdir_p("employers/acme-corp")
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  describe "#require_employer!" do
    it "does not exit when employer artifacts exist" do
      File.write("employers/acme-corp/job_description.md", "Test")
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      # Should not raise
      base.send(:require_employer!)
    end

    it "exits with message when employer not found" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "nonexistent")

      @mock_cli.expect(:say, nil, ["Employer 'nonexistent' not found.", :red])
      @mock_cli.expect(:say, nil, [String, :yellow])

      assert_raises(SystemExit) { base.send(:require_employer!) }
      @mock_cli.verify
    end
  end

  describe "#require_file!" do
    it "does not exit when file exists" do
      File.write("employers/acme-corp/test.txt", "content")
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      # Should not raise
      base.send(:require_file!, "employers/acme-corp/test.txt", "Test file")
    end

    it "exits with message when file missing" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      @mock_cli.expect(:say, nil, ["Test file not found at missing.txt", :red])

      assert_raises(SystemExit) do
        base.send(:require_file!, "missing.txt", "Test file")
      end
      @mock_cli.verify
    end

    it "shows suggestion when provided" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      @mock_cli.expect(:say, nil, [String, :red])
      @mock_cli.expect(:say, nil, ["  Run 'jojo setup' first", :yellow])

      assert_raises(SystemExit) do
        base.send(:require_file!, "missing.txt", "Config", suggestion: "Run 'jojo setup' first")
      end
      @mock_cli.verify
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: FAIL with "undefined method `require_employer!'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/commands/base.rb` protected section:

```ruby
      # Common validations
      def require_employer!
        return if employer.artifacts_exist?

        say "Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug}' to create it.", :yellow
        exit 1
      end

      def require_file!(path, description, suggestion: nil)
        return if File.exist?(path)

        say "#{description} not found at #{path}", :red
        say "  #{suggestion}", :yellow if suggestion
        exit 1
      end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/base.rb test/unit/commands/base_test.rb
git commit -m "$(cat <<'EOF'
feat(commands): add validation helpers to Base

Adds require_employer! and require_file! for common
validation patterns with consistent error messages.
EOF
)"
```

---

## Task 4: Create ConsoleOutput Adapter for Interactive Mode

**Files:**
- Create: `lib/jojo/commands/console_output.rb`
- Test: `test/unit/commands/console_output_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/commands/console_output_test.rb
require_relative "../../test_helper"
require_relative "../../../lib/jojo/commands/console_output"

describe Jojo::Commands::ConsoleOutput do
  describe "#say" do
    it "outputs message to stdout" do
      output = Jojo::Commands::ConsoleOutput.new

      assert_output("Hello\n") { output.say("Hello") }
    end

    it "ignores color parameter" do
      output = Jojo::Commands::ConsoleOutput.new

      assert_output("Hello\n") { output.say("Hello", :green) }
    end

    it "suppresses output when quiet" do
      output = Jojo::Commands::ConsoleOutput.new(quiet: true)

      assert_output("") { output.say("Hello") }
    end
  end

  describe "#yes?" do
    it "returns true for 'y' input" do
      output = Jojo::Commands::ConsoleOutput.new

      $stdin = StringIO.new("y\n")
      result = nil
      assert_output(/Continue\?/) { result = output.yes?("Continue?") }
      $stdin = STDIN

      _(result).must_equal true
    end

    it "returns true for 'yes' input" do
      output = Jojo::Commands::ConsoleOutput.new

      $stdin = StringIO.new("yes\n")
      result = nil
      assert_output(/Continue\?/) { result = output.yes?("Continue?") }
      $stdin = STDIN

      _(result).must_equal true
    end

    it "returns false for 'n' input" do
      output = Jojo::Commands::ConsoleOutput.new

      $stdin = StringIO.new("n\n")
      result = nil
      assert_output(/Continue\?/) { result = output.yes?("Continue?") }
      $stdin = STDIN

      _(result).must_equal false
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/console_output_test.rb`
Expected: FAIL with "cannot load such file"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/commands/console_output.rb
module Jojo
  module Commands
    class ConsoleOutput
      def initialize(quiet: false)
        @quiet = quiet
      end

      def say(message, _color = nil)
        puts message unless @quiet
      end

      def yes?(prompt)
        print "#{prompt} "
        response = $stdin.gets&.chomp&.downcase || ""
        response.start_with?("y")
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/console_output_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/console_output.rb test/unit/commands/console_output_test.rb
git commit -m "$(cat <<'EOF'
feat(commands): add ConsoleOutput adapter for interactive mode

Provides CLI-compatible interface without Thor dependency,
enabling commands to be called from interactive mode directly.
EOF
)"
```

---

## Task 5: Create Version Command

**Files:**
- Create: `lib/jojo/commands/version/command.rb`
- Test: `test/unit/commands/version/command_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/commands/version/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/version/command"

describe Jojo::Commands::Version::Command do
  before do
    @mock_cli = Minitest::Mock.new
  end

  it "inherits from Base" do
    _(Jojo::Commands::Version::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "outputs version string" do
    @mock_cli.expect(:say, nil, ["Jojo #{Jojo::VERSION}", :green])

    command = Jojo::Commands::Version::Command.new(@mock_cli)
    command.execute

    @mock_cli.verify
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/version/command_test.rb`
Expected: FAIL with "cannot load such file"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/commands/version/command.rb
require_relative "../base"

module Jojo
  module Commands
    module Version
      class Command < Base
        def execute
          say "Jojo #{Jojo::VERSION}", :green
        end
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/version/command_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/version/command.rb test/unit/commands/version/command_test.rb
git commit -m "$(cat <<'EOF'
feat(commands): extract version command to Commands::Version

First command extraction as proof of concept.
EOF
)"
```

---

## Task 6: Wire Version Command into CLI

**Files:**
- Modify: `lib/jojo/cli.rb`
- Test: Run existing `test/unit/cli_test.rb`

**Step 1: Verify existing test passes**

Run: `bundle exec ruby -Ilib:test test/unit/cli_test.rb`
Expected: PASS (baseline)

**Step 2: Update CLI to use Version command**

In `lib/jojo/cli.rb`, add require at top:

```ruby
require_relative "commands/version/command"
```

Replace the version method:

```ruby
    desc "version", "Show version"
    def version
      Commands::Version::Command.new(self, command_options).execute
    end
```

Add `command_options` private method if not present:

```ruby
    private

    def command_options
      {
        slug: options[:slug] || ENV["JOJO_EMPLOYER_SLUG"],
        verbose: options[:verbose],
        overwrite: options[:overwrite],
        quiet: options[:quiet]
      }
    end
```

**Step 3: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/cli_test.rb`
Expected: PASS

**Step 4: Manual verification**

Run: `./bin/jojo version`
Expected: Shows "Jojo 0.1.0" in green

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "$(cat <<'EOF'
refactor(cli): wire version command through Commands::Version

Adds command_options helper for option extraction.
EOF
)"
```

---

## Task 7: Create Annotate Command

**Files:**
- Create: `lib/jojo/commands/annotate/command.rb`
- Move: `lib/jojo/generators/annotation_generator.rb` -> `lib/jojo/commands/annotate/generator.rb`
- Move: `lib/jojo/prompts/annotation_prompt.rb` -> `lib/jojo/commands/annotate/prompt.rb`
- Test: `test/unit/commands/annotate/command_test.rb`
- Update: `test/unit/generators/annotation_generator_test.rb` (update require path)

**Step 1: Write the failing test for command**

```ruby
# test/unit/commands/annotate/command_test.rb
require_relative "../../../test_helper"

describe Jojo::Commands::Annotate::Command do
  before do
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Create config
    File.write("config.yml", <<~YAML)
      seeker_name: "Test User"
      base_url: "https://example.com"
      reasoning_ai_service: openai
      reasoning_ai_model: gpt-4
      text_generation_ai_service: openai
      text_generation_ai_model: gpt-4
    YAML

    # Create employer with required files
    FileUtils.mkdir_p("employers/acme-corp")
    File.write("employers/acme-corp/job_description.md", "5+ years Python")
    File.write("employers/acme-corp/resume.md", "7 years Python experience")

    @mock_cli = Minitest::Mock.new
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  it "inherits from Base" do
    require_relative "../../../../lib/jojo/commands/annotate/command"
    _(Jojo::Commands::Annotate::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "exits when employer not found" do
    require_relative "../../../../lib/jojo/commands/annotate/command"

    @mock_cli.expect(:say, nil, [/not found/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Annotate::Command.new(@mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/annotate/command_test.rb`
Expected: FAIL with "cannot load such file"

**Step 3: Move and update files**

Create directory structure:
```bash
mkdir -p lib/jojo/commands/annotate
```

Copy `lib/jojo/generators/annotation_generator.rb` to `lib/jojo/commands/annotate/generator.rb`:
- Update module path from `Jojo::Generators::AnnotationGenerator` to `Jojo::Commands::Annotate::Generator`
- Update require path for prompt

Copy `lib/jojo/prompts/annotation_prompt.rb` to `lib/jojo/commands/annotate/prompt.rb`:
- Update module path from `Jojo::Prompts::Annotation` to `Jojo::Commands::Annotate::Prompt`

Create command:

```ruby
# lib/jojo/commands/annotate/command.rb
require_relative "../base"
require_relative "generator"

module Jojo
  module Commands
    module Annotate
      class Command < Base
        def execute
          require_employer!

          say "Generating annotations for #{employer.company_name}...", :green

          generator = Generator.new(
            employer,
            ai_client,
            verbose: verbose?,
            overwrite_flag: overwrite?,
            cli_instance: cli
          )
          annotations = generator.generate

          status_logger.log_step(:annotate, tokens: ai_client.total_tokens_used, status: "complete")

          say "Generated #{annotations.length} annotations", :green
          say "  Saved to: #{employer.job_description_annotations_path}", :green
        rescue => e
          say "Error generating annotations: #{e.message}", :red
          status_logger.log_step(:annotate, status: "failed", error: e.message) rescue nil
          exit 1
        end
      end
    end
  end
end
```

Update `lib/jojo/commands/annotate/generator.rb`:

```ruby
# lib/jojo/commands/annotate/generator.rb
require "json"
require_relative "prompt"

module Jojo
  module Commands
    module Annotate
      class Generator
        # ... (same implementation, just update Prompts::Annotation to Prompt)
      end
    end
  end
end
```

Update `lib/jojo/commands/annotate/prompt.rb`:

```ruby
# lib/jojo/commands/annotate/prompt.rb
module Jojo
  module Commands
    module Annotate
      module Prompt
        def self.generate_annotations_prompt(...)
          # ... same implementation
        end
      end
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec ruby -Ilib:test test/unit/commands/annotate/command_test.rb`
Expected: PASS

**Step 5: Update generator test requires**

Update `test/unit/generators/annotation_generator_test.rb` to require from new location and use new class name.

**Step 6: Run all tests**

Run: `./bin/jojo test --all --no-service`
Expected: PASS

**Step 7: Commit**

```bash
git add lib/jojo/commands/annotate/
git add test/unit/commands/annotate/
git commit -m "$(cat <<'EOF'
feat(commands): extract annotate command with generator and prompt

Co-locates annotation-related code under commands/annotate/.
EOF
)"
```

---

## Task 8: Wire Annotate Command into CLI

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Update CLI to use Annotate command**

Add require:

```ruby
require_relative "commands/annotate/command"
```

Replace annotate method body:

```ruby
    def annotate
      Commands::Annotate::Command.new(self, command_options).execute
    end
```

Remove the old annotate implementation code.

**Step 2: Run tests**

Run: `./bin/jojo test --all --no-service`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "$(cat <<'EOF'
refactor(cli): wire annotate command through Commands::Annotate
EOF
)"
```

---

## Task 9-16: Extract Remaining Commands

Repeat the pattern from Tasks 7-8 for each command:

### Task 9: Research Command
- Create: `lib/jojo/commands/research/{command,generator,prompt}.rb`
- Move from: `lib/jojo/generators/research_generator.rb`, `lib/jojo/prompts/research_prompt.rb`

### Task 10: Resume Command
- Create: `lib/jojo/commands/resume/{command,generator,prompt,curation_service,transformer}.rb`
- Move from: `lib/jojo/generators/resume_generator.rb`, `lib/jojo/prompts/resume_prompt.rb`, `lib/jojo/resume_curation_service.rb`, `lib/jojo/resume_transformer.rb`

### Task 11: Cover Letter Command
- Create: `lib/jojo/commands/cover_letter/{command,generator,prompt}.rb`
- Move from: `lib/jojo/generators/cover_letter_generator.rb`, `lib/jojo/prompts/cover_letter_prompt.rb`

### Task 12: FAQ Command
- Create: `lib/jojo/commands/faq/{command,generator,prompt}.rb`
- Move from: `lib/jojo/generators/faq_generator.rb`, `lib/jojo/prompts/faq_prompt.rb`

### Task 13: Branding Command
- Create: `lib/jojo/commands/branding/{command,generator,prompt}.rb`
- Move from: `lib/jojo/generators/branding_generator.rb`

### Task 14: Website Command
- Create: `lib/jojo/commands/website/{command,generator,prompt}.rb`
- Move from: `lib/jojo/generators/website_generator.rb`, `lib/jojo/prompts/website_prompt.rb`

### Task 15: PDF Command
- Create: `lib/jojo/commands/pdf/{command,converter,pandoc_checker}.rb`
- Move from: `lib/jojo/pdf_converter.rb`, `lib/jojo/pandoc_checker.rb`

### Task 16: Setup Command
- Create: `lib/jojo/commands/setup/{command,service}.rb`
- Move from: `lib/jojo/setup_service.rb`

For each task, follow the same steps:
1. Write failing command test
2. Run test to verify failure
3. Create command class, move generator/prompt/helpers
4. Run tests to verify pass
5. Wire into CLI
6. Run full test suite
7. Commit

---

## Task 17: Extract New Command

**Files:**
- Create: `lib/jojo/commands/new/command.rb`
- Test: `test/unit/commands/new/command_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/commands/new/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/new/command"

describe Jojo::Commands::New::Command do
  before do
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Create inputs directory with resume_data.yml
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\n# Modified content")

    @mock_cli = Minitest::Mock.new
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  it "creates employer directory" do
    @mock_cli.expect(:say, nil, [/Created/, :green])
    @mock_cli.expect(:say, nil, [String, :cyan])
    @mock_cli.expect(:say, nil, [String, :white])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "new-corp")
    command.execute

    _(Dir.exist?("employers/new-corp")).must_equal true
    @mock_cli.verify
  end

  it "exits if employer already exists" do
    FileUtils.mkdir_p("employers/existing")

    @mock_cli.expect(:say, nil, [/already exists/, :yellow])

    command = Jojo::Commands::New::Command.new(@mock_cli, slug: "existing")

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/new/command_test.rb`
Expected: FAIL

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/commands/new/command.rb
require_relative "../base"
require_relative "../../template_validator"

module Jojo
  module Commands
    module New
      class Command < Base
        def execute
          validate_inputs!

          if File.exist?(employer.base_path)
            say "Application '#{slug}' already exists.", :yellow
            exit 1
          end

          FileUtils.mkdir_p(employer.base_path)
          say "Created application workspace: #{employer.base_path}", :green
          say "\nNext step:", :cyan
          say "  jojo job_description -s #{slug} -j <job_file_or_url>", :white
        end

        private

        def validate_inputs!
          Jojo::TemplateValidator.validate_required_file!(
            "inputs/resume_data.yml",
            "resume data"
          )

          result = Jojo::TemplateValidator.warn_if_unchanged(
            "inputs/resume_data.yml",
            "resume data",
            cli_instance: cli
          )

          if result == :abort
            say "Setup your inputs first, then run this command again.", :yellow
            exit 1
          end
        rescue Jojo::TemplateValidator::MissingInputError => e
          say e.message, :red
          exit 1
        end
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/new/command_test.rb`
Expected: PASS

**Step 5: Wire into CLI and commit**

```bash
git add lib/jojo/commands/new/ test/unit/commands/new/
git commit -m "$(cat <<'EOF'
feat(commands): extract new command to Commands::New
EOF
)"
```

---

## Task 18: Extract Job Description Command

**Files:**
- Create: `lib/jojo/commands/job_description/{command,processor,prompt}.rb`
- Move from: `lib/jojo/job_description_processor.rb`, `lib/jojo/prompts/job_description_prompts.rb`
- Test: `test/unit/commands/job_description/command_test.rb`

Follow the same pattern as previous commands.

---

## Task 19: Extract Test Command

**Files:**
- Create: `lib/jojo/commands/test/command.rb`
- Test: `test/unit/commands/test/command_test.rb`

The test command is simpler - it shells out to run tests. Extract following the same pattern.

---

## Task 20: Extract Interactive Command

**Files:**
- Create: `lib/jojo/commands/interactive/{command,runner,workflow,dashboard,dialogs}.rb`
- Move from: `lib/jojo/interactive.rb`, `lib/jojo/workflow.rb`, `lib/jojo/ui/dashboard.rb`, `lib/jojo/ui/dialogs.rb`
- Test: `test/unit/commands/interactive/command_test.rb`

**Key Change:** Update `runner.rb` (formerly `interactive.rb`) to use `ConsoleOutput` and call command classes directly instead of `CLI.invoke()`.

Replace:

```ruby
def execute_step_quietly(step)
  cli = CLI.new
  cli.options = {slug: @slug, overwrite: true, quiet: true}
  cli.invoke(:research, [], slug: @slug, overwrite: true, quiet: true)
  # ...
end
```

With:

```ruby
def execute_step_quietly(step)
  output = ConsoleOutput.new(quiet: true)
  command_class = step_command_class(step[:command])
  command_class.new(output, slug: @slug, overwrite: true, quiet: true).execute
end

def step_command_class(command_key)
  case command_key
  when :research then Commands::Research::Command
  when :resume then Commands::Resume::Command
  when :cover_letter then Commands::CoverLetter::Command
  when :annotate then Commands::Annotate::Command
  when :faq then Commands::Faq::Command
  when :branding then Commands::Branding::Command
  when :website then Commands::Website::Command
  when :pdf then Commands::Pdf::Command
  end
end
```

---

## Task 21: Remove Generate Command

**Files:**
- Modify: `lib/jojo/cli.rb` (remove generate command)
- Modify: `test/unit/cli_test.rb` (remove generate command test)

The `generate` command is removed per the design doc. Users should use interactive mode or individual commands.

**Step 1: Remove from CLI**

Delete the `generate` method from `cli.rb`.

**Step 2: Update test**

Remove the test for generate command existence.

**Step 3: Run tests**

Run: `./bin/jojo test --all --no-service`
Expected: PASS

**Step 4: Commit**

```bash
git add lib/jojo/cli.rb test/unit/cli_test.rb
git commit -m "$(cat <<'EOF'
refactor(cli): remove generate command

Users should use interactive mode or individual commands.
EOF
)"
```

---

## Task 22: Clean Up Old Directories

**Files:**
- Delete: `lib/jojo/generators/` (empty after moves)
- Delete: `lib/jojo/prompts/` (empty after moves)
- Delete: `lib/jojo/ui/` (empty after moves)
- Delete: `lib/jojo/interactive.rb` (moved)
- Delete: `lib/jojo/workflow.rb` (moved)
- Update: `lib/jojo.rb` (update requires)

**Step 1: Update lib/jojo.rb requires**

Replace scattered requires with new command structure:

```ruby
require "thor"
require "dotenv/load"

module Jojo
  VERSION = "0.1.0"
end

require_relative "jojo/state_persistence"
require_relative "jojo/config"
require_relative "jojo/employer"
require_relative "jojo/overwrite_helper"
require_relative "jojo/ai_client"
require_relative "jojo/errors"
require_relative "jojo/erb_renderer"
require_relative "jojo/resume_data_formatter"
require_relative "jojo/resume_data_loader"
require_relative "jojo/status_logger"
require_relative "jojo/template_validator"
require_relative "jojo/commands/base"
require_relative "jojo/commands/console_output"
require_relative "jojo/cli"
```

**Step 2: Delete old directories**

```bash
rm -rf lib/jojo/generators
rm -rf lib/jojo/prompts
rm -rf lib/jojo/ui
rm lib/jojo/interactive.rb
rm lib/jojo/workflow.rb
rm lib/jojo/pdf_converter.rb
rm lib/jojo/pandoc_checker.rb
rm lib/jojo/job_description_processor.rb
rm lib/jojo/setup_service.rb
rm lib/jojo/resume_curation_service.rb
rm lib/jojo/resume_transformer.rb
```

**Step 3: Update test requires**

Update any test files that require old paths to use new paths.

**Step 4: Run full test suite**

Run: `./bin/jojo test --all --no-service`
Expected: PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor: clean up old directories after command extraction

Removes generators/, prompts/, ui/ directories.
Updates lib/jojo.rb with new require structure.
EOF
)"
```

---

## Task 23: Update Test Organization

**Files:**
- Move: `test/unit/generators/*` -> `test/unit/commands/*/`
- Move: `test/unit/prompts/*` -> `test/unit/commands/*/`
- Move: `test/unit/ui/*` -> `test/unit/commands/interactive/`
- Update: All test requires

Reorganize test files to mirror the new source structure.

**Step 1: Move test files**

```bash
# Annotate
mv test/unit/generators/annotation_generator_test.rb test/unit/commands/annotate/generator_test.rb
mv test/unit/prompts/annotation_prompt_test.rb test/unit/commands/annotate/prompt_test.rb

# Research
mv test/unit/generators/research_generator_test.rb test/unit/commands/research/generator_test.rb
mv test/unit/prompts/research_prompt_test.rb test/unit/commands/research/prompt_test.rb

# Resume
mv test/unit/generators/resume_generator_test.rb test/unit/commands/resume/generator_test.rb
mv test/unit/prompts/resume_prompt_test.rb test/unit/commands/resume/prompt_test.rb

# Cover Letter
mv test/unit/generators/cover_letter_generator_test.rb test/unit/commands/cover_letter/generator_test.rb

# FAQ
mv test/unit/generators/faq_generator_test.rb test/unit/commands/faq/generator_test.rb
mv test/unit/prompts/faq_prompt_test.rb test/unit/commands/faq/prompt_test.rb

# Branding
mv test/unit/generators/branding_generator_test.rb test/unit/commands/branding/generator_test.rb

# Website
mv test/unit/generators/website_generator_test.rb test/unit/commands/website/generator_test.rb
mv test/unit/prompts/website_prompt_test.rb test/unit/commands/website/prompt_test.rb

# UI -> Interactive
mv test/unit/ui/dashboard_test.rb test/unit/commands/interactive/dashboard_test.rb
mv test/unit/ui/dialogs_test.rb test/unit/commands/interactive/dialogs_test.rb
```

**Step 2: Update require paths in all moved tests**

Each test file needs updated require_relative paths.

**Step 3: Run full test suite**

Run: `./bin/jojo test --all --no-service`
Expected: PASS

**Step 4: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor(tests): reorganize tests to mirror commands structure

Tests now co-located with their source code under commands/.
EOF
)"
```

---

## Task 24: Final Integration Test

**Files:**
- Run all tests
- Manual CLI verification

**Step 1: Run full test suite**

Run: `./bin/jojo test --all --no-service`
Expected: PASS

**Step 2: Manual verification**

Test each command manually:

```bash
./bin/jojo version
./bin/jojo help
./bin/jojo interactive  # Test basic navigation
```

**Step 3: Line count verification**

Run: `wc -l lib/jojo/cli.rb`
Expected: ~150 lines (down from 877)

**Step 4: Final commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
docs: complete CLI commands refactor

CLI reduced from 877 to ~150 lines.
Commands now self-contained under lib/jojo/commands/.
Interactive mode uses ConsoleOutput adapter.
EOF
)"
```

---

## Summary

| Task | Description | Estimated Steps |
|------|-------------|-----------------|
| 1-3 | Commands::Base class | 15 |
| 4 | ConsoleOutput adapter | 5 |
| 5-6 | Version command (proof of concept) | 10 |
| 7-8 | Annotate command | 10 |
| 9-16 | Remaining generators (8 commands) | 80 |
| 17 | New command | 10 |
| 18 | Job Description command | 10 |
| 19 | Test command | 10 |
| 20 | Interactive command | 15 |
| 21 | Remove generate command | 5 |
| 22 | Clean up old directories | 5 |
| 23 | Reorganize tests | 10 |
| 24 | Final integration | 5 |

**Total:** ~190 steps across 24 tasks
