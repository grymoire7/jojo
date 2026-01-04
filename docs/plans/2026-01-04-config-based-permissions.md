# Config-Based Permissions for Resume Curation

**Date:** 2026-01-04
**Status:** Design
**Supersedes:** Comment-based permissions from 2026-01-03-resume-curation-redesign.md

## Problem Statement

The current comment-based permission system has critical flaws:

### Issue: LLM Cannot Reliably Follow Permission Rules

When using comment-based permissions in `resume_data.yml`:

```yaml
# permission: reorder
experience:
  - company: "Company A"
  - company: "Company B"
  - company: "Company C"
```

**Expected:** Reorder all 3 entries by relevance
**Actual:** LLM removes entries it deems irrelevant, violating "reorder-only" permission

**Root Cause:** Even with strengthened prompts, the LLM (especially Haiku) prioritizes "be relevant and helpful" over "strictly follow these 8 permission rules." This creates unreliable, unpredictable behavior.

### Architectural Problems

1. **Ambiguous authority** - Who enforces permissions? LLM interpretation vs. code
2. **Complex prompts** - Single prompt must handle all permission combinations
3. **Poor testability** - Can't unit test permission enforcement (it's all in LLM)
4. **Expensive model required** - Need Sonnet to follow complex multi-rule prompts
5. **Content/config mixing** - Permissions are configuration, not content

## Proposed Solution: Config-Based Permissions

### Core Principle

**Separate content from configuration. Let Ruby code enforce permissions, not LLM interpretation.**

### Architecture

```
inputs/resume_data.yml (pure data, no permissions)
    ↓
config.yml (defines what's mutable per field)
    ↓
Ruby transformation pipeline (enforces permissions)
    ↓
Focused LLM calls (simple tasks: filter, reorder, rewrite)
    ↓
employers/<slug>/resume_data_curated.yml (cached)
    ↓
ERB template rendering
    ↓
employers/<slug>/resume.md
```

### Configuration Format

```yaml
# config.yml
resume_data:
  permissions:
    # Top-level fields
    skills: [remove, reorder]
    languages: [reorder]
    databases: [remove, reorder]
    tools: [remove, reorder]
    projects: [reorder]
    experience: [reorder]
    endorsements: [remove]

    # Nested fields (dot notation)
    summary: [rewrite]
    projects.skills: [reorder]
    experience.description: [rewrite]
    experience.technologies: [remove, reorder]
    experience.tags: [remove, reorder]
    education.description: [rewrite]
```

**Default:** Fields not listed are read-only (preserved exactly).

### Permission Types

- **`remove`** - Can filter items from arrays based on relevance
- **`reorder`** - Can reorder array items by relevance (CANNOT remove)
- **`rewrite`** - Can generate tailored content (for scalar/text fields)
- **No permission** (default) - Read-only, preserved exactly

### Transformation Pipeline

```ruby
class ResumeTransformer
  def initialize(ai_client:, config:, job_context:)
    @ai_client = ai_client
    @config = config
    @job_context = job_context
  end

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

  private

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

      Return JSON array of indices to keep (e.g., [0, 2, 3]).
    PROMPT

    indices = JSON.parse(@ai_client.generate_text(prompt))
    filtered = indices.map { |i| items[i] }

    set_field(data, field_path, filtered)
  end

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

      Return JSON array of indices in new order (e.g., [2, 0, 1]).
      #{can_remove ? "" : "CRITICAL: Return ALL #{items.length} indices."}
    PROMPT

    indices = JSON.parse(@ai_client.generate_text(prompt))

    # Ruby enforces the permission
    unless can_remove
      if indices.length != original_count
        raise PermissionViolation, "LLM removed items from reorder-only field: #{field_path}"
      end

      if indices.sort != (0...original_count).to_a
        raise PermissionViolation, "LLM returned invalid indices for field: #{field_path}"
      end
    end

    reordered = indices.map { |i| items[i] }
    set_field(data, field_path, reordered)
  end

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

  # Helper methods for nested field access
  def get_field(data, field_path)
    parts = field_path.split(".")
    parts.reduce(data) { |obj, key| obj&.dig(key) }
  end

  def set_field(data, field_path, value)
    parts = field_path.split(".")
    *path, key = parts

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

## Benefits

### 1. Ruby Enforces Permissions (Not LLM)

```ruby
unless can_remove
  if indices.length != original_count
    raise PermissionViolation, "Cannot remove items"
  end
