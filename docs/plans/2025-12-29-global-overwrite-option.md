# Global Overwrite Option Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `--overwrite` a global option with consistent prompting behavior across all jojo commands.

**Architecture:** Create an `OverwriteHelper` mixin that provides `with_overwrite_check` method. Include it in CLI class. All file-writing operations use this helper instead of direct `File.write`. Supports `--overwrite`, `--no-overwrite` flags and `JOJO_ALWAYS_OVERWRITE` environment variable.

**Tech Stack:** Ruby, Thor, Minitest

---

## Task 1: Create OverwriteHelper Module Foundation

**Files:**
- Create: `lib/jojo/overwrite_helper.rb`
- Create: `test/overwrite_helper_test.rb`

**Step 1: Write failing test for env_overwrite? with truthy values**

```ruby
# test/overwrite_helper_test.rb
require "test_helper"

class OverwriteHelperTest < Minitest::Test
  # Create a test class that includes the module
  class TestCLI
    include Jojo::OverwriteHelper
  end

  def setup
    @cli = TestCLI.new
  end

  def test_env_overwrite_returns_true_for_1
    with_env("JOJO_ALWAYS_OVERWRITE" => "1") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_true_for_true
    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_true_for_yes
    with_env("JOJO_ALWAYS_OVERWRITE" => "yes") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_true_for_uppercase_TRUE
    with_env("JOJO_ALWAYS_OVERWRITE" => "TRUE") do
      assert @cli.send(:env_overwrite?)
    end
  end

  private

  def with_env(env_vars)
    old_values = {}
    env_vars.each do |key, value|
      old_values[key] = ENV[key]
      ENV[key] = value
    end
    yield
  ensure
    old_values.each do |key, value|
      ENV[key] = value
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL with "uninitialized constant Jojo::OverwriteHelper"

**Step 3: Create minimal OverwriteHelper with env_overwrite?**

```ruby
# lib/jojo/overwrite_helper.rb
module Jojo
  module OverwriteHelper
    private

    def env_overwrite?
      %w[1 true yes].include?(ENV['JOJO_ALWAYS_OVERWRITE']&.downcase)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (4 tests, 4 assertions)

**Step 5: Commit**

```bash
git add lib/jojo/overwrite_helper.rb test/overwrite_helper_test.rb
git commit -m "feat: add OverwriteHelper with env_overwrite? method"
```

---

## Task 2: Test env_overwrite? Returns False for Non-Truthy Values

**Files:**
- Modify: `test/overwrite_helper_test.rb`

**Step 1: Write failing tests for falsy values**

Add to `test/overwrite_helper_test.rb` after existing tests:

```ruby
  def test_env_overwrite_returns_false_for_0
    with_env("JOJO_ALWAYS_OVERWRITE" => "0") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_false
    with_env("JOJO_ALWAYS_OVERWRITE" => "false") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_no
    with_env("JOJO_ALWAYS_OVERWRITE" => "no") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_random_string
    with_env("JOJO_ALWAYS_OVERWRITE" => "whatever") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_when_unset
    with_env("JOJO_ALWAYS_OVERWRITE" => nil) do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_when_empty
    with_env("JOJO_ALWAYS_OVERWRITE" => "") do
      refute @cli.send(:env_overwrite?)
    end
  end
```

**Step 2: Run tests to verify they pass**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (10 tests, 10 assertions)

**Step 3: Commit**

```bash
git add test/overwrite_helper_test.rb
git commit -m "test: add env_overwrite? tests for falsy values"
```

---

## Task 3: Implement should_overwrite? Method

**Files:**
- Modify: `test/overwrite_helper_test.rb`
- Modify: `lib/jojo/overwrite_helper.rb`

**Step 1: Write failing tests for should_overwrite?**

Add to `test/overwrite_helper_test.rb`:

```ruby
  def test_should_overwrite_returns_true_when_flag_is_true
    assert @cli.send(:should_overwrite?, true)
  end

  def test_should_overwrite_returns_false_when_flag_is_false
    refute @cli.send(:should_overwrite?, false)
  end

  def test_should_overwrite_returns_true_when_flag_is_nil_and_env_is_truthy
    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      assert @cli.send(:should_overwrite?, nil)
    end
  end

  def test_should_overwrite_returns_false_when_flag_is_nil_and_env_is_falsy
    with_env("JOJO_ALWAYS_OVERWRITE" => "false") do
      refute @cli.send(:should_overwrite?, nil)
    end
  end

  def test_should_overwrite_flag_false_overrides_env_true
    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      refute @cli.send(:should_overwrite?, false)
    end
  end
```

**Step 2: Run tests to verify they fail**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL with "undefined method `should_overwrite?'"

**Step 3: Implement should_overwrite? method**

Add to `lib/jojo/overwrite_helper.rb` in the private section:

```ruby
    def should_overwrite?(flag)
      # --overwrite flag wins
      return true if flag == true
      # --no-overwrite flag blocks env var
      return false if flag == false
      # Check environment variable
      env_overwrite?
    end
```

