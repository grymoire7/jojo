# Cover Letter ERB Template Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wrap the AI-generated cover letter body in a proper letter structure (sender header, date, salutation, closing, P.S.) using an ERB template.

**Architecture:** Add `cover_letter.md.erb` alongside the generator. Use the existing `ErbRenderer` class (already used by resume curation). Replace `add_landing_page_link` in generator with `render_template`, which passes contact info from `resume_data` and a generated date. The AI prompt is unchanged — it continues to generate only the body.

**Tech Stack:** Ruby ERB, `Jojo::ErbRenderer` (lib/jojo/erb_renderer.rb), Minitest

---

### Task 1: Add `website` field to test fixture

**Files:**
- Modify: `test/fixtures/resume_data.yml`

**Step 1: Add `website` field after `email`**

Open `test/fixtures/resume_data.yml`. After the `email` line, add:

```yaml
website: "https://janedoe.example.com"
```

Result should read:
```yaml
name: "Jane Doe"
email: "jane@example.com"
website: "https://janedoe.example.com"
phone: "+1-555-0123"
```

**Step 2: Run the tests to confirm nothing is broken**

```
./bin/test
```

Expected: all tests pass (no existing code reads `website` from this fixture yet).

**Step 3: Commit**

```bash
git add test/fixtures/resume_data.yml
git commit -m "test: add website field to resume_data fixture"
```

---

### Task 2: Create the ERB template

**Files:**
- Create: `lib/jojo/commands/cover_letter/cover_letter.md.erb`

**Step 1: Create the template file**

```erb
<%= name %>
<%= email %> | <%= website %>
<%= date %>

Dear Hiring Manager,

<%= body %>

Sincerely,

<%= name %>

---

*P.S. **Specifically for <%= company_name %>**: <%= landing_page_url %>*
```

**Step 2: Commit**

```bash
git add lib/jojo/commands/cover_letter/cover_letter.md.erb
git commit -m "feat: add cover letter ERB template"
```

---

### Task 3: Write failing unit tests for template rendering

**Files:**
- Create: `test/unit/cover_letter_template_test.rb`

**Step 1: Write the failing test**

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/commands/cover_letter/generator"
require_relative "../../lib/jojo/application"

class CoverLetterTemplateTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("acme-corp")
    @application.create_directory!

    File.write(@application.job_description_path, "Senior Ruby Developer at Acme Corp")
    File.write(@application.resume_path, "# Jane Doe\nSenior Ruby developer")

    @config = Minitest::Mock.new
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://example.com")
  end

  def test_render_template_includes_sender_header
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "This is the letter body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "Jane Doe"
    assert_includes result, "jane@example.com"
    assert_includes result, "https://janedoe.example.com"
    mock_ai.verify
    @config.verify
  end

  def test_render_template_includes_salutation_and_closing
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "This is the letter body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "Dear Hiring Manager,"
    assert_includes result, "This is the letter body."
    assert_includes result, "Sincerely,"
    mock_ai.verify
    @config.verify
  end

  def test_render_template_puts_landing_page_link_in_ps
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "This is the letter body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    assert_includes result, "P.S."
    assert_includes result, "Specifically for Acme Corp"
    assert_includes result, "https://example.com/acme-corp"
    refute result.start_with?("**Specifically")
    mock_ai.verify
    @config.verify
  end

  def test_render_template_date_format
    mock_ai = Minitest::Mock.new
    mock_ai.expect(:generate_text, "Body.", [String])

    generator = Jojo::Commands::CoverLetter::Generator.new(
      @application, mock_ai,
      config: @config,
      inputs_path: fixture_path
    )
    result = generator.generate

    expected_date = Time.now.strftime("%B, %Y")
    assert_includes result, expected_date
    mock_ai.verify
    @config.verify
  end
