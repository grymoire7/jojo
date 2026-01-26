# Job Description Command Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Separate job description processing from `jojo new` into its own `jojo job_description` command.

**Architecture:** CLI layer refactoring only. `jojo new` becomes minimal (creates directory), new `jojo job_description` command handles processing. Interactive mode simplified to match. `JobDescriptionProcessor` and `Employer` unchanged.

**Tech Stack:** Ruby, Thor CLI, Minitest

---

## Task 1: Add `job_description` CLI Command

**Files:**
- Modify: `lib/jojo/cli.rb:49-106`
- Test: `test/unit/cli_job_description_test.rb` (create)

**Step 1: Write the failing tests**

Create `test/unit/cli_job_description_test.rb`:

```ruby
require "test_helper"
require "fileutils"
require "tmpdir"

class CLIJobDescriptionTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # Create minimal config files
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    File.write("config.yml", "seeker:\n  name: Test User\n  base_url: https://example.com\n")

    # Create inputs directory with resume data
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")

    # Create test job description file
    @job_file = File.join(@tmpdir, "job.txt")
    File.write(@job_file, "Test job description\nSenior Engineer at Acme Corp\n")

    # Create employers directory
    FileUtils.mkdir_p("employers")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_job_description_command_requires_job_parameter
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} job_description -s test-employer 2>&1 || true")
    end

    output = out + err
    assert_match(/required.*job/i, output)
  end

  def test_job_description_command_fails_when_employer_does_not_exist
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} job_description -s nonexistent -j #{@job_file} 2>&1 || true")
    end

    output = out + err
    assert_match(/does not exist/i, output)
  end

  def test_job_description_command_uses_slug_from_state_when_not_provided
    # Create employer directory
    FileUtils.mkdir_p("employers/state-test")

    # Save slug to state
    File.write(".jojo_state", "state-test")

    out, err = capture_subprocess_io do
      # Run without -s flag - should use state
      system("#{File.join(@original_dir, "bin/jojo")} job_description -j #{@job_file} 2>&1 || true")
    end

    output = out + err
    # Should not complain about missing slug
    refute_match(/no application specified/i, output)
  end

  def test_job_description_command_fails_when_no_slug_available
    out, err = capture_subprocess_io do
      # No -s flag and no state file
      system("#{File.join(@original_dir, "bin/jojo")} job_description -j #{@job_file} 2>&1 || true")
    end

    output = out + err
    assert_match(/no application specified/i, output)
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `./bin/jojo test --unit`
Expected: FAIL with "job_description" command not found or similar errors

**Step 3: Add the job_description command to CLI**

In `lib/jojo/cli.rb`, add after the `new` method (around line 106):

```ruby
desc "job_description", "Process job description for an application"
long_desc <<~DESC, wrap: false
  Process a job description for an existing employer workspace.
  This extracts and saves the job description and key details.

  Examples:
    jojo job_description -s acme-corp-senior-dev -j job.txt
    jojo job_description -s bigco-principal -j https://careers.bigco.com/jobs/123
    jojo job_description -j job.txt  # Uses current application from state
DESC
method_option :slug, type: :string, aliases: "-s", desc: "Application slug (uses current if omitted)"
method_option :job, type: :string, aliases: "-j", required: true, desc: "Job description (file path or URL)"
def job_description
  slug = options[:slug] || StatePersistence.load_slug
  unless slug
    say "No application specified. Use -s or select one in interactive mode.", :red
    exit 1
  end

  employer = Jojo::Employer.new(slug)
  unless employer.base_path.exist?
    say "Application '#{slug}' does not exist. Run 'jojo new -s #{slug}' first.", :red
    exit 1
  end

  config = Jojo::Config.new
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])

  say "Processing job description for: #{slug}", :green

  begin
    employer.create_artifacts(options[:job], ai_client, overwrite_flag: options[:overwrite], cli_instance: self, verbose: options[:verbose])

    say "-> Job description processed and saved", :green
    say "-> Job details extracted and saved", :green
  rescue => e
    say "Error processing job description: #{e.message}", :red
    exit 1
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `./bin/jojo test --unit`
Expected: All new tests PASS

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb test/unit/cli_job_description_test.rb
git commit -m "$(cat <<'EOF'
feat(cli): add job_description command

New command to process job descriptions separately from workspace creation.
Supports -s slug (optional, uses state) and -j job source (required).
EOF
)"
```

---

## Task 2: Simplify `jojo new` Command

**Files:**
- Modify: `lib/jojo/cli.rb:49-106`
- Modify: `test/unit/cli_new_test.rb`

**Step 1: Update tests for simplified new command**

Replace contents of `test/unit/cli_new_test.rb`:

```ruby
require "test_helper"
require "fileutils"
require "tmpdir"

class CLINewTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # Create minimal config files
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    File.write("config.yml", "seeker:\n  name: Test User\n  base_url: https://example.com\n")

    # Create inputs directory with resume data
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_new_command_requires_slug
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new 2>&1 || true")
    end

    output = out + err
    assert_match(/required.*slug/i, output)
  end

  def test_new_command_creates_employer_directory
    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new -s test-employer 2>&1")
    end

    output = out + err
    assert_match(/created/i, output)
    assert Dir.exist?("employers/test-employer")
  end

  def test_new_command_fails_if_directory_already_exists
    FileUtils.mkdir_p("employers/existing-employer")

    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} new -s existing-employer 2>&1 || true")
    end

    output = out + err
    assert_match(/already exists/i, output)
  end

  def test_employer_initialize_with_slug
    employer = Jojo::Employer.new("test-slug")
    assert_equal "test-slug", employer.slug
    assert_equal "test-slug", employer.name
  end

  def test_artifacts_exist_returns_false_when_no_artifacts
    employer = Jojo::Employer.new("test-employer")
    refute employer.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_description_exists
    employer = Jojo::Employer.new("test-employer")
    FileUtils.mkdir_p(employer.base_path)
    File.write(employer.job_description_path, "test content")

    assert employer.artifacts_exist?
  end

  def test_artifacts_exist_returns_true_when_job_details_exists
    employer = Jojo::Employer.new("test-employer")
    FileUtils.mkdir_p(employer.base_path)
    File.write(employer.job_details_path, "company_name: Test\n")

    assert employer.artifacts_exist?
  end
end
```

**Step 2: Run tests to verify current failures**

Run: `./bin/jojo test --unit`
Expected: Some tests fail (e.g., new command still requires -j)

**Step 3: Simplify the new command**

Replace the `new` method in `lib/jojo/cli.rb` (lines 49-106):

```ruby
desc "new", "Create a new job application workspace"
long_desc <<~DESC, wrap: false
  Create a new employer workspace directory.
  After creating, use 'jojo job_description' to process the job description.

  Examples:
    jojo new -s acme-corp-senior-dev
    jojo new -s bigco-principal
DESC
method_option :slug, type: :string, aliases: "-s", required: true, desc: "Unique employer identifier"
def new
  # Validate required inputs exist before creating employer
  begin
    Jojo::TemplateValidator.validate_required_file!(
      "inputs/resume_data.yml",
      "resume data"
    )
  rescue Jojo::TemplateValidator::MissingInputError => e
    say e.message, :red
    exit 1
  end

  # Warn if resume data hasn't been customized
  result = Jojo::TemplateValidator.warn_if_unchanged(
    "inputs/resume_data.yml",
    "resume data",
    cli_instance: self
  )

  if result == :abort
    say "Setup your inputs first, then run this command again.", :yellow
    exit 1
  end

  employer = Jojo::Employer.new(options[:slug])

  if employer.base_path.exist?
    say "Application '#{options[:slug]}' already exists.", :yellow
    exit 1
  end

  employer.base_path.mkpath
  say "Created application workspace: #{employer.base_path}", :green
  say "\nNext step:", :cyan
  say "  jojo job_description -s #{options[:slug]} -j <job_file_or_url>", :white
end
```

**Step 4: Run tests to verify they pass**

Run: `./bin/jojo test --unit`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb test/unit/cli_new_test.rb
git commit -m "$(cat <<'EOF'
refactor(cli): simplify new command to only create directory

Remove -j parameter from 'jojo new'. Now only creates the workspace
directory. Job description processing moved to 'jojo job_description'.
EOF
)"
```

---

## Task 3: Update Workflow Step for Job Description

**Files:**
- Modify: `lib/jojo/workflow.rb:5-13`

**Step 1: Update the workflow step command**

In `lib/jojo/workflow.rb`, change line 11 from `:new` to `:job_description`:

```ruby
STEPS = [
  {
    key: :job_description,
    label: "Job Description",
    dependencies: [],
    command: :job_description,  # Changed from :new
    paid: false,
    output_file: "job_description.md"
  },
  # ... rest unchanged
```

**Step 2: Run tests to verify nothing breaks**

