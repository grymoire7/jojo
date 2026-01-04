# Config-Based Permissions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement config-based permission system for resume curation with Ruby-enforced permissions and focused LLM prompts.

**Architecture:** Replace comment-based permissions with config.yml permissions. Create ResumeTransformer pipeline that enforces permissions in Ruby code and makes focused LLM calls for filter/reorder/rewrite operations. Use ERB templates for final rendering.

**Tech Stack:** Ruby, YAML, ERB, Minitest, Anthropic AI (Haiku)

---

## Phase 1: Foundation - Data Structures and Configuration

### Task 1.1: Create sample resume_data.yml fixture

**Files:**
- Create: `test/fixtures/resume_data.yml`

**Step 1: Create resume_data.yml with sample data**

```yaml
# test/fixtures/resume_data.yml
name: "Jane Doe"
email: "jane@example.com"
phone: "+1-555-0123"
location: "San Francisco, CA"

summary: "Experienced software engineer with 10+ years building scalable web applications."

skills:
  - Ruby
  - Python
  - JavaScript
  - PostgreSQL
  - Docker
  - Git

languages:
  - English (native)
  - Spanish (conversational)

databases:
  - PostgreSQL
  - MySQL
  - Redis
  - MongoDB

tools:
  - Docker
  - Git
  - VS Code
  - Linux

experience:
  - company: "TechCorp Inc"
    title: "Senior Software Engineer"
    start_date: "2020-01"
    end_date: "present"
    description: "Led development of microservices architecture serving 1M+ users"
    technologies:
      - Ruby on Rails
      - PostgreSQL
      - Docker
    tags:
      - backend
      - architecture
      - leadership

  - company: "StartupXYZ"
    title: "Software Engineer"
    start_date: "2018-06"
    end_date: "2019-12"
    description: "Built RESTful APIs and improved database query performance by 40%"
    technologies:
      - Python
      - Django
      - MySQL
    tags:
      - backend
      - api-development

  - company: "ConsultingCo"
    title: "Junior Developer"
    start_date: "2015-03"
    end_date: "2018-05"
    description: "Developed client-facing web applications and automated deployment pipelines"
    technologies:
      - JavaScript
      - Node.js
      - PostgreSQL
    tags:
      - frontend
      - devops

projects:
  - name: "Open Source CLI Tool"
    description: "Built command-line interface for managing cloud deployments"
    skills:
      - Ruby
      - AWS
      - Docker

  - name: "E-commerce Platform"
    description: "Developed payment processing integration with Stripe"
    skills:
      - Python
      - PostgreSQL
      - Redis

education:
  - degree: "BS Computer Science"
    institution: "State University"
    year: "2015"
    description: "Focus on algorithms and distributed systems"

endorsements:
  - "Jane is an exceptional engineer who consistently delivers high-quality work"
  - "Her technical leadership transformed our team's productivity"
  - "Outstanding problem solver with strong communication skills"
```

**Step 2: Commit**

```bash
git add test/fixtures/resume_data.yml
git commit -m "feat: add sample resume_data.yml fixture for testing"
```

---

### Task 1.2: Add permissions configuration to config.yml

**Files:**
- Modify: `config.yml`

**Step 1: Add resume_data permissions section**

Add after the `website:` section:

```yaml
# Resume data transformation permissions
resume_data:
  permissions:
    # Top-level array fields
    skills: [remove, reorder]
    languages: [reorder]
    databases: [remove, reorder]
    tools: [remove, reorder]
    projects: [reorder]
    experience: [reorder]
    endorsements: [remove]

    # Scalar/text fields
    summary: [rewrite]

    # Nested fields (dot notation)
    projects.skills: [reorder]
    experience.description: [rewrite]
    experience.technologies: [remove, reorder]
    experience.tags: [remove, reorder]
    education.description: [rewrite]
```

**Step 2: Add to test fixture config**

Modify: `test/fixtures/valid_config.yml`

Add the same `resume_data:` section.

**Step 3: Commit**

```bash
git add config.yml test/fixtures/valid_config.yml
git commit -m "feat: add resume_data permissions configuration"
```

---

## Phase 2: Core Infrastructure - ResumeTransformer Class

### Task 2.1: Create PermissionViolation error class

**Files:**
- Create: `lib/jojo/errors.rb`

**Step 1: Write failing test**

Create: `test/unit/errors_test.rb`

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/errors"

describe Jojo::PermissionViolation do
  it "creates error with message" do
    error = Jojo::PermissionViolation.new("Cannot remove items")
    _(error.message).must_equal "Cannot remove items"
  end

  it "is a StandardError" do
    error = Jojo::PermissionViolation.new("test")
    _(error).must_be_kind_of StandardError
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/errors_test.rb`
Expected: FAIL with "uninitialized constant Jojo::PermissionViolation"

**Step 3: Implement error class**

```ruby
# lib/jojo/errors.rb
module Jojo
  class PermissionViolation < StandardError
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/errors_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/errors.rb test/unit/errors_test.rb
git commit -m "feat: add PermissionViolation error class"
```

---

### Task 2.2: Create ResumeTransformer skeleton

**Files:**
- Create: `lib/jojo/resume_transformer.rb`
- Create: `test/unit/resume_transformer_test.rb`

**Step 1: Write failing test for initialization**

```ruby
# test/unit/resume_transformer_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_transformer"

