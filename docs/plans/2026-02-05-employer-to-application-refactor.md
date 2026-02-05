# Employer to Application Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename the "Employer" concept to "Application" throughout the codebase to better reflect that this represents a job application, not an employer entity.

**Architecture:** This is a naming refactor that touches class names, method names, instance variables, directory names, environment variables, and documentation. We'll use a phased approach: first internal code changes with backward compatibility, then directory migration with user data preservation, then cleanup.

**Tech Stack:** Ruby, Thor CLI framework, YAML configuration

---

## Scope and Decisions

### What Gets Renamed

| From | To |
|------|-----|
| `Jojo::Employer` class | `Jojo::Application` class |
| `employer.rb` file | `application.rb` file |
| `@employer` instance variables | `@application` instance variables |
| `def employer` methods | `def application` methods |
| `require_employer!` method | `require_application!` method |
| `employers/` directory | `applications/` directory |
| `JOJO_EMPLOYER_SLUG` env var | `JOJO_APPLICATION_SLUG` env var (with backward compat) |
| CLI `--slug` description | Updated to mention "application" |

### Backward Compatibility Strategy

1. **Environment variable:** Support both `JOJO_APPLICATION_SLUG` (new) and `JOJO_EMPLOYER_SLUG` (deprecated) for one release cycle
2. **Directory:** Support reading from both `applications/` (new) and `employers/` (legacy) directories, with automatic migration prompt
3. **No data loss:** Existing `employers/` directories with user data are preserved and migrated safely

---

## Task 1: Create Application Class (Core Model)

**Files:**
- Create: `lib/jojo/application.rb`
- Modify: `lib/jojo.rb:13`
- Test: `test/unit/application_test.rb`

**Step 1.1: Write the failing test for Application class**

Create `test/unit/application_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"
require "jojo/application"

describe Jojo::Application do
  describe "#initialize" do
    it "sets slug and base_path" do
      app = Jojo::Application.new("acme-corp")

      _(app.slug).must_equal "acme-corp"
      _(app.base_path).must_equal "applications/acme-corp"
    end
  end

  describe "path accessors" do
    let(:app) { Jojo::Application.new("test-app") }

    it "returns job_description_raw_path" do
      _(app.job_description_raw_path).must_equal "applications/test-app/job_description_raw.md"
    end

    it "returns job_description_path" do
      _(app.job_description_path).must_equal "applications/test-app/job_description.md"
    end

    it "returns job_details_path" do
      _(app.job_details_path).must_equal "applications/test-app/job_details.yml"
    end

    it "returns resume_path" do
      _(app.resume_path).must_equal "applications/test-app/resume.md"
    end

    it "returns cover_letter_path" do
      _(app.cover_letter_path).must_equal "applications/test-app/cover_letter.md"
    end

    it "returns research_path" do
      _(app.research_path).must_equal "applications/test-app/research.md"
    end

    it "returns website_path" do
      _(app.website_path).must_equal "applications/test-app/website"
    end

    it "returns faq_path" do
      _(app.faq_path).must_equal "applications/test-app/faq.json"
    end
  end

  describe "#company_name" do
    it "returns slug when job_details.yml does not exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          app = Jojo::Application.new("acme-corp")
          _(app.company_name).must_equal "acme-corp"
        end
      end
    end

    it "returns company_name from job_details.yml when it exists" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("applications/acme-corp")
          File.write("applications/acme-corp/job_details.yml", "company_name: Acme Corporation")

          app = Jojo::Application.new("acme-corp")
          _(app.company_name).must_equal "Acme Corporation"
        end
      end
    end
  end

  describe "#artifacts_exist?" do
    it "returns false when no artifacts exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          app = Jojo::Application.new("new-app")
          _(app.artifacts_exist?).must_equal false
        end
      end
    end

    it "returns true when job_description.md exists" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("applications/existing-app")
          File.write("applications/existing-app/job_description.md", "# Job")

          app = Jojo::Application.new("existing-app")
          _(app.artifacts_exist?).must_equal true
        end
      end
    end
  end

  describe "#create_directory!" do
    it "creates base_path and website_path directories" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          app = Jojo::Application.new("new-app")
          app.create_directory!

          _(File.directory?("applications/new-app")).must_equal true
          _(File.directory?("applications/new-app/website")).must_equal true
        end
      end
    end
  end
end
```

**Step 1.2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/application_test.rb`
Expected: FAIL - cannot load such file -- jojo/application

**Step 1.3: Create Application class**

Create `lib/jojo/application.rb`:

```ruby
require "fileutils"
require "yaml"

