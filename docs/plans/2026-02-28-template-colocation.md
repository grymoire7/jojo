# Template Co-location and Fallback Resolution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move all output templates to `templates/`, establish a user-override fallback pattern so `inputs/templates/` takes precedence over `templates/`, rename templates to drop the awkward `default_` prefix, and update docs accordingly.

**Architecture:** Each generator resolves its template by first checking `inputs/templates/` (gitignored, user-customized), then falling back to `templates/` (tracked, always current). The website generator extends this fallback to static assets as well. The configure setup stops copying the ERB template since it's now always available from `templates/` directly.

**Tech Stack:** Ruby, ERB, Minitest

---

### Task 1: Rename template files

**Files:**
- Rename: `templates/default_resume.md.erb` → `templates/resume.md.erb`
- Rename: `templates/website/default.html.erb` → `templates/website/index.html.erb`
- Move: `lib/jojo/commands/cover_letter/cover_letter.md.erb` → `templates/cover_letter.md.erb`

**Step 1: Rename the files with git mv**

```bash
git mv templates/default_resume.md.erb templates/resume.md.erb
git mv templates/website/default.html.erb templates/website/index.html.erb
git mv lib/jojo/commands/cover_letter/cover_letter.md.erb templates/cover_letter.md.erb
```

**Step 2: Run tests to see what breaks**

Run: `./bin/test`
Expected: Multiple failures referencing old filenames — that's expected and will be fixed in subsequent tasks.

**Step 3: Commit the renames**

```bash
git add -A
git commit -m "refactor: rename and relocate output template files"
```

---

### Task 2: Update resume generator to use fallback template resolution

**Files:**
- Modify: `lib/jojo/commands/resume/generator.rb`
- Test: `test/unit/commands/resume/generator_test.rb`

**Step 1: Write failing tests for fallback behavior**

In `test/unit/commands/resume/generator_test.rb`, add two tests that call the private `resolve_template_path` method directly (use `send`):

```ruby
def test_resolve_template_path_returns_inputs_override_when_present
  FileUtils.mkdir_p(File.join(inputs_path, "templates"))
  override = File.join(inputs_path, "templates", "resume.md.erb")
  File.write(override, "override")

  generator = build_generator  # however generators are built in this test file
  result = generator.send(:resolve_template_path, "resume.md.erb")

  assert_equal override, result
ensure
  FileUtils.rm_f(override)
end

def test_resolve_template_path_falls_back_to_templates_dir
  # No file at inputs/templates/resume.md.erb
  generator = build_generator
  result = generator.send(:resolve_template_path, "resume.md.erb")

  assert_equal File.join("templates", "resume.md.erb"), result
end
```

Look at the existing test file setup to know how generators are constructed there and follow the same pattern.

**Step 2: Run tests to confirm failure**

Run: `./bin/test test/unit/commands/resume/generator_test.rb`
Expected: FAIL — `resolve_template_path` doesn't exist yet.

**Step 3: Implement fallback in resume generator**

In `lib/jojo/commands/resume/generator.rb`, replace lines 25–26:

```ruby
# Before:
template_path = config.resume_template ||
  File.join(inputs_path, "templates", "default_resume.md.erb")

# After:
template_path = config.resume_template || resolve_template_path("resume.md.erb")
```

Add private method:

```ruby
def resolve_template_path(filename)
  user_path = File.join(inputs_path, "templates", filename)
  return user_path if File.exist?(user_path)
  File.join("templates", filename)
end
```

**Step 4: Run tests**

Run: `./bin/test test/unit/commands/resume/generator_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/resume/generator.rb test/unit/commands/resume/generator_test.rb
git commit -m "feat: resume generator resolves template from inputs/templates with fallback"
```

---

### Task 3: Update cover letter generator to use fallback template resolution

**Files:**
- Modify: `lib/jojo/commands/cover_letter/generator.rb`
- Modify: `test/unit/cover_letter_template_test.rb`

**Step 1: Write a failing test for user-override behavior**

In `test/unit/cover_letter_template_test.rb`, add a test and update `setup`:

```ruby
def setup
  super
  copy_templates  # ADD THIS LINE so templates/cover_letter.md.erb resolves in tmpdir
  # ... rest of setup unchanged
end

def test_uses_inputs_template_override_when_present
  FileUtils.mkdir_p(fixture_path("templates"))
  File.write(fixture_path("templates/cover_letter.md.erb"), "OVERRIDE: <%= body %>")

  mock_ai = Minitest::Mock.new
  mock_ai.expect(:generate_text, "letter body", [String])
  @config.expect(:voice_and_tone, "professional")
  @config.expect(:base_url, "https://example.com")

  generator = Jojo::Commands::CoverLetter::Generator.new(
    @application, mock_ai,
    config: @config,
    inputs_path: fixture_path
  )
  result = generator.generate

  assert_includes result, "OVERRIDE: letter body"
  mock_ai.verify
ensure
  FileUtils.rm_f(fixture_path("templates/cover_letter.md.erb"))
end
```