describe Jojo::ResumeTransformer do
  before do
    @ai_client = Minitest::Mock.new
    @config = {
      "resume_data" => {
        "permissions" => {
          "skills" => ["remove", "reorder"]
        }
      }
    }
    @job_context = {
      job_description: "Looking for Ruby developer with PostgreSQL experience"
    }
    @transformer = Jojo::ResumeTransformer.new(
      ai_client: @ai_client,
      config: @config,
      job_context: @job_context
    )
  end

  it "initializes with required parameters" do
    _(@transformer).wont_be_nil
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL with "cannot load such file -- resume_transformer"

**Step 3: Create minimal implementation**

```ruby
# lib/jojo/resume_transformer.rb
module Jojo
  class ResumeTransformer
    def initialize(ai_client:, config:, job_context:)
      @ai_client = ai_client
      @config = config
      @job_context = job_context
    end

    def transform(data)
      # To be implemented
      data
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: add ResumeTransformer skeleton class"
```

---

## Phase 3: Field Access Helpers

### Task 3.1: Implement get_field for nested access

**Files:**
- Modify: `lib/jojo/resume_transformer.rb`
- Modify: `test/unit/resume_transformer_test.rb`

**Step 1: Write failing test**

Add to `test/unit/resume_transformer_test.rb`:

```ruby
describe "#get_field" do
  it "gets top-level field" do
    data = { "skills" => ["Ruby", "Python"] }
    result = @transformer.send(:get_field, data, "skills")
    _(result).must_equal ["Ruby", "Python"]
  end

  it "gets nested field with dot notation" do
    data = {
      "experience" => [
        { "description" => "Led team" }
      ]
    }
    result = @transformer.send(:get_field, data, "experience.description")
    _(result).must_equal "Led team"
  end

  it "returns nil for missing field" do
    data = { "skills" => [] }
    result = @transformer.send(:get_field, data, "nonexistent")
    _(result).must_be_nil
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL with undefined method error

**Step 3: Implement get_field**

Add to `lib/jojo/resume_transformer.rb` (private section):

```ruby
private

def get_field(data, field_path)
  parts = field_path.split(".")
  parts.reduce(data) { |obj, key| obj&.dig(key) }
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: implement get_field for nested field access"
```

---

### Task 3.2: Implement set_field for nested updates

**Files:**
- Modify: `lib/jojo/resume_transformer.rb`
- Modify: `test/unit/resume_transformer_test.rb`

**Step 1: Write failing test**

Add to test file:

```ruby
describe "#set_field" do
  it "sets top-level field" do
    data = { "skills" => ["Ruby"] }
    @transformer.send(:set_field, data, "skills", ["Python"])
    _(data["skills"]).must_equal ["Python"]
  end

  it "sets field on all array items" do
    data = {
      "experience" => [
        { "description" => "old" },
        { "description" => "old" }
      ]
    }
    @transformer.send(:set_field, data, "experience.description", "new")
    _(data["experience"][0]["description"]).must_equal "new"
    _(data["experience"][1]["description"]).must_equal "new"
  end

  it "sets nested scalar field" do
    data = { "contact" => { "email" => "old@example.com" } }
    @transformer.send(:set_field, data, "contact.email", "new@example.com")
    _(data["contact"]["email"]).must_equal "new@example.com"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL

**Step 3: Implement set_field**

Add to private section:

```ruby
def set_field(data, field_path, value)
  parts = field_path.split(".")
  *path, key = parts

  if path.empty?
    # Top-level field
    data[key] = value
  else
    # Navigate to parent
    target = path.reduce(data) { |obj, k| obj[k] }

    if target.is_a?(Array)
      # Setting field on array items
      target.each { |item| item[key] = value }
    else
      target[key] = value
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: implement set_field for nested field updates"
```

---

## Phase 4: Filter Transformation

### Task 4.1: Implement filter_field

**Files:**
- Modify: `lib/jojo/resume_transformer.rb`
- Modify: `test/unit/resume_transformer_test.rb`

**Step 1: Write failing test**

Add to test file:

```ruby
describe "#filter_field" do
  it "filters array items using AI" do
    data = { "skills" => ["Ruby", "Python", "Java", "C++", "Go"] }

    # Mock AI to return indices [0, 1, 4] (keep Ruby, Python, Go)
    @ai_client.expect(:generate_text, "[0, 1, 4]", [String])

    @transformer.send(:filter_field, "skills", data)

    _(data["skills"]).must_equal ["Ruby", "Python", "Go"]
    @ai_client.verify
  end

  it "does nothing for non-array fields" do
    data = { "summary" => "Some text" }

    @transformer.send(:filter_field, "summary", data)

    _(data["summary"]).must_equal "Some text"
  end

  it "does nothing for missing fields" do
    data = { "skills" => ["Ruby"] }

    @transformer.send(:filter_field, "nonexistent", data)

    _(data["skills"]).must_equal ["Ruby"]
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL

**Step 3: Implement filter_field**

Add to private section:

```ruby
def filter_field(field_path, data)
  items = get_field(data, field_path)
  return unless items.is_a?(Array)

  # Simple, focused prompt
  prompt = <<~PROMPT
    Filter these items by relevance to the job description.
    Keep approximately 70% of the most relevant items.

    Job Description:
    #{@job_context[:job_description]}

    Items (JSON):
    #{items.to_json}

    Return ONLY a JSON array of indices to keep (e.g., [0, 2, 3]).
    No explanations, just the JSON array.
  PROMPT

  response = @ai_client.generate_text(prompt)
  indices = JSON.parse(response)
  filtered = indices.map { |i| items[i] }

  set_field(data, field_path, filtered)
end
```

**Step 4: Add require statement at top of file**

```ruby
require "json"
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: implement filter_field transformation"
```

---

## Phase 5: Reorder Transformation

### Task 5.1: Implement reorder_field with permission enforcement

**Files:**
- Modify: `lib/jojo/resume_transformer.rb`
- Modify: `test/unit/resume_transformer_test.rb`

**Step 1: Add require for errors**

Add to top of `lib/jojo/resume_transformer.rb`:

```ruby
require_relative "errors"
```

**Step 2: Write failing tests**

Add to test file:

```ruby
describe "#reorder_field" do
  it "reorders array items using AI" do
    data = { "skills" => ["Ruby", "Python", "Java"] }

    # Mock AI to return reordered indices [2, 0, 1]
    @ai_client.expect(:generate_text, "[2, 0, 1]", [String])

    @transformer.send(:reorder_field, "skills", data, can_remove: true)

    _(data["skills"]).must_equal ["Java", "Ruby", "Python"]
    @ai_client.verify
  end

  it "raises error when LLM removes items from reorder-only field" do
    data = { "experience" => ["exp1", "exp2", "exp3"] }

    # Mock AI returns only 2 indices (violating reorder-only)
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    error = assert_raises(Jojo::PermissionViolation) do
      @transformer.send(:reorder_field, "experience", data, can_remove: false)
    end

    _(error.message).must_include "removed items"
    _(error.message).must_include "experience"
  end

  it "raises error when LLM returns invalid indices" do
    data = { "experience" => ["exp1", "exp2", "exp3"] }

    # Mock AI returns invalid indices
    @ai_client.expect(:generate_text, "[5, 1, 2]", [String])

    error = assert_raises(Jojo::PermissionViolation) do
      @transformer.send(:reorder_field, "experience", data, can_remove: false)
    end

    _(error.message).must_include "invalid indices"
  end

  it "allows removal when can_remove is true" do
    data = { "skills" => ["Ruby", "Python", "Java"] }

    # Returns only 2 items - should be allowed
    @ai_client.expect(:generate_text, "[0, 2]", [String])

    @transformer.send(:reorder_field, "skills", data, can_remove: true)

    _(data["skills"]).must_equal ["Ruby", "Java"]
    @ai_client.verify
  end
end
```

**Step 3: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL

**Step 4: Implement reorder_field**

Add to private section:

```ruby
def reorder_field(field_path, data, can_remove:)
  items = get_field(data, field_path)
  return unless items.is_a?(Array)

  original_count = items.length

  # Simple, focused prompt
  prompt = <<~PROMPT
    Reorder these items by relevance to the job description.
    Most relevant should be first.

    Job Description:
    #{@job_context[:job_description]}

    Items (JSON):
    #{items.to_json}

    Return ONLY a JSON array of indices in new order (e.g., [2, 0, 1]).
    #{can_remove ? "" : "CRITICAL: Return ALL #{items.length} indices."}
    No explanations, just the JSON array.
  PROMPT

  response = @ai_client.generate_text(prompt)
  indices = JSON.parse(response)

  # Ruby enforces the permission
  unless can_remove
    if indices.length != original_count
      raise PermissionViolation,
        "LLM removed items from reorder-only field: #{field_path}"
    end

    if indices.sort != (0...original_count).to_a
      raise PermissionViolation,
        "LLM returned invalid indices for field: #{field_path}"
    end
  end

  reordered = indices.map { |i| items[i] }
  set_field(data, field_path, reordered)
