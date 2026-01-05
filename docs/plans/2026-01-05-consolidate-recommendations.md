# Consolidate Recommendations into resume_data.yml Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate redundancy by consolidating `inputs/recommendations.md` into `resume_data.yml`, creating a single source of truth for testimonials used in both website and resume.

**Architecture:** Replace the markdown-based `RecommendationParser` with YAML-based loading. Website generator reads all recommendations from original `resume_data.yml`, while resume generator reads curated recommendations from `resume_data_curated.yml`. Change schema from simple `endorsements` string array to rich `recommendations` object array with name, title, relationship, and quote fields.

**Tech Stack:** Ruby, ERB templates, YAML, existing ResumeDataLoader

---

## Task 1: Update resume_data.yml Template Schema

**Files:**
- Modify: `templates/resume_data.yml:95`

**Step 1: Update endorsements to recommendations with rich schema**

Replace the endorsements section with:

```yaml
# Recommendations from colleagues, managers, clients
# Used in both resume (curated) and website (all)
recommendations:
  - name: "Jane Smith"
    title: "Senior Engineering Manager"
    relationship: "Former Manager at Acme Corp"
    quote: "Outstanding engineer with excellent problem-solving skills and strong technical leadership. Consistently delivered high-quality work under tight deadlines."
  - name: "Bob Johnson"
    title: "Lead Developer"
    relationship: "Colleague at Tech Co"
    quote: "Exceptional technical expertise combined with collaborative approach. Made complex systems understandable to the entire team."
```

**Step 2: Verify YAML is valid**

Run: `ruby -e "require 'yaml'; YAML.load_file('templates/resume_data.yml')"`
Expected: No syntax errors

**Step 3: Commit**

```bash
git add templates/resume_data.yml
git commit -m "refactor: change endorsements to recommendations with rich schema"
```

---

## Task 2: Update config.yml Template

**Files:**
- Modify: `templates/config.yml.erb:27`

**Step 1: Change endorsements to recommendations**

Replace:
```yaml
endorsements: [remove]
```

With:
```yaml
recommendations: [remove]
```

**Step 2: Commit**

```bash
git add templates/config.yml.erb
git commit -m "refactor: update config template for recommendations field"
```

---

## Task 3: Update Website Generator to Load from YAML

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb:368-389`

**Step 1: Write the failing test**

File: `test/unit/generators/website_generator_recommendations_test.rb`

Find the test that uses `recommendations.md` and update it to expect YAML loading:

```ruby
def test_loads_recommendations_from_resume_data_yml
  resume_data_content = {
    "recommendations" => [
      {
        "name" => "Jane Smith",
        "title" => "Engineering Manager",
        "relationship" => "Former Manager",
        "quote" => "Great engineer"
      }
    ]
  }.to_yaml

  Dir.mktmpdir do |dir|
    resume_data_path = File.join(dir, "resume_data.yml")
    File.write(resume_data_path, resume_data_content)

    generator = WebsiteGenerator.new(
      inputs_path: dir,
      config_path: "test/fixtures/valid_config.yml",
      output_path: "outputs/test"
    )

    recommendations = generator.send(:load_recommendations)

    assert_equal 1, recommendations.length
    assert_equal "Jane Smith", recommendations[0][:name]
    assert_equal "Great engineer", recommendations[0][:quote]
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/website_generator_recommendations_test.rb`
Expected: FAIL - method still looking for recommendations.md

**Step 3: Update load_recommendations method**

File: `lib/jojo/generators/website_generator.rb:368-389`

Replace the entire method with:

```ruby
def load_recommendations
  resume_data_path = File.join(inputs_path, "resume_data.yml")

  unless File.exist?(resume_data_path)
    log "No resume data found at #{resume_data_path}"
    return nil
  end

  loader = ResumeDataLoader.new(resume_data_path)
  resume_data = loader.load

  recommendations = resume_data["recommendations"]
  return nil if recommendations.nil? || recommendations.empty?

  # Convert to symbol keys for template compatibility
  recommendations.map { |r| r.transform_keys(&:to_sym) }
rescue => e
  log "Error loading recommendations: #{e.message}"
  nil
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/website_generator_recommendations_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/generators/website_generator.rb test/unit/generators/website_generator_recommendations_test.rb
git commit -m "refactor: load recommendations from resume_data.yml instead of markdown"
```

---

## Task 4: Update Website Template Field Names

**Files:**
- Modify: `templates/website/default.html.erb:904-916`

**Step 1: Update carousel template to use new field names**

Find the recommendations carousel section and replace field names:
- `:recommender_name` → `:name`
- `:recommender_title` → `:title`
- Keep `:relationship` and `:quote` unchanged

**Step 2: Test website generation**

Run: `./bin/jojo generate --inputs test/fixtures --config test/fixtures/valid_config.yml`
Expected: Website generates without errors (recommendations section may be empty if fixtures don't have data yet)

**Step 3: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "refactor: update website template for new recommendation field names"
```

---

## Task 5: Update Resume Template

**Files:**
- Modify: `templates/default_resume.md.erb:37-43`