Note: The existing tests in this file each set up their own `@config` mock expectations — check how many `voice_and_tone`/`base_url` calls each test expects and make sure `setup`'s mock expectations account for `copy_templates` not adding any extras.

**Step 2: Run tests to confirm failure**

Run: `./bin/test test/unit/cover_letter_template_test.rb`
Expected: FAIL — `TEMPLATE_PATH` still hardcoded, existing tests fail because template was moved in Task 1.

**Step 3: Replace hardcoded TEMPLATE_PATH with fallback resolution**

In `lib/jojo/commands/cover_letter/generator.rb`:

Remove:
```ruby
TEMPLATE_PATH = File.expand_path("cover_letter.md.erb", __dir__)
```

In `render_template`, replace:
```ruby
# Before:
renderer = ErbRenderer.new(TEMPLATE_PATH)

# After:
renderer = ErbRenderer.new(resolve_template_path("cover_letter.md.erb"))
```

Add private method:
```ruby
def resolve_template_path(filename)
  user_path = File.join(inputs_path, "templates", filename)
  return user_path if File.exist?(user_path)
  File.join("templates", filename)
end
```

**Step 4: Run tests**

Run: `./bin/test test/unit/cover_letter_template_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/cover_letter/generator.rb test/unit/cover_letter_template_test.rb
git commit -m "feat: cover letter generator resolves template from inputs/templates with fallback"
```

---

### Task 4: Update website generator — fallback for template and assets, rename default→index

**Files:**
- Modify: `lib/jojo/commands/website/generator.rb`
- Modify: `lib/jojo/cli.rb`
- Modify: `lib/jojo/commands/website/command.rb`
- Modify: `test/unit/commands/website/generator_test.rb`
- Modify: `test/unit/commands/website/command_test.rb`
- Modify: `test/integration/website_workflow_test.rb`
- Modify: `test/integration/projects_workflow_test.rb`

**Step 1: Write failing tests for user-override behavior**

In `test/unit/commands/website/generator_test.rb`, add:

```ruby
def test_uses_inputs_template_override_when_present
  override_dir = File.join(fixture_path, "templates", "website")
  FileUtils.mkdir_p(override_dir)
  File.write(File.join(override_dir, "index.html.erb"), "<html>OVERRIDE: <%= seeker_name %></html>")

  result = @generator.generate  # @generator already uses inputs_path: fixture_path

  assert_includes result, "OVERRIDE: Jane Doe"
ensure
  FileUtils.rm_f(File.join(override_dir, "index.html.erb"))
end

def test_uses_inputs_asset_override_when_present
  override_dir = File.join(fixture_path, "templates", "website")
  FileUtils.mkdir_p(override_dir)
  File.write(File.join(override_dir, "script.js"), "// CUSTOM JS")

  @generator.generate

  assert_includes File.read(File.join(@application.website_path, "script.js")), "// CUSTOM JS"
ensure
  FileUtils.rm_f(File.join(override_dir, "script.js"))
end
```

**Step 2: Run tests to confirm existing tests already fail**

Run: `./bin/test test/unit/commands/website/generator_test.rb`
Expected: FAIL — `index.html.erb` not found because generator still looks for `default.html.erb`.

**Step 3: Update website generator**

In `lib/jojo/commands/website/generator.rb`:

Change initializer default (line 14):
```ruby
# Before:
def initialize(application, ai_client, config:, template: "default", ...)
# After:
def initialize(application, ai_client, config:, template: "index", ...)
```

Replace `render_template` path resolution (around line 161):
```ruby
# Before:
template_path = File.join("templates", "website", "#{template_name}.html.erb")
unless File.exist?(template_path)
  raise "Template not found: #{template_path}. Available templates: #{available_templates.join(", ")}"
end

# After:
template_path = resolve_template_path("website/#{template_name}.html.erb")
unless File.exist?(template_path)
  raise "Template not found: #{template_name}. Available templates: #{available_templates.join(", ")}"
end
```

Update `copy_template_assets` to use fallback per asset:
```ruby
def copy_template_assets
  FileUtils.mkdir_p(application.website_path)
  build_tailwind_css
  ["script.js", "icons.svg"].each do |asset|
    source = resolve_template_path("website/#{asset}")
    dest = File.join(application.website_path, asset)
    if File.exist?(source)
      FileUtils.cp(source, dest)
      log "Copied #{asset} to #{application.website_path}"
    else
      log "Warning: Asset not found: #{asset}"
    end
  end
end
```

