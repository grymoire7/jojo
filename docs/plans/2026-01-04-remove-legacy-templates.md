# Remove Legacy Template Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove support for legacy template files (`generic_resume.md` and `projects.yml`) and consolidate on `resume_data.yml` as the single source of truth.

**Architecture:** This refactoring eliminates the "hybrid state" where the codebase supports both old (generic_resume.md + projects.yml) and new (resume_data.yml) formats. Since the product hasn't shipped to users, we can cleanly remove legacy support without migration concerns. The changes touch generators, loaders, CLI validation, setup service, and tests.

**Tech Stack:** Ruby, Minitest

---

## Phase 1: Remove ProjectLoader and projects.yml Support

### Task 1: Delete ProjectLoader class and its tests

**Files:**
- Delete: `lib/jojo/project_loader.rb`
- Delete: `test/unit/project_loader_test.rb`
- Delete: `test/fixtures/valid_projects.yml`
- Delete: `test/fixtures/invalid_projects.yml`
- Delete: `test/fixtures/invalid_skills_projects.yml`
- Delete: `test/fixtures/minimal_projects.yml`

**Step 1: Verify no other code depends on ProjectLoader**

Run: `grep -r "ProjectLoader" lib/ test/ --exclude-dir=tmp`

Expected: Should only show references in cover_letter_generator.rb, website_generator.rb, and their tests (which we'll update in subsequent tasks)

**Step 2: Delete ProjectLoader class**

```bash
git rm lib/jojo/project_loader.rb
```

**Step 3: Delete ProjectLoader tests**

```bash
git rm test/unit/project_loader_test.rb
```

**Step 4: Delete project test fixtures**

```bash
git rm test/fixtures/valid_projects.yml
git rm test/fixtures/invalid_projects.yml
git rm test/fixtures/invalid_skills_projects.yml
git rm test/fixtures/minimal_projects.yml
```

**Step 5: Commit**

```bash
git commit -m "refactor: remove ProjectLoader class and tests

Projects are now loaded from resume_data.yml instead of separate
projects.yml file. This eliminates the legacy projects.yml format."
```

---

### Task 2: Remove projects.yml from templates

**Files:**
- Delete: `templates/projects.yml`

**Step 1: Delete template file**

```bash
git rm templates/projects.yml
```

**Step 2: Commit**

```bash
git commit -m "refactor: remove projects.yml template

Projects are now defined in resume_data.yml template"
```

---

### Task 3: Update SetupService to remove projects.yml

**Files:**
- Modify: `lib/jojo/setup_service.rb:242-247`

**Step 1: Remove projects.yml from input_files hash**

Edit `lib/jojo/setup_service.rb` line 242-247:

Before:
```ruby
input_files = {
  "resume_data.yml" => "(customize with your experience)",
  "generic_resume.md" => "(legacy format - optional)",
  "recommendations.md" => "(optional - customize or delete)",
  "projects.yml" => "(optional - customize or delete)"
}
```

After:
```ruby
input_files = {
  "resume_data.yml" => "(customize with your experience)",
  "recommendations.md" => "(optional - customize or delete)"
}
```

**Step 2: Run tests**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Tests should pass

**Step 3: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "refactor: remove projects.yml from setup service

Setup no longer creates projects.yml template file"
```

---

### Task 4: Update CoverLetterGenerator to remove projects support

**Files:**
- Modify: `lib/jojo/generators/cover_letter_generator.rb:139-151`
- Modify: `lib/jojo/generators/cover_letter_generator.rb:25-26`
- Modify: `lib/jojo/generators/cover_letter_generator.rb:3-4`

**Step 1: Remove ProjectLoader and ProjectSelector requires**

Edit `lib/jojo/generators/cover_letter_generator.rb` lines 3-4:

Before:
```ruby
require_relative "../prompts/cover_letter_prompt"
require_relative "../project_loader"
require_relative "../project_selector"
```

After:
```ruby
require_relative "../prompts/cover_letter_prompt"
```

**Step 2: Remove load_projects method call from generate**

Edit `lib/jojo/generators/cover_letter_generator.rb` lines 25-26:

Before:
```ruby
log "Loading relevant projects..."
projects = load_projects()
```

After:
```ruby
# Projects removed - now part of resume_data.yml
projects = []
```

**Step 3: Delete load_projects method**

Delete lines 139-151 (the entire `load_projects` method)

**Step 4: Run tests**

Run: `ruby -Ilib:test test/unit/generators/cover_letter_generator_test.rb`

Expected: Tests should pass (projects will be empty array)

**Step 5: Commit**

```bash
git add lib/jojo/generators/cover_letter_generator.rb
git commit -m "refactor: remove projects.yml support from CoverLetterGenerator

Cover letter no longer loads projects from separate file.
Projects are now part of resume_data.yml."
```

---

### Task 5: Update WebsiteGenerator to load projects from resume_data.yml

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb:6-7`
- Modify: `lib/jojo/generators/website_generator.rb:33-35`

**Step 1: Add ResumeDataLoader require, remove ProjectLoader**

Edit `lib/jojo/generators/website_generator.rb` lines 6-7:

Before:
```ruby
require_relative "../project_loader"
require_relative "../project_selector"
```

After:
```ruby
require_relative "../resume_data_loader"
```

**Step 2: Read the current load_projects method**

Run: `sed -n '/def load_projects/,/^  end$/p' lib/jojo/generators/website_generator.rb`

Expected: See the current implementation

**Step 3: Write failing test for resume_data-based projects**

Create test file: `test/unit/website_generator_resume_data_projects_test.rb`

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/generators/website_generator"

describe "WebsiteGenerator projects from resume_data" do
  it "loads projects from resume_data.yml" do
    employer = create_employer("test-company")
    ai_client = MockAIClient.new
    config = create_config

    generator = Jojo::Generators::WebsiteGenerator.new(
      employer,
      ai_client,
      config: config,
      inputs_path: "test/fixtures"
    )

    projects = generator.send(:load_projects)

    _(projects).must_be_kind_of Array
    _(projects.size).must_equal 2
    _(projects.first[:name]).must_equal "Open Source CLI Tool"
  end
end
```

**Step 4: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/website_generator_resume_data_projects_test.rb`

Expected: FAIL - load_projects doesn't load from resume_data yet

**Step 5: Update load_projects to use ResumeDataLoader**

Find the `load_projects` method in `lib/jojo/generators/website_generator.rb` and replace with:

```ruby
def load_projects
  resume_data_path = File.join(inputs_path, "resume_data.yml")
  return [] unless File.exist?(resume_data_path)

  loader = ResumeDataLoader.new(resume_data_path)
  resume_data = loader.load

  projects = resume_data["projects"] || []

  # Convert to symbol keys for consistency
  projects.map { |p| p.transform_keys(&:to_sym) }
rescue ResumeDataLoader::LoadError, ResumeDataLoader::ValidationError => e
  log "Warning: Could not load projects from resume_data.yml: #{e.message}"
  []
end
```

**Step 6: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/website_generator_resume_data_projects_test.rb`

Expected: PASS

**Step 7: Run all website generator tests**

Run: `ruby -Ilib:test test/unit/website_generator*.rb`

Expected: All tests pass

**Step 8: Commit**

```bash
git add lib/jojo/generators/website_generator.rb test/unit/website_generator_resume_data_projects_test.rb
git commit -m "refactor: load projects from resume_data.yml in WebsiteGenerator

WebsiteGenerator now reads projects from resume_data.yml instead of
separate projects.yml file"
```

---

### Task 6: Delete obsolete project-related tests

**Files:**
- Delete: `test/unit/cover_letter_generator_projects_test.rb`
- Delete: `test/unit/resume_generator_projects_test.rb`
- Delete: `test/unit/website_generator_projects_test.rb`
- Delete: `test/integration/projects_workflow_test.rb`
- Delete: `test/integration/recommendations_workflow_test.rb` (verify first)

**Step 1: Verify these tests reference projects.yml**

Run: `grep -l "projects.yml" test/unit/*projects_test.rb test/integration/*workflow_test.rb`

Expected: Lists the test files that reference projects.yml

**Step 2: Delete obsolete test files**

```bash
git rm test/unit/cover_letter_generator_projects_test.rb
git rm test/unit/resume_generator_projects_test.rb
git rm test/unit/website_generator_projects_test.rb
git rm test/integration/projects_workflow_test.rb
```

**Step 3: Check recommendations_workflow_test**

Run: `grep -n "projects.yml" test/integration/recommendations_workflow_test.rb`

If it references projects.yml, delete it:
```bash
git rm test/integration/recommendations_workflow_test.rb
```

**Step 4: Run full test suite**

Run: `./bin/jojo test`

Expected: All tests pass

**Step 5: Commit**

```bash
git commit -m "test: remove obsolete projects.yml test files

These tests validated projects.yml loading which is no longer supported"
```

---

### Task 7: Update CLI to remove projects.yml validation warnings

**Files:**
- Modify: `lib/jojo/cli.rb:174`

**Step 1: Find the validation warning loop**

Run: `grep -n "projects.yml" lib/jojo/cli.rb`

Expected: Shows line 174 with validation warning

**Step 2: Update validation loop to remove projects.yml**

Edit `lib/jojo/cli.rb` line 174:

Before:
```ruby
["inputs/generic_resume.md", "inputs/recommendations.md", "inputs/projects.yml"].each do |file|
```

After:
```ruby
["inputs/recommendations.md"].each do |file|
```

**Step 3: Run tests**

Run: `ruby -Ilib:test test/unit/cli_test.rb`

Expected: Tests pass

**Step 4: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "refactor: remove projects.yml from CLI validation warnings"
```

---

## Phase 2: Remove generic_resume.md Support

### Task 8: Update ResearchGenerator to use resume_data.yml

**Files:**
- Modify: `lib/jojo/generators/research_generator.rb:1-3`
- Modify: `lib/jojo/generators/research_generator.rb:52-83`

**Step 1: Add ResumeDataLoader require**

Edit `lib/jojo/generators/research_generator.rb` lines 1-3:

Before:
```ruby
require "yaml"
require "deepsearch"
require_relative "../prompts/research_prompt"
```

After:
```ruby
require "yaml"
require "deepsearch"
require_relative "../prompts/research_prompt"
require_relative "../resume_data_loader"
```

**Step 2: Write failing test**

Create: `test/unit/research_generator_resume_data_test.rb`

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/generators/research_generator"

describe "ResearchGenerator with resume_data" do
  it "loads resume from resume_data.yml" do
    employer = create_employer("test-company")
    ai_client = MockAIClient.new
    config = create_config

    generator = Jojo::Generators::ResearchGenerator.new(
      employer,
      ai_client,
      config: config,
      inputs_path: "test/fixtures"
    )

    inputs = generator.send(:gather_inputs)

    _(inputs[:resume]).wont_be_nil
    _(inputs[:resume]).must_include "Jane Doe"
  end
end
```

**Step 3: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/research_generator_resume_data_test.rb`

Expected: FAIL - read_generic_resume still uses generic_resume.md

**Step 4: Update read_generic_resume method**

Replace the `read_generic_resume` method (lines 74-83) with:

```ruby
def read_generic_resume
  resume_data_path = File.join(inputs_path, "resume_data.yml")

  unless File.exist?(resume_data_path)
    log "Warning: Resume data not found at #{resume_data_path}, research will be less personalized"
    return nil
  end

  loader = ResumeDataLoader.new(resume_data_path)
  resume_data = loader.load

  # Format resume data as text for the prompt
  format_resume_data(resume_data)
rescue ResumeDataLoader::LoadError, ResumeDataLoader::ValidationError => e
  log "Warning: Could not load resume data: #{e.message}"
  nil
end

def format_resume_data(data)
  # Convert structured resume_data to readable text format
  output = []
  output << "# #{data['name']}"
  output << "#{data['email']} | #{data['location']}"
  output << ""
  output << "## Summary"
  output << data['summary']
  output << ""
  output << "## Skills"
  output << data['skills'].join(", ")
  output << ""
  output << "## Experience"
  data['experience'].each do |exp|
    output << "### #{exp['title']} at #{exp['company']}"
    output << exp['description']
    output << "Technologies: #{exp['technologies'].join(', ')}" if exp['technologies']
    output << ""
  end

  output.join("\n")
end
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/research_generator_resume_data_test.rb`

Expected: PASS

**Step 6: Run all research generator tests**

Run: `ruby -Ilib:test test/unit/research_generator_test.rb`

Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/generators/research_generator.rb test/unit/research_generator_resume_data_test.rb
git commit -m "refactor: load resume from resume_data.yml in ResearchGenerator

ResearchGenerator now reads structured resume data instead of
generic_resume.md markdown file"
```

---

### Task 9: Update CoverLetterGenerator to use resume_data.yml

**Files:**
- Modify: `lib/jojo/generators/cover_letter_generator.rb:1-4`
- Modify: `lib/jojo/generators/cover_letter_generator.rb:59-64`
- Modify: `lib/jojo/generators/cover_letter_generator.rb:103-114`

**Step 1: Add ResumeDataLoader require**

Edit `lib/jojo/generators/cover_letter_generator.rb` lines 1-2:

Before:
```ruby
require "yaml"
require_relative "../prompts/cover_letter_prompt"
```

After:
```ruby
require "yaml"
require_relative "../prompts/cover_letter_prompt"
require_relative "../resume_data_loader"
```

**Step 2: Write failing test**

Create: `test/unit/cover_letter_generator_resume_data_test.rb`

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/generators/cover_letter_generator"

describe "CoverLetterGenerator with resume_data" do
  it "loads generic resume from resume_data.yml" do
    employer = create_employer("test-company")
    create_job_description(employer)
    create_tailored_resume(employer)

    ai_client = MockAIClient.new
    config = create_config

    generator = Jojo::Generators::CoverLetterGenerator.new(
      employer,
      ai_client,
      config: config,
      inputs_path: "test/fixtures"
    )

    inputs = generator.send(:gather_inputs)

    _(inputs[:generic_resume]).wont_be_nil
    _(inputs[:generic_resume]).must_include "Jane Doe"
  end
end
```

**Step 3: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/cover_letter_generator_resume_data_test.rb`

Expected: FAIL - gather_inputs still reads generic_resume.md

**Step 4: Update gather_inputs to use resume_data.yml**

Replace lines 59-64 in `lib/jojo/generators/cover_letter_generator.rb`:

Before:
```ruby
# Read generic resume (REQUIRED)
generic_resume_path = File.join(inputs_path, "generic_resume.md")
unless File.exist?(generic_resume_path)
  raise "Generic resume not found at #{generic_resume_path}"
end
generic_resume = File.read(generic_resume_path)
```

After:
```ruby
# Read resume data (REQUIRED)
resume_data_path = File.join(inputs_path, "resume_data.yml")
unless File.exist?(resume_data_path)
  raise "Resume data not found at #{resume_data_path}"
end
loader = ResumeDataLoader.new(resume_data_path)
resume_data = loader.load
generic_resume = format_resume_data(resume_data)
```

**Step 5: Add format_resume_data helper method**

Add this method at the end of the private section:

```ruby
def format_resume_data(data)
  # Convert structured resume_data to readable text format for prompts
  output = []
  output << "# #{data['name']}"
  output << "#{data['email']} | #{data['location']}"
  output << ""
  output << "## Summary"
  output << data['summary']
  output << ""
  output << "## Skills"
  output << data['skills'].join(", ")
  output << ""
  output << "## Experience"
  data['experience'].each do |exp|
    output << "### #{exp['title']} at #{exp['company']}"
    output << exp['description']
    output << "Technologies: #{exp['technologies'].join(', ')}" if exp['technologies']
    output << ""
  end

  output.join("\n")
end
```

**Step 6: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/cover_letter_generator_resume_data_test.rb`

Expected: PASS

**Step 7: Run all cover letter generator tests**

Run: `ruby -Ilib:test test/unit/generators/cover_letter_generator_test.rb`

Expected: All tests pass

**Step 8: Commit**

```bash
git add lib/jojo/generators/cover_letter_generator.rb test/unit/cover_letter_generator_resume_data_test.rb
git commit -m "refactor: load resume from resume_data.yml in CoverLetterGenerator

CoverLetterGenerator now uses structured resume_data.yml instead of
generic_resume.md markdown file"
```

---

### Task 10: Remove generic_resume.md from CLI validations

**Files:**
- Modify: `lib/jojo/cli.rb:61-76`
- Modify: `lib/jojo/cli.rb:162-168`
- Modify: `lib/jojo/cli.rb:174-180`
- Modify: `lib/jojo/cli.rb:212-223`
- Modify: `lib/jojo/cli.rb:415-419`
- Modify: `lib/jojo/cli.rb:471-475`

**Step 1: Replace generic_resume validation with resume_data validation in annotate command**

Edit `lib/jojo/cli.rb` lines 61-76:

Before:
```ruby
# Validate required inputs exist before creating employer
begin
  Jojo::TemplateValidator.validate_required_file!(
    "inputs/generic_resume.md",
    "generic resume"
  )
rescue Jojo::TemplateValidator::MissingInputError => e
  say e.message, :red
  exit 1
end

# Warn if generic resume hasn't been customized
result = Jojo::TemplateValidator.warn_if_unchanged(
  "inputs/generic_resume.md",
  "generic resume",
  cli_instance: self
)
```

After:
```ruby
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
```

**Step 2: Update validation in new command**

Edit `lib/jojo/cli.rb` lines 162-168:

Before:
```ruby
# Validate required inputs
begin
  Jojo::TemplateValidator.validate_required_file!(
    "inputs/generic_resume.md",
    "generic resume"
  )
rescue Jojo::TemplateValidator::MissingInputError => e
  say e.message, :red
  exit 1
end
```

After:
```ruby
# Validate required inputs
begin
  Jojo::TemplateValidator.validate_required_file!(
    "inputs/resume_data.yml",
    "resume data"
  )
rescue Jojo::TemplateValidator::MissingInputError => e
  say e.message, :red
  exit 1
end
```

**Step 3: Update template warning loop**

Edit `lib/jojo/cli.rb` line 174:

Before:
```ruby
["inputs/recommendations.md"].each do |file|
```

After:
```ruby
["inputs/resume_data.yml", "inputs/recommendations.md"].each do |file|
```

**Step 4: Update generate command resume check**

Edit `lib/jojo/cli.rb` lines 212-223:

Before:
```ruby
# Generate resume
begin
  if File.exist?("inputs/generic_resume.md")
    generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
    generator.generate

    employer.update_status(
      step: "resume",
      status: "complete")
  else
    say "⚠ Warning: Generic resume not found, skipping resume generation", :yellow
    say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
  end
```

After:
```ruby
# Generate resume
begin
  if File.exist?("inputs/resume_data.yml")
    generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose], overwrite_flag: options[:overwrite], cli_instance: self)
    generator.generate

    employer.update_status(
      step: "resume",
      status: "complete")
  else
    say "⚠ Warning: Resume data not found, skipping resume generation", :yellow
    say "  Ensure inputs/resume_data.yml exists and is customized.", :yellow
  end
```

**Step 5: Update research command validation**

Edit `lib/jojo/cli.rb` lines 415-419:

Before:
```ruby
# Check that generic resume exists
unless File.exist?("inputs/generic_resume.md")
  say "✗ Generic resume not found at inputs/generic_resume.md", :red
  say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
  exit 1
end
```

After:
```ruby
# Check that resume data exists
unless File.exist?("inputs/resume_data.yml")
  say "✗ Resume data not found at inputs/resume_data.yml", :red
  say "  Ensure inputs/resume_data.yml exists and is customized.", :yellow
  exit 1
end
```

**Step 6: Update cover-letter command validation**

Edit `lib/jojo/cli.rb` lines 471-475:

Before:
```ruby
# Check generic resume exists (REQUIRED)
unless File.exist?("inputs/generic_resume.md")
  say "✗ Generic resume not found at inputs/generic_resume.md", :red
  say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
  exit 1
end
```

After:
```ruby
# Check resume data exists (REQUIRED)
unless File.exist?("inputs/resume_data.yml")
  say "✗ Resume data not found at inputs/resume_data.yml", :red
  say "  Ensure inputs/resume_data.yml exists and is customized.", :yellow
  exit 1
end
```

**Step 7: Run CLI tests**

Run: `ruby -Ilib:test test/unit/cli_test.rb`

Expected: Tests pass

**Step 8: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "refactor: replace generic_resume.md validations with resume_data.yml

All CLI commands now validate resume_data.yml instead of generic_resume.md"
```

---

### Task 11: Update SetupService to remove generic_resume.md

**Files:**
- Modify: `lib/jojo/setup_service.rb:242-247`

**Step 1: Remove generic_resume.md from input_files**

Edit `lib/jojo/setup_service.rb` lines 242-247:

Before:
```ruby
input_files = {
  "resume_data.yml" => "(customize with your experience)",
  "recommendations.md" => "(optional - customize or delete)"
}
```

Note: projects.yml was already removed in Task 3

After:
```ruby
input_files = {
  "resume_data.yml" => "(customize with your experience)",
  "recommendations.md" => "(optional - customize or delete)"
}
```

Wait, generic_resume.md was already removed in our earlier edit. Let me verify:

**Step 2: Verify current state**

Run: `grep -A 4 "input_files = {" lib/jojo/setup_service.rb`

Expected: Should show current input_files hash

If generic_resume.md is still there, remove it to match the "After" state above.

**Step 3: Run setup tests**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Tests pass

**Step 4: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "refactor: remove generic_resume.md from setup templates

Setup service no longer creates generic_resume.md template"
```

---

### Task 12: Delete template files

**Files:**
- Delete: `templates/generic_resume.md`
- Delete: `test/fixtures/generic_resume.md`

**Step 1: Delete template**

```bash
git rm templates/generic_resume.md
```

**Step 2: Delete test fixture**

```bash
git rm test/fixtures/generic_resume.md
```

**Step 3: Verify no references remain**

Run: `grep -r "generic_resume.md" lib/ test/ --exclude-dir=tmp`

Expected: No matches (or only in plan documents/README which we'll update next)

**Step 4: Commit**

```bash
git commit -m "refactor: delete generic_resume.md template and fixtures

Template no longer needed - resume_data.yml is the single source"
```

---

### Task 13: Update setup service file descriptions

**Files:**
- Modify: `lib/jojo/setup_service.rb:298-310`

**Step 1: Read current file descriptions**

Run: `sed -n '/file_descriptions = {/,/}/p' lib/jojo/setup_service.rb`

Expected: Shows current descriptions hash

**Step 2: Update descriptions to remove generic_resume.md references**

Find the `file_descriptions` hash in `show_summary` method and update:

Before:
```ruby
file_descriptions = {
  ".env" => "API configuration",
  "config.yml" => "Jojo configuration (models, voice/tone, base URL, permissions)",
  "inputs/resume_data.yml" => "Your complete work history and skills (structured YAML)",
  "inputs/generic_resume.md" => "Your generic resume (legacy markdown format - optional)",
  "inputs/recommendations.md" => "Optional: Your professional recommendations",
  "inputs/projects.yml" => "Optional: Portfolio projects to showcase",
  "inputs/templates/default_resume.md.erb" => "Resume template (ERB format)"
}
```

After:
```ruby
file_descriptions = {
  ".env" => "API configuration",
  "config.yml" => "Jojo configuration (models, voice/tone, base URL, permissions)",
  "inputs/resume_data.yml" => "Your complete work history and skills (structured YAML)",
  "inputs/recommendations.md" => "Optional: Your professional recommendations",
  "inputs/templates/default_resume.md.erb" => "Resume template (ERB format)"
}
```

**Step 3: Run setup tests**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Tests pass

**Step 4: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "docs: remove legacy template references from setup descriptions"
```

---

### Task 14: Update integration tests

**Files:**
- Modify: `test/integration/setup_integration_test.rb`

**Step 1: Read the test file**

Run: `grep -n "generic_resume\|projects.yml" test/integration/setup_integration_test.rb`

Expected: Shows lines referencing legacy templates

**Step 2: Update test expectations**

Remove assertions that check for:
- `inputs/generic_resume.md` creation
- `inputs/projects.yml` creation

Update to only expect:
- `inputs/resume_data.yml` creation
- `inputs/recommendations.md` creation

**Step 3: Run integration test**

Run: `ruby -Ilib:test test/integration/setup_integration_test.rb`

Expected: PASS

**Step 4: Commit**

```bash
git add test/integration/setup_integration_test.rb
git commit -m "test: update setup integration test for resume_data-only flow"
```

---

## Phase 3: Documentation and Cleanup

### Task 15: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Read current README**

Run: `grep -n "generic_resume\|projects.yml" README.md`

Expected: Shows sections mentioning legacy templates

**Step 2: Update getting started section**

Find the setup instructions and update to only mention `resume_data.yml`:

Before (example):
```markdown
After setup, customize your profile:
- `inputs/generic_resume.md` - Your complete professional background
- `inputs/projects.yml` - Portfolio projects to showcase
- `inputs/resume_data.yml` - Structured resume data (new format)
```

After:
```markdown
After setup, customize your profile:
- `inputs/resume_data.yml` - Your complete professional background, skills, and projects
- `inputs/recommendations.md` - Optional professional recommendations
```

**Step 3: Update any examples referencing legacy formats**

Search for and update all examples to use `resume_data.yml`

**Step 4: Verify README renders correctly**

Read through the updated README to ensure it flows well

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: update README to reference resume_data.yml only

Remove references to legacy generic_resume.md and projects.yml formats"
```

---

### Task 16: Add format_resume_data as shared utility

**Files:**
- Create: `lib/jojo/resume_data_formatter.rb`
- Modify: `lib/jojo/generators/research_generator.rb`
- Modify: `lib/jojo/generators/cover_letter_generator.rb`

**Step 1: Create shared formatter module**

Create: `lib/jojo/resume_data_formatter.rb`

```ruby
module Jojo
  module ResumeDataFormatter
    # Converts structured resume_data hash to readable text format for AI prompts
    def self.format(data)
      output = []
      output << "# #{data['name']}"
      output << "#{data['email']} | #{data['location']}"
      output << ""

      output << "## Summary"
      output << data['summary']
      output << ""

      output << "## Skills"
      output << data['skills'].join(", ")
      output << ""

      if data['experience']
        output << "## Experience"
        data['experience'].each do |exp|
          output << "### #{exp['title']} at #{exp['company']}"
          output << exp['description']
          if exp['technologies']
            output << "Technologies: #{exp['technologies'].join(', ')}"
          end
          output << ""
        end
      end

      if data['projects']
        output << "## Projects"
        data['projects'].each do |project|
          output << "### #{project['name']}"
          output << project['description']
          if project['skills']
            output << "Skills: #{project['skills'].join(', ')}"
          end
          output << ""
        end
      end

      output.join("\n")
    end
  end
end
```

**Step 2: Update ResearchGenerator to use shared formatter**

Edit `lib/jojo/generators/research_generator.rb`:

Add require:
```ruby
require_relative "../resume_data_formatter"
```

Replace `format_resume_data` method with:
```ruby
def format_resume_data(data)
  ResumeDataFormatter.format(data)
end
```

**Step 3: Update CoverLetterGenerator to use shared formatter**

Edit `lib/jojo/generators/cover_letter_generator.rb`:

Add require:
```ruby
require_relative "../resume_data_formatter"
```

Replace `format_resume_data` method with:
```ruby
def format_resume_data(data)
  ResumeDataFormatter.format(data)
end
```

**Step 4: Write test for formatter**

Create: `test/unit/resume_data_formatter_test.rb`

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_formatter"

describe Jojo::ResumeDataFormatter do
  it "formats resume data as readable text" do
    data = {
      'name' => 'Jane Doe',
      'email' => 'jane@example.com',
      'location' => 'San Francisco, CA',
      'summary' => 'Experienced engineer',
      'skills' => ['Ruby', 'Python'],
      'experience' => [
        {
          'title' => 'Senior Engineer',
          'company' => 'TechCorp',
          'description' => 'Built cool stuff',
          'technologies' => ['Ruby', 'Rails']
        }
      ]
    }

    output = Jojo::ResumeDataFormatter.format(data)

    _(output).must_include 'Jane Doe'
    _(output).must_include 'jane@example.com'
    _(output).must_include 'Experienced engineer'
    _(output).must_include 'Ruby, Python'
    _(output).must_include 'Senior Engineer at TechCorp'
  end
end
```

**Step 5: Run test**

Run: `ruby -Ilib:test test/unit/resume_data_formatter_test.rb`

Expected: PASS

**Step 6: Run full test suite**

Run: `./bin/jojo test`

Expected: All tests pass

**Step 7: Commit**

```bash
git add lib/jojo/resume_data_formatter.rb lib/jojo/generators/research_generator.rb lib/jojo/generators/cover_letter_generator.rb test/unit/resume_data_formatter_test.rb
git commit -m "refactor: extract resume data formatting to shared module

DRY up formatting logic used by multiple generators"
```

---

### Task 17: Run full test suite and verify

**Step 1: Run all tests**

Run: `./bin/jojo test`

Expected: All tests pass

**Step 2: Test setup flow manually**

```bash
cd /tmp
mkdir jojo-refactor-test
cd jojo-refactor-test
# Copy jojo to this directory or use installed gem
jojo setup
```

Expected:
- Creates `.env`
- Creates `config.yml`
- Creates `inputs/resume_data.yml`
- Creates `inputs/recommendations.md`
- Does NOT create `inputs/generic_resume.md`
- Does NOT create `inputs/projects.yml`

**Step 3: Test annotate command**

```bash
jojo new acme-corp
echo "Test JD" > employers/acme-corp/job_description.md
jojo annotate acme-corp
```

Expected: Works without errors

**Step 4: Document any issues found**

If any issues are found, create additional tasks to fix them

**Step 5: Cleanup test directory**

```bash
cd /tmp
rm -rf jojo-refactor-test
```

---

### Task 18: Update plan documents

**Files:**
- Modify: `docs/plans/design.md`
- Modify: `docs/plans/implementation_plan.md`

**Step 1: Update design.md**

Remove references to legacy templates:
- Search for `generic_resume.md` and update to `resume_data.yml`
- Search for `projects.yml` and update to reference projects in `resume_data.yml`

**Step 2: Update implementation_plan.md**

Mark any legacy template tasks as obsolete/completed

**Step 3: Commit**

```bash
git add docs/plans/design.md docs/plans/implementation_plan.md
git commit -m "docs: update design docs to reflect resume_data-only approach"
```

---

### Task 19: Final verification and summary

**Step 1: Verify no legacy references remain**

```bash
grep -r "generic_resume\.md" . --exclude-dir=.git --exclude-dir=tmp --exclude="*.md" | grep -v "docs/plans/2026-01-04-remove-legacy-templates.md"
```

Expected: No matches in code files (only in this plan and possibly README)

```bash
grep -r "projects\.yml" . --exclude-dir=.git --exclude-dir=tmp --exclude="*.md" | grep -v "docs/plans/2026-01-04-remove-legacy-templates.md"
```

Expected: No matches in code files

**Step 2: Run full test suite one final time**

Run: `./bin/jojo test`

Expected: ✅ All tests pass

**Step 3: Review git log**

Run: `git log --oneline -20`

Expected: Clean commit history with conventional commit messages

**Step 4: Create summary commit**

```bash
git commit --allow-empty -m "refactor: complete removal of legacy template support

This refactoring eliminates the hybrid state where both legacy formats
(generic_resume.md and projects.yml) and the new format (resume_data.yml)
were supported.

Changes:
- Removed ProjectLoader class and all projects.yml support
- Updated generators to use resume_data.yml exclusively
- Removed generic_resume.md from all generators and CLI commands
- Created shared ResumeDataFormatter utility
- Updated setup service to only create resume_data.yml
- Updated documentation and tests

BREAKING CHANGE: Projects must now be defined in resume_data.yml.
Separate projects.yml files are no longer supported."
```

---

## Validation Checklist

After completing all tasks, verify:

- [ ] `./bin/jojo test` passes all tests
- [ ] `jojo setup` creates only resume_data.yml (not generic_resume.md or projects.yml)
- [ ] `jojo new <company>` works with resume_data.yml
- [ ] `jojo annotate <company>` works with resume_data.yml
- [ ] `jojo generate <company>` works with resume_data.yml
- [ ] `jojo research <company>` works with resume_data.yml
- [ ] `jojo cover-letter <company>` works with resume_data.yml
- [ ] No references to `generic_resume.md` or `projects.yml` in lib/ or test/ code
- [ ] Documentation updated (README, design docs)
- [ ] Git history is clean with conventional commits

---

## Notes

- **DRY Principle**: Created `ResumeDataFormatter` to avoid duplicating formatting logic
- **YAGNI**: Removed ProjectLoader and all projects.yml infrastructure since it's unused
- **No Migration Needed**: Product hasn't shipped, so no backward compatibility required
- **Single Source of Truth**: `resume_data.yml` is now the only input format

---

## Estimated Effort

- Phase 1 (ProjectLoader removal): ~8 tasks, ~30-45 minutes
- Phase 2 (generic_resume.md removal): ~7 tasks, ~45-60 minutes
- Phase 3 (Documentation & cleanup): ~5 tasks, ~20-30 minutes

**Total**: ~20 tasks, ~2-2.5 hours