**Step 4: Run tests to verify they pass**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (15 tests, 15 assertions)

**Step 5: Commit**

```bash
git add lib/jojo/overwrite_helper.rb test/overwrite_helper_test.rb
git commit -m "feat: add should_overwrite? with flag precedence logic"
```

---

## Task 4: Implement with_overwrite_check Method (File Doesn't Exist Case)

**Files:**
- Modify: `test/overwrite_helper_test.rb`
- Modify: `lib/jojo/overwrite_helper.rb`

**Step 1: Write failing test for non-existent file**

Add to `test/overwrite_helper_test.rb`:

```ruby
  def test_with_overwrite_check_yields_when_file_does_not_exist
    Dir.mktmpdir do |dir|
      path = File.join(dir, "nonexistent.txt")
      yielded = false

      @cli.with_overwrite_check(path, nil) do
        yielded = true
      end

      assert yielded, "Expected block to be yielded when file doesn't exist"
    end
  end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL with "undefined method `with_overwrite_check'"

**Step 3: Implement with_overwrite_check skeleton**

Add to `lib/jojo/overwrite_helper.rb` (public method above private):

```ruby
    def with_overwrite_check(path, overwrite_flag, &block)
      # Check if file exists
      return yield unless File.exist?(path)
    end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (16 tests, 16 assertions)

**Step 5: Commit**

```bash
git add lib/jojo/overwrite_helper.rb test/overwrite_helper_test.rb
git commit -m "feat: add with_overwrite_check method (non-existent file case)"
```

---

## Task 5: Implement with_overwrite_check (Overwrite Flag Case)

**Files:**
- Modify: `test/overwrite_helper_test.rb`
- Modify: `lib/jojo/overwrite_helper.rb`

**Step 1: Write failing test for --overwrite flag**

Add to `test/overwrite_helper_test.rb`:

```ruby
  def test_with_overwrite_check_yields_when_file_exists_and_flag_is_true
    Dir.mktmpdir do |dir|
      path = File.join(dir, "existing.txt")
      File.write(path, "original")
      yielded = false

      @cli.with_overwrite_check(path, true) do
        yielded = true
      end

      assert yielded, "Expected block to be yielded when --overwrite is set"
    end
  end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL (block not yielded)

**Step 3: Add should_overwrite? check to with_overwrite_check**

Modify `lib/jojo/overwrite_helper.rb`:

```ruby
    def with_overwrite_check(path, overwrite_flag, &block)
      # Check if file exists
      return yield unless File.exist?(path)

      # Check override mechanisms in precedence order
      return yield if should_overwrite?(overwrite_flag)
    end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (17 tests, 17 assertions)

**Step 5: Commit**

```bash
git add lib/jojo/overwrite_helper.rb test/overwrite_helper_test.rb
git commit -m "feat: add overwrite flag handling to with_overwrite_check"
```

---

## Task 6: Implement with_overwrite_check (Non-TTY Error Case)

**Files:**
- Modify: `test/overwrite_helper_test.rb`
- Modify: `lib/jojo/overwrite_helper.rb`

**Step 1: Write failing test for non-TTY environment**

Add to `test/overwrite_helper_test.rb`:

```ruby
  def test_with_overwrite_check_raises_error_in_non_tty_environment
    Dir.mktmpdir do |dir|
      path = File.join(dir, "existing.txt")
      File.write(path, "original")

      # Mock $stdout.isatty to return false
      stdout_was = $stdout
      $stdout = StringIO.new
      def $stdout.isatty; false; end

      error = assert_raises(Thor::Error) do
        @cli.with_overwrite_check(path, nil) { }
      end

      assert_match /Cannot prompt in non-interactive mode/, error.message
      assert_match /--overwrite/, error.message
      assert_match /JOJO_ALWAYS_OVERWRITE/, error.message
    ensure
      $stdout = stdout_was
    end
  end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL (no error raised)

**Step 3: Add non-TTY check to with_overwrite_check**

Modify `lib/jojo/overwrite_helper.rb`:

```ruby
    def with_overwrite_check(path, overwrite_flag, &block)
      # Check if file exists
      return yield unless File.exist?(path)

      # Check override mechanisms in precedence order
      return yield if should_overwrite?(overwrite_flag)

      # Prompt user or fail in non-TTY
      if $stdout.isatty
        # TODO: Prompt implementation
      else
        raise Thor::Error, "Cannot prompt in non-interactive mode. Use --overwrite or set JOJO_ALWAYS_OVERWRITE=true"
      end
    end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (18 tests, 21 assertions)

**Step 5: Commit**

```bash
git add lib/jojo/overwrite_helper.rb test/overwrite_helper_test.rb
git commit -m "feat: add non-TTY error handling to with_overwrite_check"
```

---

## Task 7: Implement with_overwrite_check (Interactive Prompt Case)

**Files:**
- Modify: `test/overwrite_helper_test.rb`
- Modify: `lib/jojo/overwrite_helper.rb`

**Step 1: Write failing test for yes? prompt acceptance**

Add to `test/overwrite_helper_test.rb`:

```ruby
  def test_with_overwrite_check_yields_when_user_says_yes
    Dir.mktmpdir do |dir|
      path = File.join(dir, "existing.txt")
      File.write(path, "original")
      yielded = false

      # Mock yes? to return true
      def @cli.yes?(message)
        @last_prompt = message
        true
      end

      @cli.with_overwrite_check(path, nil) do
        yielded = true
      end

      assert yielded, "Expected block to be yielded when user says yes"
      assert_match /existing.txt/, @cli.instance_variable_get(:@last_prompt)
      assert_match /Overwrite/, @cli.instance_variable_get(:@last_prompt)
    end
  end

  def test_with_overwrite_check_does_not_yield_when_user_says_no
    Dir.mktmpdir do |dir|
      path = File.join(dir, "existing.txt")
      File.write(path, "original")
      yielded = false

      # Mock yes? to return false
      def @cli.yes?(message)
        false
      end

      @cli.with_overwrite_check(path, nil) do
        yielded = true
      end

      refute yielded, "Expected block NOT to be yielded when user says no"
    end
  end
```

**Step 2: Run tests to verify they fail**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL (undefined method `yes?`)

**Step 3: Add yes? stub to test class**

Modify `test/overwrite_helper_test.rb` TestCLI class:

```ruby
  class TestCLI
    include Jojo::OverwriteHelper

    def yes?(message)
      false
    end
  end
```

**Step 4: Run tests to verify they still fail**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: FAIL (block yielded in first test, not in second - backwards)

**Step 5: Implement interactive prompt in with_overwrite_check**

Modify `lib/jojo/overwrite_helper.rb`:

```ruby
    def with_overwrite_check(path, overwrite_flag, &block)
      # Check if file exists
      return yield unless File.exist?(path)

      # Check override mechanisms in precedence order
      return yield if should_overwrite?(overwrite_flag)

      # Prompt user or fail in non-TTY
      if $stdout.isatty
        filename = File.basename(path)
        yield if yes?("#{filename} exists. Overwrite?")
      else
        raise Thor::Error, "Cannot prompt in non-interactive mode. Use --overwrite or set JOJO_ALWAYS_OVERWRITE=true"
      end
    end
```

**Step 6: Run tests to verify they pass**

Run: `ruby -Ilib:test test/overwrite_helper_test.rb`
Expected: PASS (20 tests, 23 assertions)

**Step 7: Commit**

```bash
git add lib/jojo/overwrite_helper.rb test/overwrite_helper_test.rb
git commit -m "feat: add interactive prompt to with_overwrite_check"
```

---

## Task 8: Add Global --overwrite Option to CLI

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Include OverwriteHelper in CLI class**

Add to `lib/jojo/cli.rb` after the class definition line (around line 10):

```ruby
module Jojo
  class CLI < Thor
    include OverwriteHelper
```

**Step 2: Add global --overwrite option**

Add after existing `class_option` declarations (around line 15):

```ruby
    class_option :overwrite, type: :boolean, banner: 'Overwrite existing files without prompting'
```

**Step 3: Verify no syntax errors**

Run: `ruby -c lib/jojo/cli.rb`
Expected: "Syntax OK"

**Step 4: Run existing tests to ensure nothing broke**

Run: `./bin/jojo test`
Expected: All tests should still pass

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add global --overwrite option and include OverwriteHelper"
```

---

## Task 9: Update jojo new Command

**Files:**
- Modify: `lib/jojo/cli.rb` (around lines 52-70)
- Modify: `lib/jojo/employer.rb`
- Create: `test/integration/new_overwrite_test.rb`

**Step 1: Write integration test for jojo new with existing artifacts**

```ruby
# test/integration/new_overwrite_test.rb
require "test_helper"

class NewOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    # Create config.yml
    File.write("config.yml", "llm:\n  provider: anthropic\n")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_new_prompts_when_artifacts_exist
    # Create employer with existing artifacts
    slug = "test-employer"
    FileUtils.mkdir_p("employers/#{slug}/inputs")
    File.write("employers/#{slug}/inputs/profile.md", "existing")

    # Mock TTY and yes? to say no
    stdout_capture = capture_io do
      cli = Jojo::CLI.new
      def cli.yes?(msg); false; end

      assert_raises(SystemExit) do
        cli.options = { slug: slug }
        cli.new
      end
    end
  end

  def test_new_with_overwrite_flag_overwrites_artifacts
    # Create employer with existing artifacts
    slug = "test-employer"
    FileUtils.mkdir_p("employers/#{slug}/inputs")
    File.write("employers/#{slug}/inputs/profile.md", "existing")

    cli = Jojo::CLI.new
    cli.options = { slug: slug, overwrite: true }

    capture_io do
      cli.new
    end

    # Should have created new artifacts
    assert File.exist?("employers/#{slug}/inputs/profile.md")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/new_overwrite_test.rb`