Add private method:
```ruby
def resolve_template_path(relative)
  user_path = File.join(inputs_path, "templates", relative)
  return user_path if File.exist?(user_path)
  File.join("templates", relative)
end
```

**Step 4: Update CLI default in `lib/jojo/cli.rb`**

```ruby
# Before:
class_option :template, ..., desc: "Website template name (default: default)", default: "default"
# After:
class_option :template, ..., desc: "Website template name (default: index)", default: "index"
```

**Step 5: Update website command fallback in `lib/jojo/commands/website/command.rb` (line ~60)**

```ruby
# Before:
options[:template] || "default"
# After:
options[:template] || "index"
```

**Step 6: Update tests referencing the "default" template name**

In `test/unit/commands/website/command_test.rb`, change all three:
```ruby
metadata: {template: "default"}  →  metadata: {template: "index"}
```

In `test/integration/website_workflow_test.rb` (line 50):
```ruby
template: "default"  →  template: "index"
```

In `test/integration/projects_workflow_test.rb` (line 79):
```ruby
template: "default"  →  template: "index"
```

**Step 7: Run tests**

Run: `./bin/test test/unit/commands/website/ test/integration/website_workflow_test.rb test/integration/projects_workflow_test.rb`
Expected: PASS

**Step 8: Commit**

```bash
git add lib/jojo/commands/website/generator.rb lib/jojo/cli.rb lib/jojo/commands/website/command.rb
git add test/unit/commands/website/ test/integration/website_workflow_test.rb test/integration/projects_workflow_test.rb
git commit -m "feat: website generator resolves template and assets from inputs/templates with fallback"
```

---

### Task 5: Clean up configure service — stop copying ERB template

**Files:**
- Modify: `lib/jojo/commands/configure/service.rb`
- Modify: `test/unit/commands/configure/service_test.rb`
- Modify: `test/integration/setup_integration_test.rb`

**Step 1: Update configure service**

In `lib/jojo/commands/configure/service.rb`, in `setup_input_files`:

Remove the entire ERB copy block (lines ~270–288):
```ruby
# DELETE THIS ENTIRE BLOCK:
# Copy resume template to inputs/templates/
template_file = "default_resume.md.erb"
target_template_path = File.join("inputs", "templates", template_file)
source_template_path = File.join("templates", template_file)
if File.exist?(target_template_path) && !@overwrite
  ...
end
```

Keep the `FileUtils.mkdir_p("inputs/templates")` line — it's a useful empty "inbox" for the user.

In `show_summary`, remove the `inputs/templates/default_resume.md.erb` key from `file_descriptions`:
```ruby
# Remove this line:
"inputs/templates/default_resume.md.erb" => "Resume rendering template"
```

Update the step 2 next-steps message:
```ruby
# Before:
@cli.say "  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"
# After:
@cli.say "  2. Copy templates/resume.md.erb to inputs/templates/ to customize resume layout"
```

**Step 2: Update service unit tests in `test/unit/commands/configure/service_test.rb`**

`test_setup_input_files_creates_inputs_directory_if_missing`:
- Remove `File.write("templates/default_resume.md.erb", ...)` setup line
- Change `2.times { cli.expect :say, nil, [String, :green] }` to `1.times` (only `resume_data.yml` is created now)
- Remove the `assert_equal true, Dir.exist?("inputs/templates")` assertion (or keep it — the mkdir still runs)

`test_setup_input_files_copies_template_files_to_inputs`:
- Remove `File.write("templates/default_resume.md.erb", ...)` setup line
- Remove `cli.expect :say, nil, ["✓ Created inputs/templates/default_resume.md.erb (resume ERB template)", :green]`
- Remove the two `assert_*` lines about `inputs/templates/default_resume.md.erb`

`test_setup_input_files_skips_existing_files_unless_overwrite_mode`:
- Remove `File.write("templates/default_resume.md.erb", "Template ERB")`
- Remove `cli.expect :say, nil, ["✓ Created inputs/templates/default_resume.md.erb (resume ERB template)", :green]`

Both `test_show_summary_*` tests — change the step 2 expected string:
```ruby
# Before:
cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
# After:
cli.expect :say, nil, ["  2. Copy templates/resume.md.erb to inputs/templates/ to customize resume layout"]
```

**Step 3: Update setup integration tests in `test/integration/setup_integration_test.rb`**

All three step-2 `cli.expect :say` calls (lines 66, 151, 223):
```ruby
# Before:
cli.expect :say, nil, ["  2. Edit inputs/templates/default_resume.md.erb to customize resume layout"]
# After:
cli.expect :say, nil, ["  2. Copy templates/resume.md.erb to inputs/templates/ to customize resume layout"]
```