end
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: implement reorder_field with Ruby permission enforcement"
```

---

## Phase 6: Rewrite Transformation

### Task 6.1: Implement rewrite_field

**Files:**
- Modify: `lib/jojo/resume_transformer.rb`
- Modify: `test/unit/resume_transformer_test.rb`

**Step 1: Write failing test**

Add to test file:

```ruby
describe "#rewrite_field" do
  it "rewrites text field using AI" do
    data = { "summary" => "Generic software engineer with broad experience" }

    tailored = "Ruby specialist with 10+ years of backend development"
    @ai_client.expect(:generate_text, tailored, [String])

    @transformer.send(:rewrite_field, "summary", data)

    _(data["summary"]).must_equal tailored
    @ai_client.verify
  end

  it "does nothing for non-string fields" do
    data = { "skills" => ["Ruby", "Python"] }

    @transformer.send(:rewrite_field, "skills", data)

    _(data["skills"]).must_equal ["Ruby", "Python"]
  end

  it "does nothing for missing fields" do
    data = { "summary" => "text" }

    @transformer.send(:rewrite_field, "nonexistent", data)

    _(data["summary"]).must_equal "text"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL

**Step 3: Implement rewrite_field**

Add to private section:

```ruby
def rewrite_field(field_path, data)
  original = get_field(data, field_path)
  return unless original.is_a?(String)

  # Simple, focused prompt
  prompt = <<~PROMPT
    Tailor this content for the specific job opportunity.
    Use the original as factual baseline - no new claims.

    Job Description:
    #{@job_context[:job_description]}

    Original Content:
    #{original}

    Return only the tailored content, no explanations.
  PROMPT

  tailored = @ai_client.generate_text(prompt)
  set_field(data, field_path, tailored)
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: implement rewrite_field transformation"
```

---

## Phase 7: Transform Pipeline

### Task 7.1: Implement main transform method

**Files:**
- Modify: `lib/jojo/resume_transformer.rb`
- Modify: `test/unit/resume_transformer_test.rb`

**Step 1: Write failing integration test**

Add to test file:

```ruby
describe "#transform" do
  before do
    @full_config = {
      "resume_data" => {
        "permissions" => {
          "skills" => ["remove", "reorder"],
          "experience" => ["reorder"],
          "summary" => ["rewrite"]
        }
      }
    }
    @full_transformer = Jojo::ResumeTransformer.new(
      ai_client: @ai_client,
      config: @full_config,
      job_context: @job_context
    )
  end

  it "applies all transformations based on permissions" do
    data = {
      "skills" => ["Ruby", "Python", "Java", "C++"],
      "experience" => ["exp1", "exp2", "exp3"],
      "summary" => "Generic summary"
    }

    # Mock filter call for skills (remove + reorder)
    @ai_client.expect(:generate_text, "[0, 1, 2]", [String])
    # Mock reorder call for filtered skills
    @ai_client.expect(:generate_text, "[2, 0, 1]", [String])
    # Mock reorder call for experience (reorder only)
    @ai_client.expect(:generate_text, "[2, 1, 0]", [String])
    # Mock rewrite call for summary
    @ai_client.expect(:generate_text, "Tailored summary", [String])

    result = @full_transformer.transform(data)

    # Skills filtered and reordered
    _(result["skills"].length).must_equal 3
    # Experience reordered (all 3 preserved)
    _(result["experience"]).must_equal ["exp3", "exp2", "exp1"]
    # Summary rewritten
    _(result["summary"]).must_equal "Tailored summary"

    @ai_client.verify
  end

  it "skips fields without permissions" do
    data = {
      "skills" => ["Ruby"],
      "name" => "Jane Doe",
      "email" => "jane@example.com"
    }

    # Only skills has permissions
    @ai_client.expect(:generate_text, "[0]", [String])
    @ai_client.expect(:generate_text, "[0]", [String])

    result = @full_transformer.transform(data)

    # Read-only fields preserved exactly
    _(result["name"]).must_equal "Jane Doe"
    _(result["email"]).must_equal "jane@example.com"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: FAIL

**Step 3: Implement transform method**

Replace the stub `transform` method:

```ruby
def transform(data)
  permissions = @config.dig("resume_data", "permissions") || {}

  permissions.each do |field_path, perms|
    next unless perms.is_a?(Array)

    # Apply transformations in order
    if perms.include?("remove")
      filter_field(field_path, data)
    end

    if perms.include?("reorder")
      reorder_field(field_path, data, can_remove: perms.include?("remove"))
    end

    if perms.include?("rewrite")
      rewrite_field(field_path, data)
    end
  end

  data
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_transformer.rb test/unit/resume_transformer_test.rb
git commit -m "feat: implement main transform pipeline"
```

---

## Phase 8: ERB Template Support

### Task 8.1: Create ERB template

**Files:**
- Create: `test/fixtures/templates/resume_template.md.erb`

**Step 1: Create template file**

```erb
# <%= name %>

**Email:** <%= email %> | **Phone:** <%= phone %> | **Location:** <%= location %>

## Professional Summary

<%= summary %>

## Skills

<%= skills.join(" • ") %>

## Experience

<% experience.each do |exp| %>
### <%= exp["title"] %> at <%= exp["company"] %>
*<%= exp["start_date"] %> - <%= exp["end_date"] %>*

<%= exp["description"] %>

