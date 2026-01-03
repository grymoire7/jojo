# Resume Generation Redesign: Hybrid Curation + Selective Generation

**Date**: 2026-01-03
**Status**: Design Validated - Ready for Implementation Planning

## Problem Statement

The current resume generation approach uses an LLM to directly generate
markdown resumes by tailoring a generic resume to job descriptions. Despite
extensive anti-fabrication directives, hallucinations and inaccuracies still
occur when the LLM attempts to adapt content—particularly in skills and
technologies lists.

A pure curation-only approach would eliminate hallucinations but would lose
valuable tailoring for inherently contextual content like the professional
summary.

## Proposed Solution

**Hybrid approach**: Combine strict curation for high-risk fields with safe generation for lower-risk fields.
Risk is user-defined based on likelihood of hallucination and impact of inaccuracies. Risk is mitigated
per field in the resume data structure by permission metadata.

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
resume_data_curated.yml (updated with tailored summary)
    ↓ (ERB template renders)
resume.md (guaranteed structure, no hallucinations)
```

### Key Insight
The LLM has **different permissions per field**:

- `read-only`: LLM cannot modify, delete, add, or reorder items (default)
- `remove`: LLM can include/exclude items (no modifications or reordering)
- `reorder`: LLM can reorder items within section, most relevant first (no modifications or deletions)
  - reorder LLM can only be applied to sections with multiple entries (eg. skills, projects)
- `rewrite`: LLM can generate new content based on source material (eg. summary)

*Never* add items not in source.

If a field has no permission metadata, it defaults to `read-only` and must be preserved as-is.
This gives targeted tailoring where appropriate while preventing hallucinations in high-risk technical fields.

## Data Structure

### resume_data.yml

Hybrid structure: flat for simple fields, nested for complex sections. Includes
permission metadata in item comment to control what the LLM can do with each field.

```yaml
# Contact (default permission - read-only)
name: "Tracy Atteberry"
email: "tracy@tracyatteberry.com"
phone: "312l399 6978"
website: "https://tracyatteberry.com"
linkedin: "https://linkedin.com/in/tracyatteberry"
github: "https://github.com/grymoire7"

summary: | # permission: rewrite
  I'm a polyglot that enjoys solving problems with software. I enjoy
  working, learning, and teaching on a collaborative team. I have a
  passion for creating quality, extensible code...

skills: # permission: remove, reorder
  - software engineering
  - full stack development
  - AI assisted software development

languages: # permission: reorder
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

databases: # permission: remove, reorder
  - Postgres
  - Redis
  - MySQL
  - Sqlite

tools: # permission: remove, reorder
  - Agile
  - Docker
  - Rspec
  - Git
  - Vim
  - Aider
  - Jira

experience:  # permission: reorder
  - company: "BenchPrep"
    role: "Senior Software Engineer"
    location: "Chicago, IL and remote"
    start_date: "2020-07"
    end_date: "2024-09"
    description: | # permission: rewrite
      As a full-stack developer at BenchPrep, I helped deliver a
      high-quality SaaS platform...
    technologies: # permission: remove, reorder
      - Ruby on Rails
      - Vue
      - Python
      - Docker
      - OpenAI
      - PostgreSQL
      - Redis
      - Rspec
      - Git
    tags: # permission: remove, reorder
      - team lead
      - AI
      - full stack
      - CI/CD

projects:  # permission: reaorder
  - title: "CloudDeploy"
    description: "Open-source deployment automation tool..."
    url: "https://github.com/yourname/clouddeploy"
    year: 2024
    context: "open source"
    skills: # permission: reorder
      - Go
      - Docker
      - Kubernetes
      - DevOps
      - deployment automation

education:
  - institution: "University of Kansas"
    degree: "MA, Applied Mathematics"
    description: | # permission: rewrite
      My research involved writing software...
    year: "~1999"

endorsements: # permission: remove
  - author: "John Gill"
    role: "Senior Engineering Manager, BenchPrep"
    text: | # permission: read-only
      Tracy is one of the very best software engineers...
    linkedin: "https://linkedin.com/in/johngill"
```

**Permission Types:**
- `read-only`: LLM cannot modify, delete, add, or reorder items (default)
- `remove`: LLM can include/exclude items (no modifications or reordering)
- `reorder`: LLM can reorder items within section, most relevant first (no modifications or deletions)
  - reorder LLM can only be applied to sections with multiple entries (eg. skills, projects)
- `rewrite`: LLM can generate new content based on source material (eg. summary)

*Never* add items not in source.

If a field has no permission metadata, it defaults to `read-only` and must be preserved as-is.
This gives targeted tailoring where appropriate while preventing hallucinations in high-risk technical fields.


## LLM Processing: Two-Pass Approach

### Pass 1: Curation (Filtering)

**Input:**
- `resume_data.yml` - Full resume data with permission metadata
- `job_description.md` - Target role requirements
- `research.md` - Company culture and keywords (optional but recommended)

**Output:**
- `resume_data_filtered.yml` - Same structure, filtered arrays, items reordered by relevance

**Curation Logic (respects permission metadata):**
- Target ~70% content retention (most relevant items) -- configurable in `config.yml`
- see permssion types above

**Empty Section Handling:**
- If section has 0 relevant items: `skills: []`
- Template conditionally renders: `<% unless data[:skills].empty? %>`

**Prompt Approach (Pass 1):**
```
You are curating resume data for a specific job opportunity.