**Step 1: Write failing test for resume rendering**

File: `test/unit/generators/resume_generator_test.rb` (or similar)

Add test that verifies recommendations render with attribution:

```ruby
def test_renders_recommendations_with_attribution
  resume_data = {
    "recommendations" => [
      {
        "name" => "Jane Smith",
        "title" => "Engineering Manager",
        "quote" => "Outstanding engineer"
      }
    ]
  }

  # Test that rendered output includes quote and attribution
  rendered = render_resume_with_data(resume_data)

  assert_includes rendered, "Outstanding engineer"
  assert_includes rendered, "Jane Smith"
  assert_includes rendered, "Engineering Manager"
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb -n test_renders_recommendations_with_attribution`
Expected: FAIL - template uses old endorsements field

**Step 3: Update resume template**

File: `templates/default_resume.md.erb:37-43`

Replace:

```erb
<% if endorsements && !endorsements.empty? %>
## Endorsements

<% endorsements.each do |endorsement| %>
> <%= endorsement %>
<% end %>
<% end %>
```

With:

```erb
<% if recommendations && !recommendations.empty? %>
## Recommendations

<% recommendations.each do |rec| %>
> <%= rec["quote"] %>
<% if rec["name"] %>
— **<%= rec["name"] %><% if rec["title"] %>, <%= rec["title"] %><% end %>**
<% end %>

<% end %>
<% end %>
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb -n test_renders_recommendations_with_attribution`
Expected: PASS

**Step 5: Commit**

```bash
git add templates/default_resume.md.erb
git commit -m "refactor: update resume template to use recommendations with attribution"
```

---

## Task 6: Remove RecommendationParser Require

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb:7`

**Step 1: Remove require statement**

Delete the line:
```ruby
require_relative "../recommendation_parser"
```

**Step 2: Run tests to verify no broken dependencies**

Run: `ruby -Ilib:test test/unit/generators/website_generator_recommendations_test.rb`
Expected: PASS (no load errors)

**Step 3: Commit**

```bash
git add lib/jojo/generators/website_generator.rb
git commit -m "refactor: remove RecommendationParser require"
```

---

## Task 7: Delete RecommendationParser

**Files:**
- Delete: `lib/jojo/recommendation_parser.rb`
- Delete: `test/unit/recommendation_parser_test.rb`

**Step 1: Delete parser file**

Run: `git rm lib/jojo/recommendation_parser.rb`

**Step 2: Delete parser test**

Run: `git rm test/unit/recommendation_parser_test.rb`

**Step 3: Run full test suite to ensure nothing depends on it**

Run: `./bin/jojo test`
Expected: All tests pass (or only expected failures from incomplete work)

**Step 4: Commit**

```bash
git commit -m "refactor: delete RecommendationParser class and tests"
```

---

## Task 8: Delete recommendations.md Template

**Files:**
- Delete: `templates/recommendations.md`

**Step 1: Delete template file**

Run: `git rm templates/recommendations.md`

**Step 2: Commit**

```bash
git commit -m "refactor: remove recommendations.md template"
```

---

## Task 9: Update Setup Service

**Files:**
- Modify: `lib/jojo/setup_service.rb:242-266`

**Step 1: Remove recommendations.md from input_files hash**

Find the `input_files` hash and remove the `recommendations.md` entry:

```ruby
input_files = {
  "resume_data.yml" => "(customize with your experience)",
  # Remove this line:
  # "recommendations.md" => "(optional - customize or delete)"
}
```

**Step 2: Update any summary text that mentions recommendations.md**

Search for references to recommendations.md in setup messages and remove them.

**Step 3: Test setup command**

Run: `./bin/jojo setup --inputs test_setup_dir --overwrite`
Expected: Only resume_data.yml created, no recommendations.md

Clean up: `rm -rf test_setup_dir`

**Step 4: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "refactor: remove recommendations.md from setup flow"
```

---

## Task 10: Update Test Fixtures - resume_data.yml

**Files:**
- Modify: `test/fixtures/resume_data.yml:95`

**Step 1: Update fixtures to use recommendations**

Change from:
```yaml
endorsements:
  - "Great quote"
```

To:
```yaml
recommendations:
  - name: "Test Person"
    title: "Test Title"
    relationship: "Test Relationship"
    quote: "Great quote"
```

**Step 2: Verify tests still pass**

Run: `./bin/jojo test`
Expected: Tests that use fixtures now work with new schema

**Step 3: Commit**

```bash
git add test/fixtures/resume_data.yml
git commit -m "test: update fixtures to use recommendations schema"
```

---

## Task 11: Delete recommendations.md Fixtures

**Files:**
- Delete: All `test/fixtures/recommendations*.md` files

**Step 1: Find all recommendation markdown fixtures**

Run: `find test/fixtures -name "recommendations*.md"`

**Step 2: Delete them**

Run: `git rm test/fixtures/recommendations*.md` (or specific files found)

**Step 3: Run tests to ensure none depend on these**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 4: Commit**

```bash
git commit -m "test: remove recommendations.md fixtures"
```

---

## Task 12: Update Integration Tests