`setup_template_files` method (line ~258):
```ruby
# Before:
FileUtils.cp(File.join(templates_dir, "default_resume.md.erb"), "templates/default_resume.md.erb")
# After:
FileUtils.cp(File.join(templates_dir, "resume.md.erb"), "templates/resume.md.erb")
```

**Step 4: Run tests**

Run: `./bin/test test/unit/commands/configure/ test/integration/setup_integration_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/commands/configure/service.rb
git add test/unit/commands/configure/service_test.rb test/integration/setup_integration_test.rb
git commit -m "refactor: setup no longer copies resume ERB template; update next-steps message"
```

---

### Task 6: Update user-facing documentation

**Files:**
- Modify: `docs/getting-started/quick-start.md`
- Modify: `docs/getting-started/configuration.md`
- Modify: `docs/guides/website-templates.md`
- Modify: `docs/commands/configure.md`
- Modify: `docs/commands/website.md`
- Modify: `docs/commands/index.md`

**Step 1: Update `docs/getting-started/quick-start.md` (line 34)**

```
# Before:
nvim inputs/templates/default_resume.md.erb
# After:
nvim inputs/templates/resume.md.erb
```

**Step 2: Update `docs/getting-started/configuration.md` (lines 98–100)**

Replace:
```markdown
### `inputs/templates/default_resume.md.erb`

ERB template used to render `resume_data.yml` into markdown. Customize to change how your resume is formatted.
```

With:
```markdown
### Customizing templates

Output templates live in `templates/` — `resume.md.erb`, `cover_letter.md.erb`, and `website/index.html.erb`. Jojo uses these defaults automatically.

To customize any template, copy it to `inputs/templates/` and edit it there. Jojo checks `inputs/templates/` first and falls back to `templates/` if no override exists:

```bash
# Customize the resume template
cp templates/resume.md.erb inputs/templates/resume.md.erb
nvim inputs/templates/resume.md.erb

# Customize the cover letter template
cp templates/cover_letter.md.erb inputs/templates/cover_letter.md.erb

# Customize the website template and its assets
cp templates/website/index.html.erb inputs/templates/website/index.html.erb
cp templates/website/script.js inputs/templates/website/script.js
```

The `inputs/` directory is gitignored, so your customizations stay private.
```

**Step 3: Update `docs/guides/website-templates.md`**

Update the "Creating custom templates" section (line ~38–54):

Change the copy command:
```bash
# Before:
cp templates/website/default.html.erb templates/website/modern.html.erb
# After:
cp templates/website/index.html.erb templates/website/modern.html.erb
```

Add a new section after "Creating custom templates" explaining the override pattern:

```markdown
## Overriding the default template

To customize the default website template without creating a named variant, copy it to `inputs/templates/website/`:

```bash
mkdir -p inputs/templates/website
cp templates/website/index.html.erb inputs/templates/website/index.html.erb
nvim inputs/templates/website/index.html.erb
```

Jojo will use your override automatically — no `-t` flag needed. You can also override static assets the same way:

```bash
cp templates/website/script.js inputs/templates/website/script.js
cp templates/website/icons.svg inputs/templates/website/icons.svg
```
```

Also update the note at line ~98 if it says "single HTML files with inline CSS" — this is now outdated since the design uses Tailwind. Review and update the "Design guidelines" section if needed.

**Step 4: Update `docs/commands/configure.md` (line ~30)**

```
# Before:
| `inputs/templates/default_resume.md.erb` | Resume rendering template |
# After:
remove this row — setup no longer creates this file
```

**Step 5: Update `docs/commands/website.md` (line ~37)**

Review the `inputs/templates/*` row — update description to reflect the new override pattern:
```
| `inputs/templates/website/` | Optional template and asset overrides |
```

**Step 6: Update `docs/commands/index.md` (line ~32)**

```
# Before:
| `jojo configure` | ... | `.env`, `config.yml`, `inputs/resume_data.yml`, `inputs/templates/default_resume.md.erb` |
# After:
| `jojo configure` | ... | `.env`, `config.yml`, `inputs/resume_data.yml` |
```

**Step 7: Verify no remaining stale references**

```bash
grep -rn "default_resume\|default\.html\.erb\|cover_letter/cover_letter" docs/ --include="*.md"
```

Expected: No output.

**Step 8: Commit**

```bash
git add docs/
git commit -m "docs: update template paths and customization guide for new fallback pattern"
```

---

### Task 7: Final sweep and verification

**Step 1: Search for all remaining stale references**

```bash
grep -rn "default_resume\.md\.erb\|website/default\.html\|cover_letter/cover_letter\.md\.erb" lib/ test/ docs/ --include="*.rb" --include="*.md"
```

Expected: No output.

**Step 2: Run full test suite**

Run: `./bin/test`
Expected: All PASS

**Step 3: Commit if any stragglers were fixed, otherwise done**