**Technologies:** <%= exp["technologies"].join(", ") %>
<% end %>

## Education

<% education.each do |edu| %>
### <%= edu["degree"] %> - <%= edu["institution"] %> (<%= edu["year"] %>)
<%= edu["description"] if edu["description"] %>
<% end %>

## Projects

<% projects.each do |proj| %>
- **<%= proj["name"] %>**: <%= proj["description"] %> (Skills: <%= proj["skills"].join(", ") %>)
<% end %>

<% if endorsements && !endorsements.empty? %>
## Endorsements

<% endorsements.each do |endorsement| %>
> <%= endorsement %>
<% end %>
<% end %>
```

**Step 2: Commit**

```bash
git add test/fixtures/templates/resume_template.md.erb
git commit -m "feat: add ERB resume template"
```

---

### Task 8.2: Create ErbRenderer class

**Files:**
- Create: `lib/jojo/erb_renderer.rb`
- Create: `test/unit/erb_renderer_test.rb`

**Step 1: Write failing test**

```ruby
# test/unit/erb_renderer_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/erb_renderer"

describe Jojo::ErbRenderer do
  it "renders ERB template with data" do
    template_path = "test/fixtures/templates/resume_template.md.erb"
    data = {
      "name" => "Jane Doe",
      "email" => "jane@example.com",
      "phone" => "+1-555-0123",
      "location" => "SF, CA",
      "summary" => "Experienced engineer",
      "skills" => ["Ruby", "Python"],
      "experience" => [
        {
          "title" => "Senior Dev",
          "company" => "TechCo",
          "start_date" => "2020-01",
          "end_date" => "present",
          "description" => "Built things",
          "technologies" => ["Ruby", "Rails"]
        }
      ],
      "education" => [
        {
          "degree" => "BS CS",
          "institution" => "State U",
          "year" => "2015"
        }
      ],
      "projects" => [
        {
          "name" => "CLI Tool",
          "description" => "Command line tool",
          "skills" => ["Ruby"]
        }
      ],
      "endorsements" => ["Great engineer"]
    }

    renderer = Jojo::ErbRenderer.new(template_path)
    result = renderer.render(data)

    _(result).must_include "# Jane Doe"
    _(result).must_include "jane@example.com"
    _(result).must_include "Experienced engineer"
    _(result).must_include "Ruby • Python"
    _(result).must_include "### Senior Dev at TechCo"
    _(result).must_include "> Great engineer"
  end

  it "handles missing optional fields" do
    template_path = "test/fixtures/templates/resume_template.md.erb"
    data = {
      "name" => "John Doe",
      "email" => "john@example.com",
      "phone" => "555-0100",
      "location" => "NYC",
      "summary" => "Engineer",
      "skills" => ["Python"],
      "experience" => [],
      "education" => [],
      "projects" => []
    }

    renderer = Jojo::ErbRenderer.new(template_path)
    result = renderer.render(data)

    _(result).must_include "# John Doe"
    _(result).wont_include "## Endorsements"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/erb_renderer_test.rb`
Expected: FAIL

**Step 3: Implement ErbRenderer**

```ruby
# lib/jojo/erb_renderer.rb
require "erb"

module Jojo
  class ErbRenderer
    def initialize(template_path)
      @template_path = template_path
    end

    def render(data)
      template_content = File.read(@template_path)
      erb = ERB.new(template_content, trim_mode: "-")

      # Create a binding with data as local variables
      binding_obj = create_binding(data)
      erb.result(binding_obj)
    end

    private

    def create_binding(data)
      # Create a clean binding with data fields as local variables
      data.each do |key, value|
        instance_variable_set("@#{key}", value)
      end

      # Define methods to access instance variables in ERB
      data.keys.each do |key|
        define_singleton_method(key) do
          instance_variable_get("@#{key}")
        end
      end

      binding
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/erb_renderer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/erb_renderer.rb test/unit/erb_renderer_test.rb
git commit -m "feat: implement ERB template renderer"
```

---

## Phase 9: Resume Data Loader

### Task 9.1: Create ResumeDataLoader with validation

**Files:**
- Create: `lib/jojo/resume_data_loader.rb`
- Create: `test/unit/resume_data_loader_test.rb`

**Step 1: Write failing tests**

```ruby
# test/unit/resume_data_loader_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_loader"

describe Jojo::ResumeDataLoader do
  it "loads valid resume data" do
    loader = Jojo::ResumeDataLoader.new("test/fixtures/resume_data.yml")
    data = loader.load

    _(data["name"]).must_equal "Jane Doe"
    _(data["skills"]).must_be_kind_of Array
    _(data["experience"]).must_be_kind_of Array
  end

  it "raises error for missing file" do
    loader = Jojo::ResumeDataLoader.new("nonexistent.yml")

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      loader.load
    end

    _(error.message).must_include "not found"
  end

  it "validates required fields" do
    # Create invalid fixture
    invalid_path = "test/fixtures/invalid_resume_data.yml"
    File.write(invalid_path, "skills: [Ruby]")

    loader = Jojo::ResumeDataLoader.new(invalid_path)

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    _(error.message).must_include "name"

    FileUtils.rm_f(invalid_path)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_data_loader_test.rb`
Expected: FAIL

**Step 3: Implement ResumeDataLoader**

```ruby
# lib/jojo/resume_data_loader.rb
require "yaml"