module Jojo
  class Application
    attr_reader :name, :slug, :base_path

    def initialize(slug)
      @slug = slug
      @name = slug  # Will be updated from job_details.yml if it exists
      @base_path = File.join("applications", @slug)
    end

    def job_description_raw_path = File.join(base_path, "job_description_raw.md")
    def job_description_path = File.join(base_path, "job_description.md")
    def job_description_annotations_path = File.join(base_path, "job_description_annotations.json")
    def job_details_path = File.join(base_path, "job_details.yml")
    def research_path = File.join(base_path, "research.md")
    def resume_path = File.join(base_path, "resume.md")
    def branding_path = File.join(base_path, "branding.md")
    def cover_letter_path = File.join(base_path, "cover_letter.md")
    def resume_pdf_path = File.join(base_path, "resume.pdf")
    def cover_letter_pdf_path = File.join(base_path, "cover_letter.pdf")
    def status_log_path = File.join(base_path, "status.log")
    def website_path = File.join(base_path, "website")
    def faq_path = File.join(base_path, "faq.json")
    def index_html_path = File.join(website_path, "index.html")

    def job_details
      return {} unless File.exist?(job_details_path)

      YAML.load_file(job_details_path) || {}
    rescue
      {}
    end

    def company_name
      job_details["company_name"] || @name
    end

    def status_logger
      @status_logger ||= Jojo::StatusLogger.new(status_log_path)
    end

    def create_directory!
      FileUtils.mkdir_p(base_path)
      FileUtils.mkdir_p(website_path)
    end

    def create_artifacts(job_source, ai_client, overwrite_flag: nil, cli_instance: nil, verbose: false)
      create_directory!

      require_relative "commands/job_description/processor"
      processor = Commands::JobDescription::Processor.new(self, ai_client, overwrite_flag: overwrite_flag, cli_instance: cli_instance, verbose: verbose)
      processor.process(job_source)
    end

    def artifacts_exist?
      File.exist?(job_description_path) || File.exist?(job_details_path)
    end

    private

    def remove_artifacts
      [
        job_description_raw_path,
        job_description_path,
        job_details_path,
        job_description_annotations_path,
        research_path,
        resume_path,
        cover_letter_path,
        status_log_path,
        faq_path
      ].each do |path|
        FileUtils.rm_f(path) if File.exist?(path)
      end
    end
  end
end
```

**Step 1.4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/application_test.rb`
Expected: PASS - all tests green

**Step 1.5: Update lib/jojo.rb to require application**

In `lib/jojo.rb`, add after line 12:

```ruby
require_relative "jojo/application"
```

**Step 1.6: Commit**

```bash
git add lib/jojo/application.rb test/unit/application_test.rb lib/jojo.rb
git commit -m "$(cat <<'EOF'
feat: add Application class as successor to Employer

Create new Application class with same interface as Employer but using
applications/ directory. This is the first step in renaming Employer
to Application throughout the codebase.
EOF
)"
```

---

## Task 2: Update Commands Base Class

**Files:**
- Modify: `lib/jojo/commands/base.rb`
- Test: `test/unit/commands/base_test.rb`

**Step 2.1: Write failing test for application method**

Add to `test/unit/commands/base_test.rb` in the appropriate describe block:

```ruby
describe "#application" do
  before do
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_details.yml", "company_name: Acme")
  end

  after do
    FileUtils.rm_rf("applications")
  end

  it "creates application from slug" do
    command = TestCommand.new(mock_cli, slug: "acme-corp")

    _(command.send(:application)).must_be_instance_of Jojo::Application
    _(command.send(:application).slug).must_equal "acme-corp"
  end

  it "caches application instance" do
    command = TestCommand.new(mock_cli, slug: "acme-corp")

    first_call = command.send(:application)
    second_call = command.send(:application)

    _(first_call).must_be_same_as second_call
  end
end

describe "#require_application!" do
  it "passes when application artifacts exist" do
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_description.md", "# Job")

    command = TestCommand.new(mock_cli, slug: "acme-corp")
    # Should not raise
    command.send(:require_application!)

    FileUtils.rm_rf("applications")
  end

  it "exits when application does not exist" do
    command = TestCommand.new(mock_cli, slug: "nonexistent")

    assert_raises(SystemExit) do
      command.send(:require_application!)
    end
  end
end
```

**Step 2.2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: FAIL - undefined method `application`

**Step 2.3: Update base.rb with application method**

In `lib/jojo/commands/base.rb`:

1. Change require from employer to application (line 2):
```ruby
require_relative "../application"
```