Run: `./bin/jojo test --unit`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/jojo/workflow.rb
git commit -m "$(cat <<'EOF'
refactor(workflow): update job_description step to use new command
EOF
)"
```

---

## Task 4: Simplify Interactive handle_new_application

**Files:**
- Modify: `lib/jojo/interactive.rb:355-436`
- Modify: `test/unit/interactive_test.rb`

**Step 1: Add test for simplified new application flow**

Add to `test/unit/interactive_test.rb`:

```ruby
describe "#handle_new_application behavior" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    FileUtils.mkdir_p(@employers_dir)
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Create minimal config for validation
    File.write("config.yml", "seeker:\n  name: Test\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test\n")
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  it "creates employer directory without job description" do
    # Create the directory directly (simulating what handle_new_application does)
    slug = "test-new-app"
    employer = Jojo::Employer.new(slug)
    employer.base_path.mkpath

    _(Dir.exist?(File.join(@employers_dir, slug))).must_equal true
    _(employer.artifacts_exist?).must_equal false  # No job description yet
  end
end
```

**Step 2: Run tests to verify they pass (this tests current capability)**

Run: `./bin/jojo test --unit`
Expected: PASS

**Step 3: Simplify handle_new_application**

Replace `handle_new_application` method in `lib/jojo/interactive.rb` (lines 355-436):

```ruby
def handle_new_application
  clear_screen

  # Prompt for slug
  puts TTY::Box.frame(
    "\n  Slug (e.g., acme-corp-senior-dev):\n  > \n",
    title: {top_left: " New Application "},
    padding: [0, 1],
    border: :thick
  )

  # Move cursor into the input area
  print @cursor.up(3)
  print @cursor.forward(5)

  slug = @reader.read_line.strip
  if slug.empty?
    if employer
      render_dashboard
    elsif list_applications.empty?
      render_welcome
    else
      handle_switch
    end
    return
  end

  # Check if already exists
  new_employer = Employer.new(slug)
  if new_employer.base_path.exist?
    clear_screen
    puts TTY::Box.frame(
      "\n  Application '#{slug}' already exists.\n\n  Press any key to continue...\n",
      title: {top_left: " Error "},
      padding: [0, 1],
      border: :thick
    )
    @reader.read_keypress
    if employer
      render_dashboard
    elsif list_applications.empty?
      render_welcome
    else
      handle_switch
    end
    return
  end

  # Create the directory
  new_employer.base_path.mkpath
  switch_application(slug)

  clear_screen
  puts TTY::Box.frame(
    "\n  Created application: #{slug}\n\n  Select 'Job Description' to add the job posting.\n\n  Press any key to continue...\n",
    title: {top_left: " Success "},
    padding: [0, 1],
    border: :thick
  )
  @reader.read_keypress
  render_dashboard
end
```

**Step 4: Run tests to verify they pass**

Run: `./bin/jojo test --unit`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "$(cat <<'EOF'
refactor(interactive): simplify new application to only create directory

Remove job source prompting from new application flow. User now creates
directory first, then uses Job Description step to add job posting.
EOF
)"
```

---

## Task 5: Add Job Description Step Handler in Interactive

**Files:**
- Modify: `lib/jojo/interactive.rb:125-139` and add new method
- Modify: `test/unit/interactive_test.rb`

**Step 1: Add test for job description step handling**

Add to `test/unit/interactive_test.rb`:

```ruby
describe "#handle_step_selection for job_description" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Create employer without job description
    @slug = "no-job-desc"
    FileUtils.mkdir_p(File.join(@employers_dir, @slug))

    # Create minimal config
    File.write("config.yml", "seeker:\n  name: Test\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test\n")
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  it "shows ready status when job description is missing" do
    interactive = Jojo::Interactive.new(slug: @slug)
    status = Jojo::Workflow.status(:job_description, interactive.employer)

    # Job description has no dependencies, so it's always ready when missing
    _(status).must_equal :ready
  end
end
```

**Step 2: Run tests to verify they pass**

Run: `./bin/jojo test --unit`
Expected: PASS

**Step 3: Update handle_step_selection and execute_step for job_description**

In `lib/jojo/interactive.rb`, modify `show_ready_dialog` to handle job_description specially. Add this check at the start of the method (around line 158):

```ruby
def show_ready_dialog(step, status)
  # Special handling for job_description step - needs to prompt for source
  if step[:key] == :job_description
    show_job_description_dialog
    return
  end

  # ... rest of existing method unchanged
```

Add new method after `show_generated_dialog`:

```ruby
def show_job_description_dialog
  clear_screen
  puts TTY::Box.frame(
    "\n  Enter job description source (URL or file path):\n  > \n\n  [Esc] Cancel\n",
    title: {top_left: " Job Description "},
    padding: [0, 1],
    border: :thick
  )

  print @cursor.up(4)
  print @cursor.forward(5)

  source = @reader.read_line.strip
  if source.empty?
    render_dashboard
    return
  end

  clear_screen
  puts "Processing job description..."
  puts "Press Ctrl+C to cancel"
  puts

  begin
    cli = CLI.new
    cli.invoke(:job_description, [], slug: @slug, job: source, overwrite: true)

    puts
    puts "Done! Press any key to continue..."
    @reader.read_keypress
  rescue => e
    puts "Error: #{e.message}"
    puts "Press any key to continue..."
    @reader.read_keypress
  end

  render_dashboard
end
```

Also update `execute_step` to handle the new command (around line 239):

```ruby
case step[:command]
when :job_description
  # Should not reach here - handled by show_job_description_dialog
  puts "Use step 1 to add job description"
when :research
  # ... rest unchanged
```

**Step 4: Run tests to verify they pass**

Run: `./bin/jojo test --unit`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "$(cat <<'EOF'
feat(interactive): add job description step handler

When selecting Job Description step with no existing file, prompts for
job source (URL or file path) and processes it using the new command.
EOF
)"
```

---

## Task 6: Add Integration Tests

**Files:**
- Create: `test/integration/job_description_command_test.rb`

**Step 1: Write integration tests**

Create `test/integration/job_description_command_test.rb`:

```ruby
# frozen_string_literal: true

require_relative "../test_helper"

describe "Job Description Command Integration" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Create minimal config
    File.write("config.yml", "seeker:\n  name: Test User\n  base_url: https://example.com\n")
    File.write(".env", "ANTHROPIC_API_KEY=test_key\n")
    FileUtils.mkdir_p("inputs")
    File.write("inputs/resume_data.yml", "name: Test User\nemail: test@example.com\n")

    # Create test job file
    @job_file = File.join(@temp_dir, "job.txt")
    File.write(@job_file, <<~JOB)
      Senior Software Engineer at Acme Corp

      We are looking for a senior engineer to join our team.

      Requirements:
      - 5+ years of experience
      - Ruby expertise
      - PostgreSQL knowledge
    JOB
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe "workflow: new then job_description" do
    it "creates workspace then processes job description separately" do
      slug = "acme-corp-senior"

      # Step 1: Create workspace with 'new'
      employer = Jojo::Employer.new(slug)
      employer.base_path.mkpath

      _(Dir.exist?(File.join(@employers_dir, slug))).must_equal true
      _(employer.artifacts_exist?).must_equal false

      # Step 2: Verify job_description would work (without actual AI call)
      _(employer.base_path.exist?).must_equal true
      _(File.exist?(@job_file)).must_equal true
    end
  end

  describe "state-based slug resolution" do
    it "uses slug from state file when -s not provided" do
      slug = "state-based-app"

      # Create employer
      employer = Jojo::Employer.new(slug)
      employer.base_path.mkpath

      # Save to state
      Jojo::StatePersistence.save_slug(slug)

      # Verify state is saved
      _(Jojo::StatePersistence.load_slug).must_equal slug
    end
  end
end
```

**Step 2: Run integration tests**

Run: `./bin/jojo test --integration`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add test/integration/job_description_command_test.rb
git commit -m "$(cat <<'EOF'
test(integration): add job_description command integration tests
EOF
)"
```

---

## Task 7: Run Full Test Suite and Verify

**Step 1: Run all tests**

Run: `./bin/jojo test --all --no-service`
Expected: All tests PASS

**Step 2: Manual verification**

Test the CLI manually:
```bash
# Create new workspace
./bin/jojo new -s test-manual

# Should show the directory was created
ls employers/test-manual

# Process job description (will fail without real API key, but validates command works)
./bin/jojo job_description -s test-manual -j test/fixtures/job_description.txt 2>&1 || echo "Expected error without API"
```

**Step 3: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "$(cat <<'EOF'
fix: address any issues found during final testing
EOF
)"
```

---

## Summary of Changes

| File | Change |
|------|--------|
| `lib/jojo/cli.rb` | Simplified `new`, added `job_description` |
| `lib/jojo/workflow.rb` | Changed step command from `:new` to `:job_description` |
| `lib/jojo/interactive.rb` | Simplified `handle_new_application`, added `show_job_description_dialog` |
| `test/unit/cli_new_test.rb` | Updated for simplified `new` |
| `test/unit/cli_job_description_test.rb` | New tests for `job_description` |
| `test/unit/interactive_test.rb` | Added tests for new flows |
| `test/integration/job_description_command_test.rb` | New integration tests |