**Files:**
- Modify: `test/integration/recommendations_workflow_test.rb`

**Step 1: Update test to use resume_data.yml**

Replace any file writes to `recommendations.md` with updates to `resume_data.yml`:

```ruby
def test_recommendations_appear_in_website
  Dir.mktmpdir do |dir|
    # Instead of:
    # File.write(File.join(dir, "recommendations.md"), content)

    # Do:
    resume_data = {
      "recommendations" => [
        {
          "name" => "Jane Smith",
          "title" => "Manager",
          "relationship" => "Former Manager",
          "quote" => "Great engineer"
        }
      ]
    }
    File.write(File.join(dir, "resume_data.yml"), resume_data.to_yaml)

    # ... rest of test
  end
end
```

**Step 2: Run integration tests**

Run: `ruby -Ilib:test test/integration/recommendations_workflow_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add test/integration/recommendations_workflow_test.rb
git commit -m "test: update integration tests to use YAML recommendations"
```

---

## Task 13: Update ERB Renderer Tests

**Files:**
- Modify: `test/unit/erb_renderer_test.rb:39`

**Step 1: Update test to use recommendations object format**

Find test that uses `"endorsements"` and update:

```ruby
# Change from:
data = { "endorsements" => ["Great quote"] }

# To:
data = {
  "recommendations" => [
    { "name" => "Test", "quote" => "Great quote" }
  ]
}
```

**Step 2: Run test**

Run: `ruby -Ilib:test test/unit/erb_renderer_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add test/unit/erb_renderer_test.rb
git commit -m "test: update ERB renderer test for recommendations"
```

---

## Task 14: Update Other Test References

**Files:**
- Search and update any remaining references

**Step 1: Search for endorsements references**

Run: `grep -r "endorsements" test/`
Expected: Find any remaining test files referencing old field

**Step 2: Update each file found**

For each file, change `endorsements` to `recommendations` and update format if needed.

**Step 3: Run full test suite**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add test/
git commit -m "test: update remaining test references to recommendations"
```

---

## Task 15: Run Full Test Suite

**Files:**
- None (verification only)

**Step 1: Run complete test suite**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 2: If any failures, fix them**

Address any test failures before proceeding.

**Step 3: Commit any fixes**

```bash
git add .
git commit -m "fix: address test failures from refactoring"
```

---

## Task 16: Manual Verification - Website Generation

**Files:**
- None (verification only)

**Step 1: Create test inputs directory**

```bash
mkdir -p test_manual/inputs
cp templates/resume_data.yml test_manual/inputs/
cp templates/config.yml.erb test_manual/inputs/config.yml
```

**Step 2: Add test recommendations to resume_data.yml**

Edit `test_manual/inputs/resume_data.yml` and add recommendations section with sample data.

**Step 3: Generate website**

Run: `./bin/jojo generate --inputs test_manual/inputs --config test_manual/inputs/config.yml --outputs test_manual/outputs`

**Step 4: Verify carousel appears**

Open generated website in browser and verify recommendations carousel displays correctly.

**Step 5: Clean up**

Run: `rm -rf test_manual/`

---

## Task 17: Manual Verification - Resume Generation

**Files:**
- None (verification only)

**Step 1: Use same test directory from Task 16 setup**

```bash
mkdir -p test_manual/inputs
cp templates/resume_data.yml test_manual/inputs/
cp templates/config.yml.erb test_manual/inputs/config.yml
```

**Step 2: Generate resume**

Run: `./bin/jojo generate --inputs test_manual/inputs --config test_manual/inputs/config.yml --outputs test_manual/outputs`

**Step 3: Check curated resume**

Run: `cat test_manual/outputs/resume_curated.md | grep -A 5 "Recommendations"`
Expected: Recommendations section with quotes and attribution

**Step 4: Clean up**

Run: `rm -rf test_manual/`

---

## Task 18: Update README (if needed)

**Files:**
- Modify: `README.md` (if it contains permission examples)

**Step 1: Search for endorsements in README**

Run: `grep -n "endorsements" README.md`

**Step 2: Update any permission examples**

Change `endorsements: [remove]` to `recommendations: [remove]`

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update README for recommendations field rename"
```

---

## Task 19: Final Verification

**Files:**
- None (verification only)

**Step 1: Search for any remaining references to endorsements**

Run: `grep -r "endorsements" lib/ templates/ --exclude-dir=.git`
Expected: No results (or only in comments/docs explaining migration)

**Step 2: Search for any remaining references to recommendations.md**

Run: `grep -r "recommendations\.md" lib/ templates/ --exclude-dir=.git`
Expected: No results

**Step 3: Run full test suite one final time**

Run: `./bin/jojo test`
Expected: All tests pass

---

## Completion Checklist

- [ ] All tests pass
- [ ] Website generates with recommendations from YAML
- [ ] Resume generates with curated recommendations
- [ ] Setup command creates only resume_data.yml (no recommendations.md)
- [ ] No references to old `endorsements` field remain
- [ ] No references to `recommendations.md` remain
- [ ] RecommendationParser deleted
- [ ] All fixture files updated
- [ ] Manual verification complete
