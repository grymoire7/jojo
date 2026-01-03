# Resume Generation Redesign: Hybrid Curation + Selective Generation

**Date**: 2026-01-03
**Status**: Design Validated - Ready for Implementation Planning

## Problem Statement

The current resume generation approach uses an LLM to directly generate markdown resumes by tailoring a generic resume to job descriptions. Despite extensive anti-fabrication directives, hallucinations and inaccuracies still occur when the LLM attempts to adapt content—particularly in skills and technologies lists.

A pure curation-only approach would eliminate hallucinations but would lose valuable tailoring for inherently contextual content like the professional summary.

## Proposed Solution

**Hybrid approach**: Combine strict curation for high-risk fields with safe generation for low-risk fields:
- **High-risk fields** (skills, technologies, tools): Read-only curation—LLM can only include/exclude, not modify
- **Low-risk fields** (summary): Safe generation—LLM can tailor to specific role
- **Medium-risk fields** (experience descriptions): Can reorder but not substantially rephrase
- ERB template renders everything with consistent structure
- Persisted filtered YAML enables re-generation without additional API costs

## Architecture

### Current Flow
```
generic_resume.md + job_description.md + research.md + projects.yml
    ↓ (LLM generates markdown)
resume.md (hallucinations possible)
```

### New Flow (Two-Pass Hybrid)
```
resume_data.yml + job_description.md + research.md
    ↓ Pass 1: LLM curates (filter/reorder, read-only for high-risk fields)
resume_data_filtered.yml (persisted intermediate)
    ↓ Pass 2: LLM generates summary only (safe field)
resume_data_filtered.yml (updated with tailored summary)
    ↓ (ERB template renders)
resume.md (guaranteed structure, no hallucinations)
```

### Key Insight
The LLM has **different permissions per field**:
- **skills, technologies, tools**: READ_ONLY—can only include/exclude items
- **summary**: REWRITE_ALLOWED—can generate tailored content
- **experience**: REORDER_ONLY—can reorder entries, not modify descriptions
- **projects**: READ_ONLY—can only include/exclude items

This gives targeted tailoring where appropriate while preventing hallucinations in high-risk technical fields.

## Data Structure

### resume_data.yml

Hybrid structure: flat for simple fields, nested for complex sections. Includes permission metadata to control what the LLM can do with each field.

```yaml
# Contact (flat - read-only)
name: "Tracy Atteberry"
email: "tracy@tracyatteberry.com"
phone: "312 399 6978"
website: "https://tracyatteberry.com"
linkedin: "https://linkedin.com/in/tracyatteberry"
github: "https://github.com/grymoire7"

# Summary (flat text - LLM can rewrite this field)
summary:
  content: |
    I'm a polyglot that enjoys solving problems with software. I enjoy
    working, learning, and teaching on a collaborative team. I have a
    passion for creating quality, extensible code...
  permission: rewrite  # LLM can tailor this to the specific role

# Skills (flat arrays - LLM can filter but not modify)
skills:
  - software engineering
  - full stack development
  - AI assisted software development

languages:
  - Ruby
  - Ruby on Rails
  - Java
  - C/C++
  - Javascript
  - Vue
  - Python
  - Bash
  - Perl
  - Go
permission: read_only  # Can only include/exclude

databases:
  - Postgres
  - Redis
  - MySQL
  - Sqlite
permission: read_only

tools:
  - Agile
  - Docker
  - Rspec
  - Git
  - Vim
  - Aider
  - Jira
permission: read_only

# Experience (nested - LLM can reorder but not modify content)
experience:
  - company: "BenchPrep"
    role: "Senior Software Engineer"
    location: "Chicago, IL and remote"
    start_date: "2020-07"
    end_date: "2024-09"
    description: |
      As a full-stack developer at BenchPrep, I helped deliver a
      high-quality SaaS platform...
    technologies:
      - Ruby on Rails
      - Vue
      - Python
      - Docker
      - OpenAI
      - PostgreSQL
      - Redis
      - Rspec
      - Git
    tags:
      - team lead
      - AI
      - full stack
      - CI/CD
permission: reorder_only  # Can reorder entries, not modify descriptions

# Projects (nested - read-only, can only include/exclude)
projects:
  - title: "CloudDeploy"
    description: "Open-source deployment automation tool..."
    url: "https://github.com/yourname/clouddeploy"
    year: 2024
    context: "open source"
    skills:
      - Go
      - Docker
      - Kubernetes
      - DevOps
      - deployment automation
permission: read_only

# Education (nested - read-only)
education:
  - institution: "University of Kansas"
    degree: "MA, Applied Mathematics"
    description: |
      My research involved writing software...
    year: "~1999"
permission: read_only

# Endorsements (nested - read-only)
endorsements:
  - author: "John Gill"
    role: "Senior Engineering Manager, BenchPrep"
    text: |
      Tracy is one of the very best software engineers...
    linkedin: "https://linkedin.com/in/johngill"
permission: read_only
```

