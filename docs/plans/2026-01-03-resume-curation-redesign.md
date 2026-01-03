# Resume Generation Redesign: Curation-Based Approach

**Date**: 2026-01-03
**Status**: Design Validated - Ready for Implementation Planning

## Problem Statement

The current resume generation approach uses an LLM to directly generate markdown resumes by tailoring a generic resume to job descriptions. Despite extensive anti-fabrication directives, hallucinations and inaccuracies still occur when the LLM attempts to adapt content.

## Proposed Solution

Separate **curation** (LLM) from **rendering** (ERB template):
- LLM filters and ranks existing resume data based on job relevance
- ERB template guarantees consistent structure and prevents content invention
- Persisted filtered YAML enables re-generation without additional API costs

## Architecture

### Current Flow
```
generic_resume.md + job_description.md + research.md + projects.yml
    ↓ (LLM generates markdown)
resume.md (hallucinations possible)
```

### New Flow
```
resume_data.yml + job_description.md + research.md
    ↓ (LLM curates: filter to ~70% most relevant)
resume_data_filtered.yml (persisted intermediate)
    ↓ (ERB template renders)
resume.md (guaranteed structure, no hallucinations)
```

### Key Insight
The LLM's role changes from **generating prose** to **selecting content**. The template controls formatting and prevents invention of new skills, technologies, or experiences.

## Data Structure

### resume_data.yml

Hybrid structure: flat for simple fields, nested for complex sections.

```yaml
# Contact (flat)
name: "Tracy Atteberry"
email: "tracy@tracyatteberry.com"
phone: "312 399 6978"
website: "https://tracyatteberry.com"
linkedin: "https://linkedin.com/in/tracyatteberry"
github: "https://github.com/grymoire7"

# Summary (flat text)
summary: |
  I'm a polyglot that enjoys solving problems with software...

# Skills (flat arrays - LLM filters which to include)
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

databases:
  - Postgres
  - Redis
  - MySQL
  - Sqlite

tools:
  - Agile
  - Docker
  - Rspec
  - Git
  - Vim
  - Aider
  - Jira

# Experience (nested - each job has multiple fields)
experience:
  - company: "BenchPrep"
    role: "Senior Software Engineer"
    location: "Chicago, IL and remote"
    start_date: "2020-07"
    end_date: "2024-09"
    description: |
      As a full-stack developer at BenchPrep...
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

# Projects (nested - similar to current projects.yml)
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

# Education (nested)
education:
  - institution: "University of Kansas"
    degree: "MA, Applied Mathematics"
    description: |
      My research involved writing software...
    year: "~1999"

# Endorsements (nested)
endorsements:
  - author: "John Gill"
    role: "Senior Engineering Manager, BenchPrep"
    text: |
      Tracy is one of the very best software engineers...
    linkedin: "https://linkedin.com/in/johngill"
```

## LLM Curation Step

### Input
- `resume_data.yml` - Full resume data
- `job_description.md` - Target role requirements
- `research.md` - Company culture and keywords (optional but recommended)

### Output
- `resume_data_filtered.yml` - Same structure, filtered arrays, items reordered by relevance

### Curation Logic
- Target ~70% content retention (most relevant items)
- Remove least relevant skills, projects, experience details
- Reorder items within sections (most relevant first)
- Never add items not in source
- Never modify item content (only filter/reorder)

### Empty Section Handling
- If section has 0 relevant items: `skills: []`
- Template conditionally renders: `<% unless data[:skills].empty? %>`

### Prompt Approach
```
You are curating resume data for a specific job opportunity.

Your task: Filter resume_data.yml to include ~70% most relevant content.

Rules:
- Remove items that don't align with job requirements
- Reorder items by relevance (most relevant first)
- Keep original YAML structure intact
- Never add items not in source
- Never modify item content
- Output complete filtered YAML
```

## ERB Template Rendering

### Template Responsibilities
- Receive filtered YAML data
- Render to markdown with consistent structure
- Handle conditional sections (skip if empty)
- Support multiple template styles

### Default Template Structure

```erb
---
margin-left: 2cm
# ... pandoc metadata ...
---

###### [<%= data[:website] %>] . [<%= data[:email] %>]

<%= data[:summary] %>

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
    resume_generator.rb         # MAJOR: Orchestrates curation + rendering
  prompts/
    resume_prompt.rb            # MAJOR: Curation prompt, not generation
  loaders/
    resume_data_loader.rb       # NEW: Load/validate resume_data.yml
  renderers/
    erb_renderer.rb             # NEW: Render ERB with data
```

### Component Responsibilities

| Component | Current | New |
|-----------|---------|-----|
| `ResumeGenerator` | Prompt + AI → markdown | Curation → template → markdown |
| `ResumePrompt` | Tailoring/generation prompt | Curation filtering prompt |
| `ResumeDataLoader` | (doesn't exist) | Load/validate `resume_data.yml` |
| `ErbRenderer` | (doesn't exist) | Render ERB with filtered data |
| `ProjectSelector` | Select from `projects.yml` | LLM handles in curation |

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

1. **No hallucinations**: Template only renders data that exists in YAML
2. **Regenerable**: Can re-run website/cover letter from cached filtered YAML without API calls
3. **Format control**: Exact markdown structure via ERB
4. **Customizable**: Users can create alternate templates without code changes
5. **Cost efficient**: Generate once, render many times

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

- `./bin/jojo resume -e "Acme Corp"` generates `resume.md` via template
- Generated `resume_data_filtered.yml` persists for reuse
- Website/cover letter regeneration uses cached filtered YAML
- Resume has consistent structure regardless of job
- No hallucinated skills or experiences in output
- All tests pass