Expected: FAIL (current implementation doesn't use with_overwrite_check)

**Step 3: Remove command-specific --overwrite option from jojo new**

In `lib/jojo/cli.rb`, remove line ~52:

```ruby
    method_option :overwrite, type: :boolean, aliases: '-o', default: false  # DELETE THIS LINE
```

**Step 4: Update Employer#create_artifacts to use with_overwrite_check**

First, check current implementation:

Run: `grep -A 20 "def create_artifacts" lib/jojo/employer.rb`

Then modify `lib/jojo/employer.rb` to accept overwrite_flag parameter and use helper:

```ruby
  def create_artifacts(overwrite_flag = nil, cli_instance = nil)
    Dir.mkdir(employer_dir) unless Dir.exist?(employer_dir)

    if cli_instance
      cli_instance.with_overwrite_check(inputs_dir, overwrite_flag) do
        Dir.mkdir(inputs_dir) unless Dir.exist?(inputs_dir)
      end

      INPUT_TEMPLATES.each do |template|
        dest_path = File.join(inputs_dir, template)
        cli_instance.with_overwrite_check(dest_path, overwrite_flag) do
          FileUtils.cp(template_path(template), dest_path)
        end
      end
    else
      # Fallback for direct calls without CLI instance
      Dir.mkdir(inputs_dir) unless Dir.exist?(inputs_dir)
      INPUT_TEMPLATES.each do |template|
        FileUtils.cp(template_path(template), File.join(inputs_dir, template))
      end
    end
  end
```

**Step 5: Update jojo new command to pass self and overwrite flag**

In `lib/jojo/cli.rb`, modify the `new` command (around line 61):

Remove the old artifacts_exist? check:
```ruby
    # DELETE THESE LINES:
    if employer.artifacts_exist? && !options[:overwrite]
      error "Artifacts for '#{slug}' already exist. Use --overwrite to replace them."
      exit 1
    end
```

Update the create_artifacts call:
```ruby
    employer.create_artifacts(options[:overwrite], self)
```

**Step 6: Run tests to verify**

Run: `ruby -Ilib:test test/integration/new_overwrite_test.rb`
Expected: Tests may need adjustment based on actual implementation

**Step 7: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 8: Commit**

```bash
git add lib/jojo/cli.rb lib/jojo/employer.rb test/integration/new_overwrite_test.rb
git commit -m "feat: update jojo new to use global overwrite behavior"
```

---

## Task 10: Update jojo setup Command

**Files:**
- Modify: `lib/jojo/cli.rb` (around lines 560-565)
- Create: `test/integration/setup_overwrite_test.rb`

**Step 1: Write integration test for jojo setup**

```ruby
# test/integration/setup_overwrite_test.rb
require "test_helper"

class SetupOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_setup_prompts_when_config_exists
    File.write("config.yml", "existing: config")

    cli = Jojo::CLI.new
    def cli.yes?(msg); false; end

    capture_io { cli.setup }

    # Should not have overwritten
    assert_equal "existing: config", File.read("config.yml")
  end

  def test_setup_with_overwrite_flag_overwrites_config
    File.write("config.yml", "existing: config")

    cli = Jojo::CLI.new
    cli.options = { overwrite: true }

    capture_io { cli.setup }

    # Should have overwritten
    refute_equal "existing: config", File.read("config.yml")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/setup_overwrite_test.rb`
Expected: FAIL (current implementation uses custom yes? prompt)

**Step 3: Update jojo setup to use with_overwrite_check**

In `lib/jojo/cli.rb`, find the setup command (around line 560) and replace:

```ruby
    # DELETE THESE LINES:
    if File.exist?(config_path)
      unless yes?("config.yml already exists. Overwrite?")
        say "Setup cancelled.", :yellow
        return
      end
    end

    File.write(config_path, config_content)
```

With:

```ruby
    with_overwrite_check(config_path, options[:overwrite]) do
      File.write(config_path, config_content)
    end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/setup_overwrite_test.rb`
Expected: PASS

**Step 5: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/jojo/cli.rb test/integration/setup_overwrite_test.rb
git commit -m "feat: update jojo setup to use global overwrite behavior"
```

---

## Task 11: Update ResearchGenerator

**Files:**
- Modify: `lib/jojo/generators/research_generator.rb`
- Modify: `lib/jojo/cli.rb` (research command)
- Create: `test/integration/research_overwrite_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/research_overwrite_test.rb
require "test_helper"

class ResearchOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    # Create minimal config and employer
    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_research_prompts_when_file_exists
    File.write("employers/test-employer/research.md", "existing research")

    cli = Jojo::CLI.new
    def cli.yes?(msg); false; end
    cli.options = { slug: "test-employer" }

    # Mock the LLM call
    Jojo::LLMClient.stub :call, "new research" do
      capture_io { cli.research }
    end

    # Should not have overwritten
    assert_equal "existing research", File.read("employers/test-employer/research.md")
  end

  def test_research_with_overwrite_flag_overwrites
    File.write("employers/test-employer/research.md", "existing research")

    cli = Jojo::CLI.new
    cli.options = { slug: "test-employer", overwrite: true }

    # Mock the LLM call
    Jojo::LLMClient.stub :call, "new research" do
      capture_io { cli.research }
    end

    # Should have overwritten
    assert_equal "new research", File.read("employers/test-employer/research.md")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/research_overwrite_test.rb`
Expected: FAIL (silent overwrite currently)

**Step 3: Update ResearchGenerator.save_research to accept cli_instance**

In `lib/jojo/generators/research_generator.rb`:

```ruby
  def self.save_research(employer, research_text, overwrite_flag, cli_instance)
    cli_instance.with_overwrite_check(employer.research_path, overwrite_flag) do
      File.write(employer.research_path, research_text)
    end
  end
```

**Step 4: Update research command in CLI to pass parameters**

In `lib/jojo/cli.rb`, find research command and update:

```ruby
    ResearchGenerator.save_research(employer, research, options[:overwrite], self)
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/research_overwrite_test.rb`
Expected: PASS

**Step 6: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/generators/research_generator.rb lib/jojo/cli.rb test/integration/research_overwrite_test.rb
git commit -m "feat: update research generator to use global overwrite behavior"
```

---

## Task 12: Update ResumeGenerator

**Files:**
- Modify: `lib/jojo/generators/resume_generator.rb`
- Modify: `lib/jojo/cli.rb` (resume command)
- Create: `test/integration/resume_overwrite_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/resume_overwrite_test.rb
require "test_helper"

class ResumeOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
    File.write("employers/test-employer/research.md", "research")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_resume_prompts_when_file_exists
    File.write("employers/test-employer/resume.md", "existing resume")

    cli = Jojo::CLI.new
    def cli.yes?(msg); false; end
    cli.options = { slug: "test-employer" }

    Jojo::LLMClient.stub :call, "new resume" do
      capture_io { cli.resume }
    end

    assert_equal "existing resume", File.read("employers/test-employer/resume.md")
  end

  def test_resume_with_overwrite_flag_overwrites
    File.write("employers/test-employer/resume.md", "existing resume")

    cli = Jojo::CLI.new
    cli.options = { slug: "test-employer", overwrite: true }

    Jojo::LLMClient.stub :call, "new resume" do
      capture_io { cli.resume }
    end

    assert_equal "new resume", File.read("employers/test-employer/resume.md")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/resume_overwrite_test.rb`
Expected: FAIL

**Step 3: Update ResumeGenerator.save_resume**

In `lib/jojo/generators/resume_generator.rb`:

```ruby
  def self.save_resume(employer, resume_text, overwrite_flag, cli_instance)
    cli_instance.with_overwrite_check(employer.resume_path, overwrite_flag) do
      File.write(employer.resume_path, resume_text)
    end
  end
```

**Step 4: Update resume command in CLI**

In `lib/jojo/cli.rb`:

```ruby
    ResumeGenerator.save_resume(employer, resume, options[:overwrite], self)
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/resume_overwrite_test.rb`
Expected: PASS

**Step 6: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/generators/resume_generator.rb lib/jojo/cli.rb test/integration/resume_overwrite_test.rb
git commit -m "feat: update resume generator to use global overwrite behavior"
```

---

## Task 13: Update CoverLetterGenerator

**Files:**
- Modify: `lib/jojo/generators/cover_letter_generator.rb`
- Modify: `lib/jojo/cli.rb` (cover_letter command)
- Create: `test/integration/cover_letter_overwrite_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/cover_letter_overwrite_test.rb
require "test_helper"

class CoverLetterOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
    File.write("employers/test-employer/research.md", "research")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_cover_letter_prompts_when_file_exists
    File.write("employers/test-employer/cover_letter.md", "existing letter")

    cli = Jojo::CLI.new
    def cli.yes?(msg); false; end
    cli.options = { slug: "test-employer" }

    Jojo::LLMClient.stub :call, "new letter" do
      capture_io { cli.cover_letter }
    end

    assert_equal "existing letter", File.read("employers/test-employer/cover_letter.md")
  end

  def test_cover_letter_with_overwrite_flag_overwrites
    File.write("employers/test-employer/cover_letter.md", "existing letter")

    cli = Jojo::CLI.new
    cli.options = { slug: "test-employer", overwrite: true }

    Jojo::LLMClient.stub :call, "new letter" do
      capture_io { cli.cover_letter }
    end

    assert_equal "new letter", File.read("employers/test-employer/cover_letter.md")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/cover_letter_overwrite_test.rb`
Expected: FAIL

**Step 3: Update CoverLetterGenerator.save_cover_letter**

In `lib/jojo/generators/cover_letter_generator.rb`:

```ruby
  def self.save_cover_letter(employer, letter_text, overwrite_flag, cli_instance)
    cli_instance.with_overwrite_check(employer.cover_letter_path, overwrite_flag) do
      File.write(employer.cover_letter_path, letter_text)
    end
  end
```

**Step 4: Update cover_letter command in CLI**

In `lib/jojo/cli.rb`:

```ruby
    CoverLetterGenerator.save_cover_letter(employer, cover_letter, options[:overwrite], self)
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/cover_letter_overwrite_test.rb`
Expected: PASS

**Step 6: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/generators/cover_letter_generator.rb lib/jojo/cli.rb test/integration/cover_letter_overwrite_test.rb
git commit -m "feat: update cover letter generator to use global overwrite behavior"
```

---

## Task 14: Update WebsiteGenerator

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`
- Modify: `lib/jojo/cli.rb` (website command)
- Create: `test/integration/website_overwrite_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/website_overwrite_test.rb
require "test_helper"

class WebsiteOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
    File.write("employers/test-employer/inputs/projects.yml", "projects:\n  - name: Test")
    File.write("employers/test-employer/resume.md", "resume")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_website_prompts_when_file_exists
    FileUtils.mkdir_p("employers/test-employer/website")
    File.write("employers/test-employer/website/index.html", "existing website")

    cli = Jojo::CLI.new
    def cli.yes?(msg); false; end
    cli.options = { slug: "test-employer" }

    Jojo::LLMClient.stub :call, "new website" do
      capture_io { cli.website }
    end

    assert_equal "existing website", File.read("employers/test-employer/website/index.html")
  end

  def test_website_with_overwrite_flag_overwrites
    FileUtils.mkdir_p("employers/test-employer/website")
    File.write("employers/test-employer/website/index.html", "existing website")

    cli = Jojo::CLI.new
    cli.options = { slug: "test-employer", overwrite: true }

    Jojo::LLMClient.stub :call, "new website" do
      capture_io { cli.website }
    end

    refute_equal "existing website", File.read("employers/test-employer/website/index.html")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/website_overwrite_test.rb`
Expected: FAIL

**Step 3: Update WebsiteGenerator.save_website**

In `lib/jojo/generators/website_generator.rb`:

```ruby
  def self.save_website(employer, html, overwrite_flag, cli_instance)
    website_dir = File.join(employer.employer_dir, 'website')
    Dir.mkdir(website_dir) unless Dir.exist?(website_dir)

    index_path = File.join(website_dir, 'index.html')
    cli_instance.with_overwrite_check(index_path, overwrite_flag) do
      File.write(index_path, html)
    end
  end
```

**Step 4: Update website command in CLI**

In `lib/jojo/cli.rb`:

```ruby
    WebsiteGenerator.save_website(employer, website, options[:overwrite], self)
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/website_overwrite_test.rb`
Expected: PASS

**Step 6: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/generators/website_generator.rb lib/jojo/cli.rb test/integration/website_overwrite_test.rb
git commit -m "feat: update website generator to use global overwrite behavior"
```

---

## Task 15: Update AnnotationGenerator

**Files:**
- Modify: `lib/jojo/generators/annotation_generator.rb`
- Modify: `lib/jojo/cli.rb` (annotate command)
- Create: `test/integration/annotate_overwrite_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/annotate_overwrite_test.rb
require "test_helper"

class AnnotateOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_annotate_prompts_when_file_exists
    File.write("employers/test-employer/job_description_annotations.json", '{"existing": true}')

    cli = Jojo::CLI.new
    def cli.yes?(msg); false; end
    cli.options = { slug: "test-employer" }

    Jojo::LLMClient.stub :call, '{"new": true}' do
      capture_io { cli.annotate }
    end

    assert_equal '{"existing": true}', File.read("employers/test-employer/job_description_annotations.json")
  end

  def test_annotate_with_overwrite_flag_overwrites
    File.write("employers/test-employer/job_description_annotations.json", '{"existing": true}')

    cli = Jojo::CLI.new
    cli.options = { slug: "test-employer", overwrite: true }

    Jojo::LLMClient.stub :call, '{"new": true}' do
      capture_io { cli.annotate }
    end

    assert_equal '{"new": true}', File.read("employers/test-employer/job_description_annotations.json")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/integration/annotate_overwrite_test.rb`
Expected: FAIL

**Step 3: Update AnnotationGenerator.save_annotations**

In `lib/jojo/generators/annotation_generator.rb`:

```ruby
  def self.save_annotations(employer, annotations_json, overwrite_flag, cli_instance)
    cli_instance.with_overwrite_check(employer.annotations_path, overwrite_flag) do
      File.write(employer.annotations_path, annotations_json)
    end
  end
```

**Step 4: Update annotate command in CLI**

In `lib/jojo/cli.rb`:

```ruby
    AnnotationGenerator.save_annotations(employer, annotations, options[:overwrite], self)
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/annotate_overwrite_test.rb`
Expected: PASS

**Step 6: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/generators/annotation_generator.rb lib/jojo/cli.rb test/integration/annotate_overwrite_test.rb
git commit -m "feat: update annotation generator to use global overwrite behavior"
```

---

## Task 16: Update jojo generate Command (Multi-file Behavior)

**Files:**
- Modify: `lib/jojo/cli.rb` (generate command)
- Create: `test/integration/generate_overwrite_test.rb`

**Step 1: Write integration test for multi-file behavior**

```ruby
# test/integration/generate_overwrite_test.rb
require "test_helper"

class GenerateOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
    File.write("employers/test-employer/inputs/projects.yml", "projects:\n  - name: Test")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_generate_prompts_for_each_existing_file
    # Create some existing files
    File.write("employers/test-employer/research.md", "existing research")
    File.write("employers/test-employer/resume.md", "existing resume")

    cli = Jojo::CLI.new
    prompts = []
    def cli.yes?(msg)
      @prompts ||= []
      @prompts << msg
      # Say no to research, yes to resume
      msg.include?("research.md") ? false : true
    end
    cli.options = { slug: "test-employer" }

    Jojo::LLMClient.stub :call, "new content" do
      capture_io { cli.generate }
    end

    # Research should not be overwritten (said no)
    assert_equal "existing research", File.read("employers/test-employer/research.md")

    # Resume should be overwritten (said yes)
    assert_equal "new content", File.read("employers/test-employer/resume.md")
  end

  def test_generate_with_overwrite_flag_overwrites_all
    File.write("employers/test-employer/research.md", "existing research")
    File.write("employers/test-employer/resume.md", "existing resume")

    cli = Jojo::CLI.new
    cli.options = { slug: "test-employer", overwrite: true }

    Jojo::LLMClient.stub :call, "new content" do
      capture_io { cli.generate }
    end

    # Both should be overwritten
    assert_equal "new content", File.read("employers/test-employer/research.md")
    assert_equal "new content", File.read("employers/test-employer/resume.md")
  end
end
```

**Step 2: Run test to verify current behavior**

Run: `ruby -Ilib:test test/integration/generate_overwrite_test.rb`
Expected: Should mostly work since we updated individual generators

**Step 3: Verify generate command passes overwrite flag to all generators**

Check `lib/jojo/cli.rb` generate command and ensure all generator calls include `options[:overwrite], self`:

```ruby
    ResearchGenerator.save_research(employer, research, options[:overwrite], self)
    ResumeGenerator.save_resume(employer, resume, options[:overwrite], self)
    CoverLetterGenerator.save_cover_letter(employer, cover_letter, options[:overwrite], self)
    WebsiteGenerator.save_website(employer, website, options[:overwrite], self)
    AnnotationGenerator.save_annotations(employer, annotations, options[:overwrite], self)
    # ... and any other generators
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/generate_overwrite_test.rb`
Expected: PASS

**Step 5: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/jojo/cli.rb test/integration/generate_overwrite_test.rb
git commit -m "feat: update generate command to use global overwrite behavior"
```

---

## Task 17: Test JOJO_ALWAYS_OVERWRITE Environment Variable

**Files:**
- Create: `test/integration/env_overwrite_test.rb`

**Step 1: Write integration tests for environment variable**

```ruby
# test/integration/env_overwrite_test.rb
require "test_helper"

class EnvOverwriteTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @old_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    File.write("config.yml", "llm:\n  provider: anthropic\n")
    FileUtils.mkdir_p("employers/test-employer/inputs")
    File.write("employers/test-employer/inputs/job_description.md", "job")
    File.write("employers/test-employer/inputs/profile.md", "profile")
  end

  def teardown
    Dir.chdir(@old_pwd)
    FileUtils.rm_rf(@test_dir)
  end

  def test_env_var_true_overwrites_without_prompting
    File.write("employers/test-employer/research.md", "existing")

    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      cli = Jojo::CLI.new
      cli.options = { slug: "test-employer" }

      Jojo::LLMClient.stub :call, "new research" do
        capture_io { cli.research }
      end

      assert_equal "new research", File.read("employers/test-employer/research.md")
    end
  end

  def test_no_overwrite_flag_blocks_env_var
    File.write("employers/test-employer/research.md", "existing")

    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      cli = Jojo::CLI.new
      def cli.yes?(msg); false; end
      cli.options = { slug: "test-employer", overwrite: false }

      Jojo::LLMClient.stub :call, "new research" do
        capture_io { cli.research }
      end

      # Should still be existing because --no-overwrite blocks env var
      assert_equal "existing", File.read("employers/test-employer/research.md")
    end
  end

  private

  def with_env(env_vars)
    old_values = {}
    env_vars.each do |key, value|
      old_values[key] = ENV[key]
      ENV[key] = value
    end
    yield
  ensure
    old_values.each do |key, value|
      ENV[key] = value
    end
  end
end
```

**Step 2: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/env_overwrite_test.rb`
Expected: PASS

**Step 3: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add test/integration/env_overwrite_test.rb
git commit -m "test: add integration tests for JOJO_ALWAYS_OVERWRITE env var"
```

---

## Task 18: Update Help Text and Documentation

**Files:**
- Modify: `lib/jojo/cli.rb`
- Modify: `README.md` (if it exists and documents CLI usage)

**Step 1: Verify global option help text**

Run: `./bin/jojo help`
Expected: Should show `--overwrite` in global options

**Step 2: Update individual command descriptions if needed**

In `lib/jojo/cli.rb`, ensure command descriptions don't mention command-specific overwrite behavior:

- Remove any mentions of command-specific `--overwrite` or `-o` flags in desc strings
- Update examples if they reference old behavior

**Step 3: Update README.md if it exists**

Add section about overwrite behavior:

```markdown
### Overwriting Files

By default, jojo prompts before overwriting existing files:

```bash
jojo research --slug acme-corp
# If research.md exists: "research.md exists. Overwrite? (y/n)"
```

To skip prompts and overwrite automatically:

```bash
# Using flag
jojo research --slug acme-corp --overwrite

# Using environment variable (useful for CI/CD)
export JOJO_ALWAYS_OVERWRITE=true
jojo generate --slug acme-corp

# Force prompting even with env var set
jojo research --slug acme-corp --no-overwrite
```

**Precedence order:**
1. `--overwrite` flag → always overwrites
2. `--no-overwrite` flag → always prompts
3. `JOJO_ALWAYS_OVERWRITE=true` → overwrites
4. Default → prompts
```

**Step 4: Verify help output**

Run: `./bin/jojo help new`
Run: `./bin/jojo help research`
Run: `./bin/jojo help generate`
Expected: No mentions of command-specific overwrite flags

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb README.md
git commit -m "docs: update help text and README for global overwrite option"
```

---

## Task 19: Final Testing and Verification

**Files:**
- None (testing only)

**Step 1: Run full test suite**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 2: Manual smoke test - jojo new**

```bash
cd /tmp
mkdir jojo-smoke-test
cd jojo-smoke-test

# First time - should create without prompt
jojo new --slug test-company

# Second time - should prompt
jojo new --slug test-company
# Type 'n' to cancel

# With --overwrite flag
jojo new --slug test-company --overwrite
# Should succeed without prompt
```

**Step 3: Manual smoke test - content generators**

```bash
# Setup
echo "Job description" > employers/test-company/inputs/job_description.md
echo "Profile" > employers/test-company/inputs/profile.md

# Generate research - should create
jojo research --slug test-company

# Try again - should prompt
jojo research --slug test-company
# Type 'n'

# With env var
export JOJO_ALWAYS_OVERWRITE=true
jojo research --slug test-company
# Should overwrite without prompt

# With --no-overwrite (overrides env)
jojo research --slug test-company --no-overwrite
# Should prompt even with env var set
```

**Step 4: Test non-TTY behavior**

```bash
# Should fail with helpful error
echo "n" | jojo research --slug test-company 2>&1 | grep "Cannot prompt"

# Should succeed with flag
echo "n" | jojo research --slug test-company --overwrite
```

**Step 5: Clean up**

```bash
cd /tmp
rm -rf jojo-smoke-test
```

**Step 6: Document test results**

Create a simple test report:

```bash
cat > test_results.md <<EOF
# Global Overwrite Option - Test Results

Date: $(date)

## Unit Tests
- OverwriteHelper: PASS

## Integration Tests
- jojo new: PASS
- jojo setup: PASS
- jojo research: PASS
- jojo resume: PASS
- jojo cover_letter: PASS
- jojo website: PASS
- jojo annotate: PASS
- jojo generate: PASS
- Environment variable: PASS

## Manual Smoke Tests
- Prompting behavior: PASS
- --overwrite flag: PASS
- --no-overwrite flag: PASS
- JOJO_ALWAYS_OVERWRITE: PASS
- Non-TTY error: PASS

## Notes
[Any observations or issues]
EOF
```

**Step 7: Commit test results**

```bash
git add test_results.md
git commit -m "test: add verification results for global overwrite option"
```

---

## Completion Checklist

- [ ] OverwriteHelper module created with full test coverage
- [ ] Global `--overwrite` option added to CLI
- [ ] All commands updated to use `with_overwrite_check`
- [ ] Integration tests for all commands
- [ ] Environment variable support verified
- [ ] Non-TTY error handling tested
- [ ] Help text and documentation updated
- [ ] Full test suite passes
- [ ] Manual smoke tests completed
- [ ] All commits follow conventional commit format

---

## Post-Implementation

After completing all tasks, use @superpowers:verification-before-completion to verify:
- All tests pass
- No regressions in existing functionality
- Documentation is complete
- Code follows project conventions