Your task: Filter and reorder resume_data.yml to include ~70% most relevant content.

Field Permissions (STRICTLY ENFORCED):
- you can only remove items from sections with the "remove" permission (examples: "# permission: remove", "# permission: remove, reorder")
- you can only reorder items from sections with the "reorder" permission (examples: "# permission: reorder", "# permission: remove, reorder")
- DO NOT MODIFY any content in this pass

Rules:
- Respect the permission metadata for each field
- Remove items that don't align with job requirements
- Reorder items by relevance (most relevant first)
- Keep original YAML structure intact
- Never add items not in source
- Never modify item content
- Output complete filtered YAML
```

### Pass 2: Summary Generation (Safe Field Only)

**Input:**
- `resume_data_filtered.yml` - Curated data from Pass 1
- `job_description.md` - Target role requirements
- `research.md` - Company culture and keywords

**Output:**
- `resume_data_curated.yml` - Updated with tailored summary

**Generation Logic:**
- Generate tailored content based on job requirements for fields with `rewrite` permission only
- Use original content as factual baseline
- Can rephrase and emphasize different aspects
- Must remain truthful (no new claims not in original)

**Prompt Approach (Pass 2):**

[ TODO: create detailed prompt in implementation document ]

**Result:** `resume_data_curated.yml` now contains curated data plus tailored fields with `rewrite` permission, ready for template rendering.

## ERB Template Rendering

### Template Responsibilities
- Receive filtered YAML data with pre-generated summary
- Render to markdown with consistent structure
- Handle conditional sections (skip if empty)
- Support choice of template file via config/CLI
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
  resume_data_filtered.yml      # NEW: Persisted LLM curation output from pass 1
  resume_data_curated.yml       # NEW: Persisted LLM curation output from pass 2
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
    resume_filter_prompt.rb     # NEW: Pass 1 - Filtering curation prompt (no rewrites)
    resume_curate_prompt.rb     # NEW: Pass 2 - Tailor fields with rewrite permission
  loaders/
    resume_data_loader.rb       # NEW: Load/validate resume_data.yml
  renderers/
    erb_renderer.rb             # NEW: Render ERB with data
```

### Component Responsibilities

| Component | Current | New |
|-----------|---------|-----|
| `ResumeGenerator` | Single-pass: prompt + AI → markdown | Two-pass: filter + rewrite + template → markdown |
| `ResumePrompt` | Single tailoring/generation prompt | Split into filter + rewrite/curate prompts |
| `ResumeDataLoader` | (doesn't exist) | Load/validate `resume_data.yml` with permissions |
| `ErbRenderer` | (doesn't exist) | Render ERB with filtered data |
| `ProjectSelector` | Select from `projects.yml` | LLM handles selection in curation pass |

## Configuration

```yaml
# templates/config.yml.erb
resume_template: <%= resume_template_path %>  # Path to resume template
```

## Error Handling

| Scenario                          | Behavior                                    |
| --------------------------------- | ------------------------------------------- |
| Missing `resume_data.yml`         | HARD ERROR                                  |
| Missing `resume_data_curated.yml` | Run curation step                           |
| Template syntax errors            | Catch ERB error, show user-friendly message |
| Validation errors in YAML         | Show specific missing/invalid fields        |

## Validation

`ResumeDataLoader` validates required fields:
- `name` (required)
- Contact info (at least one: email, phone, website)
- `summary` (required)
- Array fields must be arrays
- Nested items must have required sub-fields

Similar pattern to current `ProjectLoader::ValidationError`.
Note: This is not a full schema validation - only key fields are checked.

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
2. Files `generic_resume.md` and `projects.yml` are deprecated
3. Provide example `resume_data.yml` in templates/
4. Update setup command to generate new structure

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
- `test/fixtures/resume_data_filtered.yml` - Expected filter (pass 1) output
- `test/fixtures/resume_data_curated.yml` - Expected curation (pass 2) output
- `test/fixtures/tailored_resume.md` - Expected rendered output

## Success Criteria

- `./bin/jojo resume -e "Acme Corp"` runs two-pass LLM + template rendering
- `resume_data_curated.yml` persists with curated data and tailored summary
- `read-only` fields in output match source YAML exactly (no modifications)
- `rewrite` fields are tailored to the specific role
- `reorder` fields are reordered by relevance but contain same items
- `remove` fields contain a subset of original items only
- Website/cover letter regeneration uses cached filtered YAML (no new API calls)
- Resume has consistent structure regardless of job
- No hallucinated skills or experiences in output
- All tests pass