**Permission Types:**
- `read_only`: LLM can only include/exclude items, never modify content
- `reorder_only`: LLM can reorder items within section, not modify content
- `rewrite`: LLM can generate new content based on source material

## LLM Processing: Two-Pass Approach

### Pass 1: Curation (Filtering)

**Input:**
- `resume_data.yml` - Full resume data with permission metadata
- `job_description.md` - Target role requirements
- `research.md` - Company culture and keywords (optional but recommended)

**Output:**
- `resume_data_filtered.yml` - Same structure, filtered arrays, items reordered by relevance

**Curation Logic (respects permission metadata):**
- Target ~70% content retention (most relevant items)
- `read_only` fields: Filter items, never modify content
- `reorder_only` fields: Reorder items, never modify content
- `rewrite` fields: Keep original content for now (Pass 2 handles this)
- Reorder items within sections (most relevant first)
- Never add items not in source

**Empty Section Handling:**
- If section has 0 relevant items: `skills: []`
- Template conditionally renders: `<% unless data[:skills].empty? %>`

**Prompt Approach (Pass 1):**
```
You are curating resume data for a specific job opportunity.

Your task: Filter and reorder resume_data.yml to include ~70% most relevant content.

Field Permissions (STRICTLY ENFORCED):
- skills, languages, databases, tools: READ_ONLY - include/exclude only
- experience: REORDER_ONLY - reorder entries, do not modify descriptions
- projects: READ_ONLY - include/exclude only
- education, endorsements: READ_ONLY - include/exclude only
- summary: DO NOT MODIFY in this pass

Rules:
- Respect the permission metadata for each field
- Remove items that don't align with job requirements
- Reorder items by relevance (most relevant first)
- Keep original YAML structure intact
- Never add items not in source
- Output complete filtered YAML
```

### Pass 2: Summary Generation (Safe Field Only)

**Input:**
- `resume_data_filtered.yml` - Curated data from Pass 1
- `job_description.md` - Target role requirements
- `research.md` - Company culture and keywords
- Original `summary.content` from source YAML

**Output:**
- `resume_data_filtered.yml` - Updated with tailored summary

**Generation Logic:**
- Generate tailored professional summary based on job requirements
- Use original summary content as factual baseline
- Can rephrase and emphasize different aspects
- Must remain truthful (no new claims not in original)
- Target 2-3 sentences

**Prompt Approach (Pass 2):**
```
You are writing a professional summary for a specific job opportunity.

Original summary (base factual material):
#{original_summary}

Job description:
#{job_description}

Research insights:
#{research}

Task: Write a 2-3 sentence professional summary that:
1. Is tailored to this specific role
2. Emphasizes relevant experience/skills from the original
3. Uses company-appropriate language from research
4. Remains truthful - no new claims beyond what's in original
5. Is professional and concise

Output ONLY the summary text (no markdown formatting, no preamble).
```

**Result:** `resume_data_filtered.yml` now contains curated data plus a tailored summary, ready for template rendering.

## ERB Template Rendering

### Template Responsibilities
- Receive filtered YAML data with pre-generated summary
- Render to markdown with consistent structure
- Handle conditional sections (skip if empty)
- Support multiple template styles
- No content generation - pure rendering

### Default Template Structure

```erb
---
margin-left: 2cm
# ... pandoc metadata ...
---

###### [<%= data[:website] %>] . [<%= data[:email] %>]

<%= data[:summary][:content] %>
<%# Summary was generated by LLM in Pass 2 %>

<% unless data[:skills].empty? %>
## Skills

<% data[:skills].each do |skill| %>
```<%= skill %>```
<% end %>
<% end %>

<% unless data[:experience].empty? %>
## Experience

<% data[:experience].each do |job| %>
### <%= job[:role] %>, <%= job[:company] %>

<%= job[:start_date].strftime('%B %Y') %> - <%= job[:end_date] ? job[:end_date].strftime('%B %Y') : 'Present' %>

<%= job[:description] %>
<%# Description is rendered as-is from YAML, not rephrased %>

<% unless job[:technologies].empty? %>**Technologies used:** <%= job[:technologies].join(', ') %><% end %>

<% end %>
<% end %>
```