2. Change parameter name in initialize (line 12):
```ruby
def initialize(cli, ai_client: nil, application: nil, **options)
```

3. Change instance variable (line 16):
```ruby
@application = application
```

4. Change method name and implementation (lines 36-38):
```ruby
def application
  @application ||= Jojo::Application.new(slug)
end
```

5. Change require_employer! to require_application! (lines 53-59):
```ruby
def require_application!
  return if application.artifacts_exist?

  say "Application '#{slug}' not found.", :red
  say "  Run 'jojo new -s #{slug}' to create it.", :yellow
  exit 1
end
```

6. Update status_logger to use application (line 72):
```ruby
def status_logger
  @status_logger ||= application.status_logger
end
```

**Step 2.4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/commands/base_test.rb`
Expected: PASS

**Step 2.5: Commit**

```bash
git add lib/jojo/commands/base.rb test/unit/commands/base_test.rb
git commit -m "$(cat <<'EOF'
refactor: rename employer to application in Commands::Base

- Change require from employer to application
- Rename @employer to @application instance variable
- Rename employer method to application
- Rename require_employer! to require_application!
EOF
)"
```

---

## Task 3: Update All Generator Classes

**Files:**
- Modify: `lib/jojo/commands/job_description/processor.rb`
- Modify: `lib/jojo/commands/job_description/command.rb`
- Modify: `lib/jojo/commands/new/command.rb`
- Modify: `lib/jojo/commands/research/generator.rb`
- Modify: `lib/jojo/commands/resume/generator.rb`
- Modify: `lib/jojo/commands/cover_letter/generator.rb`
- Modify: `lib/jojo/commands/branding/generator.rb`
- Modify: `lib/jojo/commands/faq/generator.rb`
- Modify: `lib/jojo/commands/website/generator.rb`
- Modify: `lib/jojo/commands/annotate/generator.rb`
- Modify: `lib/jojo/commands/pdf/converter.rb`
- Modify: `lib/jojo/project_selector.rb`

For each file, use find-and-replace:
- `@employer` → `@application`
- `attr_reader :employer` → `attr_reader :application`
- `def initialize(employer,` → `def initialize(application,`
- `employer.` → `application.`

**Step 3.1: Update job_description/processor.rb**

Replace all occurrences of `employer` with `application` (instance variable, parameter, and method calls).

**Step 3.2: Update job_description/command.rb**

Replace `@employer` with `@application`, `Jojo::Employer.new` with `Jojo::Application.new`, and `employer.` with `application.`.

**Step 3.3: Update new/command.rb**

Replace `employer.` with `application.`.

**Step 3.4-3.11: Update remaining generators**

Apply same pattern to:
- research/generator.rb
- resume/generator.rb
- cover_letter/generator.rb
- branding/generator.rb
- faq/generator.rb
- website/generator.rb
- annotate/generator.rb
- pdf/converter.rb
- project_selector.rb

**Step 3.12: Run all unit tests**

Run: `./bin/jojo test --unit`
Expected: All tests pass (or identify tests needing updates)

**Step 3.13: Commit**

```bash
git add lib/jojo/commands/ lib/jojo/project_selector.rb
git commit -m "$(cat <<'EOF'
refactor: rename employer to application in all generators

Update all generator and command classes to use @application instead
of @employer, matching the renamed Application class.
EOF
)"
```

---

## Task 4: Update Interactive Commands

**Files:**
- Modify: `lib/jojo/commands/interactive/runner.rb`
- Modify: `lib/jojo/commands/interactive/workflow.rb`
- Modify: `lib/jojo/commands/interactive/dashboard.rb`

**Step 4.1: Update runner.rb**

In `lib/jojo/commands/interactive/runner.rb`:

1. Change `def employer` to `def application` (around line 27)
2. Change `@employer` to `@application` throughout
3. Change `Employer.new` to `Application.new`
4. Change `employers_path = File.join(Dir.pwd, "employers")` to `applications_path = File.join(Dir.pwd, "applications")`
5. Update any directory listing logic

**Step 4.2: Update workflow.rb**

In `lib/jojo/commands/interactive/workflow.rb`:

1. Change all parameter names from `employer` to `application`
2. Change all method calls from `employer.` to `application.`

**Step 4.3: Update dashboard.rb**

In `lib/jojo/commands/interactive/dashboard.rb`:

1. Change `def self.render(employer)` to `def self.render(application)`
2. Change `employer.slug` to `application.slug`
3. Change `employer.company_name` to `application.company_name`

**Step 4.4: Run interactive tests**

Run: `bundle exec ruby -Ilib:test test/unit/commands/interactive/runner_test.rb test/unit/commands/interactive/workflow_test.rb test/unit/commands/interactive/dashboard_test.rb`
Expected: Tests may fail, proceed to update them in Task 6

**Step 4.5: Commit**

```bash
git add lib/jojo/commands/interactive/
git commit -m "$(cat <<'EOF'
refactor: rename employer to application in interactive commands

Update runner, workflow, and dashboard to use application terminology
instead of employer throughout.
EOF
)"
```

---

## Task 5: Update CLI and Environment Variable

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 5.1: Update CLI descriptions and env var support**

In `lib/jojo/cli.rb`:

1. Change line 22 description from "Employer slug" to "Application slug":
```ruby
class_option :slug, type: :string, aliases: "-s", desc: "Application slug (unique identifier)"
```

2. Change line 44 long_desc from "employer workspace" to "application workspace"

3. Update command_options method (around line 218) to support both env vars with new one taking precedence:
```ruby
def command_options
  {
    slug: options[:slug] || ENV["JOJO_APPLICATION_SLUG"] || ENV["JOJO_EMPLOYER_SLUG"],
    verbose: options[:verbose],
    overwrite: options[:overwrite],
    quiet: options[:quiet]
  }