module Jojo
  class ResumeDataLoader
    class LoadError < StandardError; end
    class ValidationError < StandardError; end

    REQUIRED_FIELDS = %w[name email summary skills experience].freeze

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      raise LoadError, "Resume data file not found: #{@file_path}" unless File.exist?(@file_path)

      data = YAML.load_file(@file_path)
      validate!(data)
      data
    rescue Psych::SyntaxError => e
      raise LoadError, "Invalid YAML syntax: #{e.message}"
    end

    private

    def validate!(data)
      missing_fields = REQUIRED_FIELDS - data.keys

      unless missing_fields.empty?
        raise ValidationError, "Missing required fields: #{missing_fields.join(', ')}"
      end

      # Validate field types
      raise ValidationError, "skills must be an array" unless data["skills"].is_a?(Array)
      raise ValidationError, "experience must be an array" unless data["experience"].is_a?(Array)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_data_loader_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_data_loader.rb test/unit/resume_data_loader_test.rb
git commit -m "feat: implement ResumeDataLoader with validation"
```

---

## Phase 10: Integration - New Resume Generation Pipeline

### Task 10.1: Create ResumeCurationService

**Files:**
- Create: `lib/jojo/resume_curation_service.rb`
- Create: `test/unit/resume_curation_service_test.rb`

**Step 1: Write failing integration test**

```ruby
# test/unit/resume_curation_service_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_curation_service"

describe Jojo::ResumeCurationService do
  before do
    @ai_client = Minitest::Mock.new
    @config = {
      "resume_data" => {
        "permissions" => {
          "skills" => ["remove", "reorder"],
          "summary" => ["rewrite"]
        }
      }
    }
    @job_context = {
      job_description: "Looking for Ruby developer"
    }

    @service = Jojo::ResumeCurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: "test/fixtures/resume_data.yml",
      template_path: "test/fixtures/templates/resume_template.md.erb"
    )
  end

  it "curates resume from data using transformer and template" do
    # Mock transformer calls
    @ai_client.expect(:generate_text, "[0, 1, 2]", [String]) # filter
    @ai_client.expect(:generate_text, "[2, 1, 0]", [String]) # reorder
    @ai_client.expect(:generate_text, "Tailored Ruby developer summary", [String]) # rewrite

    result = @service.generate(@job_context)

    _(result).must_include "# Jane Doe"
    _(result).must_include "Tailored Ruby developer summary"
    _(result).must_include "Skills"

    @ai_client.verify
  end

  it "caches curated data for same job context" do
    cache_file = "test/fixtures/cached_resume_data.yml"
    FileUtils.rm_f(cache_file)

    service_with_cache = Jojo::ResumeCurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: "test/fixtures/resume_data.yml",
      template_path: "test/fixtures/templates/resume_template.md.erb",
      cache_path: cache_file
    )

    # First call - uses AI
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])
    @ai_client.expect(:generate_text, "Summary v1", [String])

    result1 = service_with_cache.generate(@job_context)
    _(result1).must_include "Summary v1"

    # Second call - uses cache (no AI calls)
    result2 = service_with_cache.generate(@job_context)
    _(result2).must_include "Summary v1"

    @ai_client.verify
    FileUtils.rm_f(cache_file)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_curation_service_test.rb`
Expected: FAIL

**Step 3: Implement ResumeCurationService**

```ruby
# lib/jojo/resume_curation_service.rb
require_relative "resume_data_loader"
require_relative "resume_transformer"
require_relative "erb_renderer"
require "yaml"
require "digest"

module Jojo
  class ResumeCurationService
    def initialize(ai_client:, config:, resume_data_path:, template_path:, cache_path: nil)
      @ai_client = ai_client
      @config = config
      @resume_data_path = resume_data_path
      @template_path = template_path
      @cache_path = cache_path
    end

    def generate(job_context)
      # Load base resume data
      loader = ResumeDataLoader.new(@resume_data_path)
      data = loader.load

      # Check cache
      if @cache_path && cache_valid?(job_context)
        data = YAML.load_file(@cache_path)
      else
        # Transform data based on permissions
        transformer = ResumeTransformer.new(
          ai_client: @ai_client,
          config: @config,
          job_context: job_context
        )
        data = transformer.transform(data)

        # Cache transformed data
        save_cache(data, job_context) if @cache_path
      end

      # Render using ERB template
      renderer = ErbRenderer.new(@template_path)
      renderer.render(data)
    end

    private

    def cache_valid?(job_context)
      return false unless File.exist?(@cache_path)

      # Simple cache validation - could be enhanced with timestamp checks
      true
    end

    def save_cache(data, job_context)
      File.write(@cache_path, data.to_yaml)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_curation_service_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_curation_service.rb test/unit/resume_curation_service_test.rb