### Template Selection
- Config option: `resume_template: templates/my_template.md.erb`
- CLI override: `./bin/jojo resume --template custom.md.erb`

## File Structure

### New Files
```
inputs/
  resume_data.yml               # NEW: Replaces generic_resume.md

templates/
  default_resume.md.erb         # NEW: Default resume template
  custom_resume.md.erb          # NEW: Example custom template

employers/{slug}/
  resume_data_filtered.yml      # NEW: Persisted LLM curation output
  resume.md                     # OUTPUT: Now template-rendered
```

### Deleted Files
```
inputs/
  generic_resume.md             # REPLACED by resume_data.yml
  projects.yml                  # Merged into resume_data.yml
```

### Modified Components
```
lib/jojo/
  generators/
    resume_generator.rb         # MAJOR: Orchestrates 2-pass LLM + rendering
  prompts/
    resume_curation_prompt.rb   # NEW: Pass 1 - Filtering curation prompt
    resume_summary_prompt.rb    # NEW: Pass 2 - Summary generation prompt
  loaders/
    resume_data_loader.rb       # NEW: Load/validate resume_data.yml
  renderers/
    erb_renderer.rb             # NEW: Render ERB with data
```

### Component Responsibilities

| Component | Current | New |
|-----------|---------|-----|
| `ResumeGenerator` | Single-pass: prompt + AI → markdown | Two-pass: curation + summary + template → markdown |
| `ResumePrompt` | Single tailoring/generation prompt | Split into curation + summary prompts |
| `ResumeDataLoader` | (doesn't exist) | Load/validate `resume_data.yml` with permissions |
| `ErbRenderer` | (doesn't exist) | Render ERB with filtered data |
| `ProjectSelector` | Select from `projects.yml` | LLM handles selection in curation pass |

## Configuration

```yaml
# templates/config.yml.erb
resume_template: <%= resume_template_path %>  # Path to resume template
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Missing `resume_data.yml` | HARD ERROR |
| Missing `resume_data_filtered.yml` | Run curation step |
| Template syntax errors | Catch ERB error, show user-friendly message |
| Validation errors in YAML | Show specific missing/invalid fields |

## Validation

`ResumeDataLoader` validates required fields:
- `name` (required)
- Contact info (at least one: email, phone, website)
- `summary` (required)
- Array fields must be arrays
- Nested items must have required sub-fields

Similar pattern to current `ProjectLoader::ValidationError`.

## Benefits

1. **No hallucinations in high-risk fields**: Skills, technologies, and tools are read-only from YAML
2. **Tailored messaging where it matters**: Professional summary is customized for each role
3. **Regenerable**: Can re-run website/cover letter from cached filtered YAML without API calls
4. **Format control**: Exact markdown structure via ERB
5. **Customizable**: Users can create alternate templates without code changes
6. **Cost efficient**: Generate once (curation + summary), render many times
7. **Best of both worlds**: Targeted tailoring for contextual fields (summary) with strict truthfulness for technical fields (skills)

## Migration Strategy

Since backward compatibility is not required:
1. User creates `resume_data.yml` manually or via migration script
2. Delete `generic_resume.md` and `projects.yml`
3. Update setup command to generate new structure
4. Optional: provide migration script to help convert old data

## Testing Strategy

### Unit Tests
- `ResumeDataLoader`: Validation, required fields, array handling
- `ResumePrompt`: Curation prompt generation
- `ErbRenderer`: Template rendering, conditional sections
- `ResumeGenerator`: Full pipeline orchestration

### Integration Tests
- Full pipeline: YAML → filtered YAML → markdown
- Missing inputs handling
- Template selection via config/CLI

### Test Fixtures
- `test/fixtures/resume_data.yml` - Complete sample data
- `test/fixtures/resume_data_filtered.yml` - Expected curation output
- `test/fixtures/tailored_resume.md` - Expected rendered output

## Success Criteria

- `./bin/jojo resume -e "Acme Corp"` runs two-pass LLM + template rendering
- `resume_data_filtered.yml` persists with curated data and tailored summary
- Skills, technologies, tools in output match source YAML exactly (no additions)
- Professional summary is tailored to the specific role
- Website/cover letter regeneration uses cached filtered YAML (no new API calls)
- Resume has consistent structure regardless of job
- No hallucinated skills or experiences in output
- All tests pass