end
```

4. Update resolve_slug method (around line 225) similarly:
```ruby
def resolve_slug
  slug = options[:slug] || ENV["JOJO_APPLICATION_SLUG"] || ENV["JOJO_EMPLOYER_SLUG"]

  unless slug
    say "Error: No application specified.", :red
    say "Provide --slug or set JOJO_APPLICATION_SLUG environment variable.", :yellow
    say "\nExample:", :cyan
    say "  jojo #{invoked_command} --slug acme-corp-senior", :white
    say "  export JOJO_APPLICATION_SLUG=acme-corp-senior && jojo #{invoked_command}", :white
    exit 1
  end

  slug
end
```

5. Update all long_desc strings that mention "employer" to say "application"

**Step 5.2: Run CLI tests**

Run: `bundle exec ruby -Ilib:test test/unit/cli_*.rb`
Expected: May need test updates

**Step 5.3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "$(cat <<'EOF'
refactor: update CLI to use application terminology

- Change --slug description to "Application slug"
- Support JOJO_APPLICATION_SLUG env var (with JOJO_EMPLOYER_SLUG fallback)
- Update all command descriptions to reference "application" not "employer"
EOF
)"
```

---

## Task 6: Update All Unit Tests

**Files:**
- Modify: All files in `test/unit/`
- Rename: `test/unit/employer_test.rb` → keep for backward compat testing

**Step 6.1: Update test files with find-and-replace**

For each test file, update:
- `@employer` → `@application`
- `employer:` → `application:` (in hash parameters)
- `employer.` → `application.` (method calls)
- `employers/` → `applications/` (directory paths)
- `FileUtils.mkdir_p("employers/` → `FileUtils.mkdir_p("applications/`
- `Jojo::Employer.new` → `Jojo::Application.new`

**Step 6.2: Run all unit tests**

Run: `./bin/jojo test --unit`
Expected: All tests pass

**Step 6.3: Commit**

```bash
git add test/unit/
git commit -m "$(cat <<'EOF'
test: update all unit tests for employer to application rename

Update test files to use Application class and applications/ directory
paths instead of Employer and employers/.
EOF
)"
```

---

## Task 7: Update Integration Tests

**Files:**
- Modify: All files in `test/integration/`

**Step 7.1: Update integration test files**

Apply same find-and-replace patterns as Task 6.

**Step 7.2: Run integration tests**

Run: `./bin/jojo test --integration`
Expected: All tests pass

**Step 7.3: Commit**

```bash
git add test/integration/
git commit -m "$(cat <<'EOF'
test: update integration tests for employer to application rename
EOF
)"
```

---

## Task 8: Add Backward Compatibility for Directory Migration

**Files:**
- Modify: `lib/jojo/application.rb`

**Step 8.1: Add legacy directory detection**

Update `lib/jojo/application.rb` to check for legacy `employers/` directory:

```ruby
def initialize(slug)
  @slug = slug
  @name = slug
  @base_path = resolve_base_path
end

private

def resolve_base_path
  new_path = File.join("applications", @slug)
  legacy_path = File.join("employers", @slug)

  # Prefer new path if it exists, fall back to legacy if only legacy exists
  if File.directory?(new_path)
    new_path
  elsif File.directory?(legacy_path)
    legacy_path
  else
    # Default to new path for new applications
    new_path
  end
end
```