end
```

**Step 2: Run the tests to verify they fail**

```
./bin/test test/unit/cover_letter_template_test.rb
```

Expected: FAIL — `NoMethodError` or assertion failures because `render_template` doesn't exist and `add_landing_page_link` still runs.

**Step 3: Commit the failing tests**

```bash
git add test/unit/cover_letter_template_test.rb
git commit -m "test: add failing tests for cover letter template rendering"
```

---

### Task 4: Update the generator

**Files:**
- Modify: `lib/jojo/commands/cover_letter/generator.rb`

**Step 1: Add require for ErbRenderer**

At the top of the file, after the existing requires, add:

```ruby
require_relative "../../erb_renderer"
```

**Step 2: Add a constant for the template path**

Inside the `Generator` class (before `def initialize`), add:

```ruby
TEMPLATE_PATH = File.expand_path("cover_letter.md.erb", __dir__)
```

**Step 3: Add `resume_data` to the inputs hash in `gather_inputs`**

In `gather_inputs`, the `loader` and `resume_data` are already loaded (line 66-67). Add `resume_data:` to the returned hash:

Change the return hash from:
```ruby
{
  job_description: job_description,
  tailored_resume: tailored_resume,
  generic_resume: generic_resume,
  research: research,
  job_details: job_details,
  company_name: application.company_name,
  company_slug: application.slug
}
```

To:
```ruby
{
  job_description: job_description,
  tailored_resume: tailored_resume,
  generic_resume: generic_resume,
  research: research,
  job_details: job_details,
  company_name: application.company_name,
  company_slug: application.slug,
  resume_data: resume_data
}
```

**Step 4: Replace `add_landing_page_link` with `render_template`**

In the `generate` method, change:
```ruby
log "Adding landing page link..."
cover_letter_with_link = add_landing_page_link(cover_letter, inputs)

log "Saving cover letter to #{application.cover_letter_path}..."
save_cover_letter(cover_letter_with_link)

log "Cover letter generation complete!"
cover_letter_with_link
```

To:
```ruby
log "Rendering cover letter template..."
rendered = render_template(cover_letter, inputs)

log "Saving cover letter to #{application.cover_letter_path}..."
save_cover_letter(rendered)

log "Cover letter generation complete!"
rendered
```

**Step 5: Add `render_template` and remove `add_landing_page_link`**

Remove the entire `add_landing_page_link` method and replace with:

```ruby
def render_template(body, inputs)
  resume_data = inputs[:resume_data]
  renderer = ErbRenderer.new(TEMPLATE_PATH)
  renderer.render(
    "name" => resume_data["name"],
    "email" => resume_data["email"],
    "website" => resume_data["website"],
    "date" => Time.now.strftime("%B, %Y"),
    "body" => body,
    "company_name" => inputs[:company_name],
    "landing_page_url" => "#{config.base_url}/#{inputs[:company_slug]}"
  )
end
```

**Step 6: Run the new unit tests**

```
./bin/test test/unit/cover_letter_template_test.rb
```

Expected: all 4 new tests PASS.

---

### Task 5: Update integration tests

The integration tests still assert the old behavior (link prepended, `/resume/` in URL). Update them to match the new structure.

**Files:**
- Modify: `test/integration/cover_letter_generator_integration_test.rb`

**Step 1: Update `test_full_cover_letter_pipeline`**

Replace the assertions block:
```ruby
# Verify landing page link prepended
assert_includes result, "**Specifically for Acme Corp**: https://example.com/resume/acme-corp"
assert_includes result, cover_letter_content

# Verify file saved
assert File.exist?(@application.cover_letter_path)
saved = File.read(@application.cover_letter_path)
assert_includes saved, "Specifically for Acme Corp"
assert_includes saved, cover_letter_content
```

With:
```ruby
# Verify letter structure
assert_includes result, "Jane Doe"
assert_includes result, "Dear Hiring Manager,"
assert_includes result, cover_letter_content
assert_includes result, "Sincerely,"
assert_includes result, "P.S."
assert_includes result, "https://example.com/acme-corp"
refute result.start_with?("**Specifically")

# Verify file saved
assert File.exist?(@application.cover_letter_path)
saved = File.read(@application.cover_letter_path)
assert_includes saved, "Specifically for Acme Corp"
assert_includes saved, cover_letter_content
```

**Step 2: Run all tests**

```
./bin/test
```

Expected: all tests PASS.

**Step 3: Commit**

```bash
git add lib/jojo/commands/cover_letter/generator.rb \
        test/integration/cover_letter_generator_integration_test.rb
git commit -m "feat: use ERB template for cover letter structure"
```

---

### Task 6: Smoke test with a real application

**Step 1: Verify a real cover letter looks correct**

If you have an application directory available, regenerate a cover letter and inspect the output:

```bash
./bin/jojo cover_letter <slug> --overwrite
cat applications/<slug>/cover_letter.md | head -20
```

Expected output starts with:
```
Tracy Atteberry
tracy@tracyatteberry.com | https://tracyatteberry.com
February, 2026

Dear Hiring Manager,
```

And ends with something like:
```
Sincerely,

Tracy Atteberry

---

*P.S. **Specifically for [Company]**: https://tracyatteberry.com/[slug]*
```

**Step 2: Verify the PDF still generates cleanly** (if applicable)

```bash
./bin/jojo pdf <slug>
```

Check the generated PDF looks correct.