git commit -m "feat: implement ResumeCurationService integration"
```

---

## Phase 11: Replace ResumeGenerator Implementation

### Task 11.1: Replace ResumeGenerator with new pipeline

**Files:**
- Modify: `lib/jojo/generators/resume_generator.rb`
- Modify: `test/unit/generators/resume_generator_test.rb`

**Step 1: Write test for new implementation**

Replace existing tests in test file:

```ruby
require_relative "../../test_helper"
require_relative "../../../lib/jojo/employer"
require_relative "../../../lib/jojo/generators/resume_generator"

describe Jojo::Generators::ResumeGenerator do
  before do
    @employer = Jojo::Employer.new("acme-corp")
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::ResumeGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures"
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates resume using ResumeCurationService" do
    # Mock config for permissions and base_url
    @config.expect(:dig, {"skills" => ["remove", "reorder"]}, ["resume_data", "permissions"])
    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    # Mock AI calls for transformation
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    result = @generator.generate

    _(result).must_include "# Jane Doe"
    _(result).must_include "Specifically for Acme Corp"
    _(result).must_include "https://example.com/resume/acme-corp"

    @ai_client.verify
  end

  it "saves resume to file" do
    @config.expect(:dig, {"skills" => ["remove", "reorder"]}, ["resume_data", "permissions"])
    @config.expect(:resume_template, nil)
    @config.expect(:base_url, "https://example.com")

    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    @generator.generate

    _(File.exist?(@employer.resume_path)).must_equal true
    content = File.read(@employer.resume_path)
    _(content).must_include "Specifically for Acme Corp"
  end

  it "fails when resume_data.yml is missing" do
    generator_no_data = Jojo::Generators::ResumeGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false,
      inputs_path: "test/fixtures/nonexistent"
    )

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      generator_no_data.generate
    end

    _(error.message).must_include "not found"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb`
Expected: FAIL (old implementation doesn't use ResumeCurationService)

**Step 3: Replace ResumeGenerator implementation**

Modify: `lib/jojo/generators/resume_generator.rb`

Replace entire file:

```ruby
require "yaml"
require_relative "../resume_curation_service"

module Jojo
  module Generators
    class ResumeGenerator
      attr_reader :employer, :ai_client, :config, :verbose, :inputs_path, :overwrite_flag, :cli_instance

      def initialize(employer, ai_client, config:, verbose: false, inputs_path: "inputs", overwrite_flag: nil, cli_instance: nil)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
        @inputs_path = inputs_path
        @overwrite_flag = overwrite_flag
        @cli_instance = cli_instance
      end

      def generate
        log "Generating config-based resume..."

        resume_data_path = File.join(inputs_path, "resume_data.yml")
        template_path = config.resume_template ||
                        File.join(inputs_path, "templates", "default_resume.md.erb")

        cache_path = File.join(employer.base_path, "resume_data_curated.yml")

        job_context = {
          job_description: File.read(employer.job_description_path)
        }

        log "Using transformation pipeline..."
        service = ResumeCurationService.new(
          ai_client: ai_client,
          config: config,
          resume_data_path: resume_data_path,
          template_path: template_path,
          cache_path: cache_path
        )

        resume = service.generate(job_context)
        resume_with_link = add_landing_page_link(resume)

        log "Saving resume to #{employer.resume_path}..."
        save_resume(resume_with_link)

        log "Resume generation complete!"
        resume_with_link
      end

      private

      def add_landing_page_link(resume_content)
        link = "**Specifically for #{employer.company_name}**: #{config.base_url}/resume/#{employer.slug}"
        "#{link}\n\n#{resume_content}"
      end

      def save_resume(content)
        if cli_instance
          cli_instance.with_overwrite_check(employer.resume_path, overwrite_flag) do
            File.write(employer.resume_path, content)
          end
        else
          File.write(employer.resume_path, content)
        end
      end

      def log(message)
        puts "  [ResumeGenerator] #{message}" if verbose
      end
    end
  end
end
```

**Step 4: Update Config class to support resume_template**

Modify: `lib/jojo/config.rb`

Add reader method:

```ruby
def resume_template
  @data["resume_template"]
end
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/resume_generator.rb lib/jojo/config.rb test/unit/generators/resume_generator_test.rb
git commit -m "feat: replace ResumeGenerator with config-based pipeline"
```

---

## Phase 12: Documentation and Validation

### Task 12.1: Update implementation plan status

**Files:**
- Modify: `docs/plans/2026-01-04-config-based-permissions.md`

**Step 1: Add implementation status**

Add at end of design doc:

```markdown
## Implementation Status

**Status:** ✅ COMPLETED (2026-01-04)

