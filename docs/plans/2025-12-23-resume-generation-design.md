# Resume Generation Design (Phase 4)

**Date**: 2025-12-23
**Status**: Validated - Ready for Implementation

## Overview

Generate tailored resumes from generic resumes using conservative tailoring with strategic pruning. The approach maintains truthfulness and structure while filtering irrelevant content and optimizing for specific job requirements.

## Tailoring Philosophy

**Conservative Tailoring with Strategic Pruning:**
- Keep all original work experience and education intact
- Only modify: professional summary, skill emphasis/ordering, and bullet point phrasing
- Strategically prune: Remove skills/projects/bullets that don't align with the role (keep 60-80% most relevant)
- Ensure all achievements remain truthful, just reworded to match job description keywords
- Maintain original resume structure and section headings

## Architecture & Components

### ResumeGenerator Class

Following the ResearchGenerator pattern:

- **Initialization**: `employer`, `ai_client`, `config`, `verbose` flag
- **Input Sources**:
  - `inputs/generic_resume.md` - source material (REQUIRED)
  - `employers/{slug}/job_description.md` - target role (REQUIRED)
  - `employers/{slug}/research.md` - strategic context (REQUIRED)
  - `employers/{slug}/job_details.yml` - structured role data (OPTIONAL)
- **Output**: `employers/{slug}/resume.md`
- **AI Model**: Uses `text_generation_ai` (Haiku for cost efficiency)

### ResumePrompt Module

Template-based prompt generation following ResearchPrompt pattern:

- Instructions for conservative tailoring with strategic pruning
- Emphasizes: maintain truthfulness, filter irrelevant content, optimize keywords
- Output specification: markdown format matching generic resume structure

### Key Dependencies

- Generic resume must exist (hard requirement)
- Research should exist (soft requirement with warning)
- Job description must exist (from Phase 2)
- Job details optional (from Phase 2)

### Landing Page Link

Add deterministic URL at top of resume:
```markdown
**Specifically for Acme Corp**: https://tracyatteberry.com/resume/acme-corp
```

- URL structure: `{base_url}/resume/{company_slug}`
- No placeholder needed - website will be generated to match this URL in Phase 6
- `base_url` comes from config.yml

## Prompt Engineering Strategy

### Prompt Structure

**1. Context Section** - Provide all inputs:
- Job description (what they're looking for)
- Research insights (company culture, keywords, positioning)
- Generic resume (source material to tailor)
- Job details YAML if available (structured requirements)

**2. Instructions Section** - Clear tailoring rules:
- **Preserve**: All dates, job titles, company names, degrees, certifications
- **Prune**: Skills/projects/bullets that don't align with role (keep only relevant 60-80%)
- **Optimize**: Reword bullets to include keywords from job description
- **Reorder**: Within sections, put most relevant items first
- **Professional Summary**: Rewrite completely to target this specific role

**3. Output Format Specification**:
- Mirror the structure of the generic resume (same section headings)
- Markdown format with consistent formatting
- Include landing page link at top
- Clean, ATS-friendly formatting (no tables, simple bullets)

**4. Quality Guidelines**:
- Every bullet point must be truthful (no fabrication)
- Use action verbs and quantifiable results from original
- Match voice/tone from config (e.g., "professional and friendly")
- Target 1-2 pages worth of content

## Implementation Flow

```ruby
def generate
  log "Gathering inputs for resume generation..."
  inputs = gather_inputs  # job_description, research, generic_resume, job_details

  log "Building resume prompt..."
  prompt = build_resume_prompt(inputs)

  log "Generating tailored resume using AI..."
  resume = call_ai(prompt)

  log "Adding landing page link..."
  resume_with_link = add_landing_page_link(resume, inputs)

  log "Saving resume to #{employer.resume_path}..."
  save_resume(resume_with_link)

  log "Resume generation complete!"
  resume_with_link
end
```

### Landing Page Link Generation

```ruby
def add_landing_page_link(resume_content, company_name, company_slug, base_url)
  link = "**Specifically for #{company_name}**: #{base_url}/resume/#{company_slug}"
  "#{link}\n\n#{resume_content}"
end
```

## Error Handling & Graceful Degradation

- **Missing `inputs/generic_resume.md`**: HARD FAILURE - cannot generate without source material
- **Missing `research.md`**: SOFT WARNING - continue with just job description
- **Missing `job_details.yml`**: SOFT WARNING - use job description text only
- **AI API errors**: Raise with helpful message, don't retry (let user fix API key/quota)

## Configuration Updates

### templates/config.yml.erb

Add `base_url` as required field:

```yaml
seeker_name: <%= seeker_name %>
base_url: <%= base_url %>  # e.g., https://tracyatteberry.com
reasoning_ai:
  service: anthropic
  model: sonnet
text_generation_ai:
  service: anthropic
  model: haiku
voice_and_tone: professional and friendly
```

### Setup Command Updates

Update setup command to prompt for `base_url` during initial configuration.

## CLI Integration

### Standalone Command

```bash
./bin/jojo resume -e "Acme Corp" -j job.txt
```

- Validates that research.md exists (dependency from Phase 3)
- Runs ResumeGenerator only
- Uses StatusLogger to log the operation

### Integrated into Generate Command

```bash
./bin/jojo generate -e "Acme Corp" -j job.txt
```

- Runs after research generation (Phase 3)
- Before cover letter generation (Phase 5)
- Part of full workflow

## Testing Strategy

### Unit Tests

Location: `test/unit/generators/resume_generator_test.rb`

Test coverage:
- Mock AI client responses
- Input gathering with missing files
- Landing page link generation with various company names/slugs
- Pruning instructions in prompt generation
- Markdown output formatting
- All error paths (missing generic resume = failure)
- Graceful degradation (missing research = warning)

### Test Fixtures

Location: `test/fixtures/`

- `generic_resume.md` - sample resume with extra skills/projects to demonstrate pruning
- Expected tailored output for comparison

## File Structure

```
lib/jojo/
  generators/
    resume_generator.rb       # New: Main generator class
  prompts/
    resume_prompt.rb          # New: Prompt template module

test/unit/
  generators/
    resume_generator_test.rb  # New: Unit tests

test/fixtures/
  generic_resume.md           # New: Test fixture
```

## Success Criteria

- `./bin/jojo resume -e "Acme Corp" -j test_job.txt` generates tailored `resume.md`
- Generated resume includes deterministic landing page link
- Resume maintains structure of generic resume
- Less relevant skills/projects are pruned
- Bullet points are reworded with job description keywords
- Professional summary is tailored to specific role
- All tests pass
- StatusLogger records the operation