end
```

**No ambiguity.** Permission violations are caught programmatically.

### 2. Simple, Focused Prompts

Instead of:
> "Curate resume_data.yml by filtering and reordering based on permission metadata in comments with these 8 complex rules..."

We have:
> "Reorder these 5 items by relevance. Return JSON array of indices."

**Haiku can handle this reliably.**

### 3. Cost Efficiency

**Current (Sonnet, single complex call):**
- 1 call × ~3500 tokens × Sonnet pricing = ~$0.03/resume

**Proposed (Haiku, focused calls):**
- 8 calls × ~800 tokens × Haiku pricing = ~$0.013/resume

**2-3x cheaper** and more reliable.

### 4. Better Testability

```ruby
describe ResumeTransformer do
  it "preserves all items when reorder-only permission" do
    data = { "skills" => ["Ruby", "Python", "Java"] }
    permissions = { "skills" => ["reorder"] }

    transformer.transform(data)

    # Ruby code guarantees this
    expect(data["skills"].length).to eq(3)
  end
end
```

**Unit tests for permission enforcement.**

### 5. Parallelization

```ruby
# Independent transformations can run in parallel
futures = [
  async { filter_field("skills", data) },
  async { reorder_field("projects", data) },
  async { reorder_field("experience", data) }
]

futures.map(&:value) # Wait for all
```

**3x faster** for independent transformations.

### 6. Clear Separation of Concerns

- **`inputs/resume_data.yml`** - Pure content, no configuration
- **`config.yml`** - What's mutable, what's not
- **Ruby code** - Enforces rules, orchestrates LLM calls
- **LLM** - Focused tasks (filter, reorder, rewrite)

## Migration from Current Implementation

### What to Keep ✅

- `ErbRenderer` - Template rendering works fine
- `ResumeDataLoader` - YAML validation still needed
- `default_resume.md.erb` - Template is good
- Test infrastructure patterns
- Config setting for `resume_template`

### What to Change ❌

- Remove `ResumeFilterPrompt` (single complex prompt)
- Remove `ResumeCuratePrompt` (replace with focused prompts)
- Remove comment-based permissions from `resume_data.yml`
- Add `resume_data.permissions` to `config.yml`
- Replace `ResumeGenerator` two-pass with single transformation pipeline
- Rewrite service tests to test individual transformations

### Migration Path

1. **Add permissions to `config.yml`** (new format)
2. **Remove permission comments from `resume_data.yml`**
3. **Create `ResumeTransformer`** class
4. **Replace two-pass `ResumeGenerator`** with single-pass
5. **Write focused prompt builders** (filter, reorder, rewrite)
6. **Add Ruby validation** for permission enforcement
7. **Update tests** to validate transformations individually

## Example: Before vs After

### Before (Comment-Based)

**resume_data.yml:**
```yaml
skills: # permission: remove, reorder
  - Ruby
  - Python
  - Java

experience: # permission: reorder
  - company: "Company A"
  - company: "Company B"
```

**Problem:** LLM interprets permissions, removes items from reorder-only fields.

### After (Config-Based)

**resume_data.yml:**
```yaml
skills:
  - Ruby
  - Python
  - Java

experience:
  - company: "Company A"
  - company: "Company B"
```

**config.yml:**
```yaml
resume_data:
  permissions:
    skills: [remove, reorder]
    experience: [reorder]  # Ruby guarantees no removal
```

**Result:** Ruby code enforces that `experience` reordering preserves all items.

## Open Questions

1. **Nested array handling** - How to handle `experience[0].technologies` transformations?
2. **Parallel vs sequential** - Which transformations can run in parallel safely?
3. **Caching strategy** - Cache after each transformation or only final result?
4. **Error recovery** - If one transformation fails, continue or abort?
5. **Prompt templates** - Store focused prompts in separate files or inline?

## Success Criteria

1. **Permission enforcement** - Ruby code catches all permission violations
2. **Reliability** - 100% of service tests pass with Haiku
3. **Cost** - 50%+ reduction in API costs vs. Sonnet single-pass
4. **Testability** - Unit tests for each transformation type
5. **Separation** - Content (YAML) contains zero configuration

## References

- Previous design: `docs/plans/2026-01-03-resume-curation-redesign.md`
- Systematic debugging investigation: Current session
- Cost analysis: This document, Benefits section

---

**Next Steps:**

1. Review and approve this design
2. Create new worktree for clean implementation
3. Write implementation plan based on this design
4. Implement transformation pipeline
5. Migrate resume_data.yml to remove permission comments