**Implemented Components:**
- ✅ ResumeTransformer with Ruby-enforced permissions
- ✅ Focused prompts for filter/reorder/rewrite
- ✅ Config-based permission system
- ✅ ERB template rendering
- ✅ ResumeCurationService integration
- ✅ ResumeGenerator replaced with new pipeline
- ✅ Comprehensive test coverage

**Migration Requirements:**
1. Create `inputs/resume_data.yml` from existing resume content
2. Create `inputs/templates/default_resume.md.erb` template
3. Add `resume_data.permissions` to `config.yml`
4. Test with sample employer
5. Verify cost reduction and reliability

**Validation:**
Run: `ruby -Ilib:test test/unit/resume_transformer_test.rb`
Run: `ruby -Ilib:test test/unit/resume_curation_service_test.rb`
Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb`

All tests passing ✅
```

**Step 2: Commit**

```bash
git add docs/plans/2026-01-04-config-based-permissions.md
git commit -m "docs: mark config-based permissions as implemented"
```

---

### Task 12.2: Run full test suite

**Step 1: Run all tests**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 2: If failures, debug systematically**

Use `superpowers:systematic-debugging` skill if needed.

**Step 3: Commit any fixes**

```bash
git add .
git commit -m "fix: resolve test failures from integration"
```

---

## Phase 13: Example Usage Documentation

### Task 13.1: Create example resume_data.yml

**Files:**
- Create: `docs/examples/resume_data_example.yml`

**Step 1: Create comprehensive example**

Copy from `test/fixtures/resume_data.yml` and enhance with comments:

```yaml
# Example resume_data.yml - Structured resume data
#
# This file contains your base resume data in a structured format.
# The transformer will apply permissions from config.yml to curate
# this data for specific job opportunities.

name: "Your Full Name"
email: "your.email@example.com"
phone: "+1-555-0123"
location: "City, State"

# Professional summary - can be rewritten per job
summary: "Experienced software engineer with X years building..."

# Skills - can be filtered and reordered
skills:
  - Ruby
  - Python
  - JavaScript
  # ... add all your skills

# Languages you speak
languages:
  - English (native)
  - Spanish (professional)

# Database technologies
databases:
  - PostgreSQL
  - MySQL
  - Redis

# Development tools
tools:
  - Docker
  - Git
  - VS Code

# Work experience - can be reordered, descriptions rewritten
experience:
  - company: "Company Name"
    title: "Job Title"
    start_date: "YYYY-MM"
    end_date: "present"  # or "YYYY-MM"
    description: "High-level summary of role and impact"
    technologies:
      - Tech1
      - Tech2
    tags:
      - backend
      - leadership

# Education - descriptions can be rewritten
education:
  - degree: "BS Computer Science"
    institution: "University Name"
    year: "YYYY"
    description: "Relevant coursework or achievements"

# Projects - can be reordered
projects:
  - name: "Project Name"
    description: "What you built and why it matters"
    skills:
      - Ruby
      - PostgreSQL

# Endorsements/recommendations - can be filtered
endorsements:
  - "Quote from colleague or manager"
```

**Step 2: Create example config snippet**

Create: `docs/examples/config_permissions_example.yml`

```yaml
# Example permissions configuration
resume_data:
  permissions:
    # Arrays: can remove irrelevant items, reorder by relevance
    skills: [remove, reorder]
    databases: [remove, reorder]
    tools: [remove, reorder]
    endorsements: [remove]

    # Arrays: reorder only (keep all items)
    experience: [reorder]
    projects: [reorder]
    languages: [reorder]

    # Text fields: can be rewritten for job
    summary: [rewrite]
    experience.description: [rewrite]
    education.description: [rewrite]

    # Fields without permissions are read-only
    # (name, email, phone, dates, etc.)
```

**Step 3: Commit**

```bash
git add docs/examples/
git commit -m "docs: add example resume_data.yml and permissions config"
```

---

## Success Criteria Validation

✅ **Permission enforcement** - Ruby code catches violations (Task 5.1)
✅ **Reliability** - All service tests pass with mocked Haiku (Phases 4-7)
✅ **Cost** - Focused prompts reduce token usage (simpler prompts in filter/reorder/rewrite)
✅ **Testability** - Unit tests for each transformation (Phases 4-7)
✅ **Separation** - Content (YAML) contains zero configuration (Task 1.1)

---

## Next Steps After Implementation

1. **Data Migration**: Create actual `inputs/resume_data.yml` from existing resume content
2. **Template Creation**: Design `inputs/templates/default_resume.md.erb`
3. **Permissions Setup**: Configure `resume_data.permissions` in `config.yml`
4. **Real-World Test**: Generate resume for actual employer
5. **Cost Analysis**: Measure API costs with focused prompts vs. previous implementation
6. **Iteration**: Refine permissions and templates based on results

---

**Implementation Notes:**

- Each task is atomic (2-5 minutes)
- Tests written before implementation (TDD)
- Frequent commits after each passing test
- Ruby enforces permissions, not LLM
- Focused prompts replace complex single prompt
- Direct replacement - no backward compatibility needed