**Step 8.2: Write test for backward compatibility**

Add to `test/unit/application_test.rb`:

```ruby
describe "backward compatibility" do
  it "uses applications/ path when it exists" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p("applications/my-app")
        app = Jojo::Application.new("my-app")
        _(app.base_path).must_equal "applications/my-app"
      end
    end
  end

  it "falls back to employers/ path when only legacy exists" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p("employers/legacy-app")
        app = Jojo::Application.new("legacy-app")
        _(app.base_path).must_equal "employers/legacy-app"
      end
    end
  end

  it "uses applications/ for new apps when neither exists" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        app = Jojo::Application.new("new-app")
        _(app.base_path).must_equal "applications/new-app"
      end
    end
  end
end
```

**Step 8.3: Run tests**

Run: `bundle exec ruby -Ilib:test test/unit/application_test.rb`
Expected: All tests pass

**Step 8.4: Commit**

```bash
git add lib/jojo/application.rb test/unit/application_test.rb
git commit -m "$(cat <<'EOF'
feat: add backward compatibility for employers/ directory

Application class now checks for both applications/ (new) and
employers/ (legacy) directories, preferring new but supporting legacy
for users who haven't migrated yet.
EOF
)"
```

---

## Task 9: Remove Old Employer Class

**Files:**
- Delete: `lib/jojo/employer.rb`
- Modify: `lib/jojo.rb` (remove employer require)

**Step 9.1: Remove employer.rb**

```bash
git rm lib/jojo/employer.rb
```

**Step 9.2: Remove require from jojo.rb**

Remove the line `require_relative "jojo/employer"` from `lib/jojo.rb`.

**Step 9.3: Run all tests**

Run: `./bin/jojo test --all --no-service`
Expected: All tests pass

**Step 9.4: Commit**

```bash
git add lib/jojo.rb
git commit -m "$(cat <<'EOF'
refactor: remove deprecated Employer class

Delete employer.rb and its require now that all code uses Application.
EOF
)"
```

---

## Task 10: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/commands.md`
- Modify: `CHANGELOG.md`

**Step 10.1: Update README.md**

Replace all references to:
- "employer" → "application"
- "employers/" → "applications/"
- "JOJO_EMPLOYER_SLUG" → "JOJO_APPLICATION_SLUG"

**Step 10.2: Update docs/commands.md**

Apply same replacements.

**Step 10.3: Update CHANGELOG.md**

Add entry for this release:

```markdown
## [Unreleased]

### Changed
- **BREAKING**: Renamed `Employer` class to `Application` to better reflect purpose
- **BREAKING**: Default workspace directory changed from `employers/` to `applications/`
- **BREAKING**: Environment variable renamed from `JOJO_EMPLOYER_SLUG` to `JOJO_APPLICATION_SLUG`

### Deprecated
- `employers/` directory still supported but will be removed in future release
- `JOJO_EMPLOYER_SLUG` environment variable still works but is deprecated
```

**Step 10.4: Commit**

```bash
git add README.md docs/commands.md CHANGELOG.md
git commit -m "$(cat <<'EOF'
docs: update documentation for employer to application rename

Update all documentation to reflect the renamed Application class,
applications/ directory, and JOJO_APPLICATION_SLUG environment variable.
EOF
)"
```

---

## Task 11: Final Verification

**Step 11.1: Run complete test suite**

Run: `./bin/jojo test --all --no-service`
Expected: All tests pass

**Step 11.2: Run Standard Ruby**

Run: `./bin/jojo test --standard`
Expected: No style violations

**Step 11.3: Manual verification**

1. Create a new application:
   ```bash
   ./bin/jojo new -s test-refactor
   ```
   Verify it creates `applications/test-refactor/`

2. Test with legacy directory (if `employers/` exists):
   ```bash
   ./bin/jojo resume -s cybercoders
   ```
   Should work with existing `employers/cybercoders/`

**Step 11.4: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix: address issues found in final verification"
```

---

## Summary

This refactor touches approximately:
- **1 class rename**: Employer → Application
- **1 file rename**: employer.rb → application.rb
- **~15 lib files**: Generator and command classes
- **~25 test files**: Unit and integration tests
- **~5 doc files**: README, commands.md, CHANGELOG
- **2 env vars**: JOJO_EMPLOYER_SLUG → JOJO_APPLICATION_SLUG (with backward compat)
- **1 directory**: employers/ → applications/ (with backward compat)

Total: ~2,300 lines of code changes across ~50 files.
