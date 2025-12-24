# Cover Letter Generation Design

**Phase**: 5
**Date**: 2025-12-23
**Status**: Approved

## Overview

Design for Phase 5 cover letter generation feature. Adds ability to generate tailored cover letters that complement the resume by telling the "why this company/role" story rather than duplicating resume content.

## Architecture & Dependencies

### Generator Pattern

`CoverLetterGenerator` follows the established architectural pattern:

- **Location**: `lib/jojo/generators/cover_letter_generator.rb`
- **Constructor**: `initialize(employer, ai_client, config:, verbose: false)`
- **Public API**: Single `generate` method returning generated content
- **Private methods**: `gather_inputs`, `build_prompt`, `call_ai`, `add_landing_page_link`, `save_cover_letter`, `log`

### Input Dependencies

**Required inputs** (fail if missing):
- `employers/{slug}/job_description.md` - role requirements
- `employers/{slug}/resume.md` - the tailored resume being submitted
- `inputs/generic_resume.md` - full background for storytelling

**Optional inputs** (warn but continue):
- `employers/{slug}/research.md` - company culture/values/positioning
- `employers/{slug}/job_details.yml` - structured job metadata

### Workflow Position

Cover letter generation occurs after resume in the pipeline:

1. Job description processing
2. Research generation
3. Resume generation
4. **Cover letter generation** ← Phase 5
5. Website generation (Phase 6)
6. PDF generation (Phase 7)

**Key design decision**: Cover letter reads the *tailored* resume (not generic) to ensure perfect alignment with what the candidate is actually submitting. No references to pruned content.

## Prompt Design

### Location

`lib/jojo/prompts/cover_letter_prompt.rb` following existing pattern with module method `CoverLetter.generate_prompt(...)`.

### AI Instructions

The prompt instructs the AI to:

1. **Analyze context**
   - Company culture from research
   - Role requirements from job description
   - Candidate background from both resumes

2. **Craft narrative arc** - "Why this company/role" story:
   - Specific enthusiasm for THIS company (using research)
   - Career journey/motivations connecting to role
   - Authentic references to company mission/values/culture
   - Avoid generic openings

3. **Use flexible structure** - Adapt based on:
   - Company culture signals from research
   - Job level inferred from title/responsibilities
   - Industry context
   - Typical range: 200-400 words, 2-4 paragraphs

4. **Preserve truthfulness** - Same strict rules as resume:
   - No fabrication of experiences
   - Reference only content from resumes
   - Maintain factual accuracy

5. **Include config elements**:
   - Voice/tone from `config.voice_and_tone`
   - Landing page link at top (same format as resume)

### AI Model Selection

Use `ai_client.generate_text(prompt)` (text generation model, likely Haiku) for speed/cost efficiency. Cover letters don't require deep reasoning like research generation.

### Prompt Structure

```
# System Role
You are an expert cover letter writer...

# Context & Inputs
## Job Description
{job_description}

## Company Research
{research if available, otherwise note absence}

## Candidate's Tailored Resume
{tailored resume - what they're submitting}

## Candidate's Full Background
{generic resume - additional context for storytelling}

# Writing Instructions
- Flexible length/structure based on company culture
- "Why this company/role" narrative focus
- Reference resume without duplicating bullet points
- Connect career journey to role requirements
- Authentic voice matching company culture
- Include specific company insights from research

# Constraints
- No fabrication (same rules as resume)
- Use only experiences from resumes
- Maintain truthfulness
- Professional formatting

# Output Format
- Clean markdown
- No commentary, just the cover letter
- Voice/tone: {voice_and_tone from config}
```

## CLI Integration

### Standalone Command

Implement the `cover_letter` command in `lib/jojo/cli.rb` (currently placeholder):

```ruby
desc "cover_letter", "Generate cover letter only"
def cover_letter
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
  status_logger = Jojo::StatusLogger.new(employer)

  say "Generating cover letter for #{employer.name}...", :green

  # Ensure employer directory exists
  employer.create_directory! unless Dir.exist?(employer.base_path)

  # Check job description exists
  unless File.exist?(employer.job_description_path)
    say "✗ Job description not found. Run 'generate' first.", :red
    exit 1
  end

  # Check tailored resume exists (REQUIRED)
  unless File.exist?(employer.resume_path)
    say "✗ Tailored resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
    exit 1
  end

  # Check generic resume exists (REQUIRED)
  unless File.exist?('inputs/generic_resume.md')
    say "✗ Generic resume not found at inputs/generic_resume.md", :red
    exit 1
  end

  # Warn if research missing (optional)
  unless File.exist?(employer.research_path)
    say "⚠ Warning: Research not found. Cover letter will be less targeted.", :yellow
  end

  begin
    generator = Jojo::Generators::CoverLetterGenerator.new(
      employer, ai_client, config: config, verbose: options[:verbose]
    )
    cover_letter = generator.generate

    say "✓ Cover letter generated and saved to #{employer.cover_letter_path}", :green

    status_logger.log_step("Cover Letter Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )

    say "\n✓ Cover letter complete!", :green
  rescue => e
    say "✗ Error generating cover letter: #{e.message}", :red
    status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
    exit 1
  end
end
```

### Integration into `generate` Workflow

Add after resume generation step in `generate` command (~line 99):

```ruby
# Generate cover letter
begin
  unless File.exist?(employer.resume_path)
    say "⚠ Warning: Resume not found, skipping cover letter generation", :yellow
  else
    generator = Jojo::Generators::CoverLetterGenerator.new(
      employer, ai_client, config: config, verbose: options[:verbose]
    )
    generator.generate

    say "✓ Cover letter generated and saved", :green
    status_logger.log_step("Cover Letter Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )
  end
rescue => e
  say "✗ Error generating cover letter: #{e.message}", :red
  status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
  exit 1
end

say "\n✓ Generation complete!", :green
```

### Error Handling

**Standalone command failures**:
- Resume missing: "Tailored resume not found. Run 'jojo resume' or 'jojo generate' first."
- Generic resume missing: "Generic resume not found at inputs/generic_resume.md"
- Job description missing: "Job description not found. Run 'generate' first."

**Generate workflow**:
- Should never fail due to missing resume (comes earlier in pipeline)
- Defensive check included anyway
- Skip cover letter generation if resume somehow missing

## Testing Strategy

### Test File

`test/unit/generators/cover_letter_generator_test.rb` following existing generator test patterns.

### Test Coverage

Using Minitest::Mock to avoid real API calls:

1. **Happy path** - All inputs present
   ```ruby
   it "generates cover letter from all inputs" do
     # Mock AI response
     # Verify file saved
     # Verify landing page link included
   end
   ```

2. **Landing page link format**
   ```ruby
   it "generates correct landing page link" do
     # Verify: **Specifically for {Company}**: {base_url}/resume/{slug}
   end
   ```

3. **Required input validation**
   ```ruby
   it "fails when job description is missing"
   it "fails when tailored resume is missing" # Key difference from resume generator
   it "fails when generic resume is missing"
   ```

4. **Optional input handling**
   ```ruby
   it "continues when research is missing with warning"
   it "continues when job details missing"
   ```

5. **File operations**
   ```ruby
   it "saves cover letter to correct path"
   ```

### Fixture Setup

Follow `resume_generator_test.rb` pattern:

```ruby
before do
  @employer = Jojo::Employer.new('Acme Corp')
  @ai_client = Minitest::Mock.new
  @config = Minitest::Mock.new
  @generator = Jojo::Generators::CoverLetterGenerator.new(...)

  # Create directories and required files
  @employer.create_directory!
  File.write(@employer.job_description_path, "Job description...")
  File.write(@employer.resume_path, "Tailored resume...") # Required!
  FileUtils.mkdir_p('inputs')
  File.write('inputs/generic_resume.md', "Generic resume...")
  File.write(@employer.research_path, "Research...") # Optional
end

after do
  FileUtils.rm_rf(@employer.base_path)
  FileUtils.rm_f('inputs/generic_resume.md')
  @config.verify
end
```

## Implementation Details

### File Output

- **Path**: `employers/{slug}/cover_letter.md` (via `employer.cover_letter_path`)
- **Encoding**: UTF-8
- **Format**: Clean markdown with landing page link at top

### Landing Page Link

Same format as resume:
```markdown
**Specifically for {Company Name}**: {base_url}/resume/{company_slug}

[Cover letter content begins here...]
```

**Design rationale**: Maximize opportunities to drive traffic to landing page (marketing funnel). Keep consistent pattern across documents. Can re-evaluate if feedback suggests it's too aggressive.

### Logging

- Verbose logging using `log(message)` helper (same pattern as other generators)
- Status log entries with timestamps and token usage
- Clear error messages with actionable guidance

### Status Logging

```ruby
status_logger.log_step("Cover Letter Generation",
  tokens: ai_client.total_tokens_used,
  status: "complete" # or "failed"
)
```

## Files to Create/Modify

### New Files

1. `lib/jojo/generators/cover_letter_generator.rb` - Main generator class
2. `lib/jojo/prompts/cover_letter_prompt.rb` - Prompt template
3. `test/unit/generators/cover_letter_generator_test.rb` - Unit tests

### Modified Files

1. `lib/jojo/cli.rb`:
   - Implement `cover_letter` command (replace placeholder)
   - Add cover letter step to `generate` workflow
   - Update completion message (remove "Phase 5 coming" notice)

2. `docs/plans/implementation_plan.md`:
   - Mark Phase 5 tasks as complete
   - Update phase status to COMPLETED

## Success Criteria

- [ ] `./bin/jojo cover_letter -e "Acme Corp" -j test_job.txt` generates cover_letter.md
- [ ] Cover letter includes landing page link at top
- [ ] Cover letter tells "why" story complementing resume
- [ ] Cover letter adapts tone/length based on company culture from research
- [ ] Fails gracefully when required inputs missing with clear error messages
- [ ] Warns but continues when optional inputs (research) missing
- [ ] All unit tests pass
- [ ] Integration into `generate` workflow works end-to-end
- [ ] Status log tracks cover letter generation step

## Design Decisions & Rationale

1. **Use tailored resume as input** (not generic)
   - Ensures cover letter references what candidate is actually submitting
   - Prevents references to pruned content
   - Creates dependency: resume must be generated first

2. **"Why" story focus** (not resume duplication)
   - Differentiates cover letter value proposition
   - Leverages research insights about company culture/values
   - More compelling narrative than restating resume bullets

3. **Flexible AI-driven structure**
   - Adapts to company culture signals
   - More authentic than rigid template
   - Matches what research already provides

4. **Same landing page link pattern as resume**
   - Consistency reinforces professional brand
   - Maximizes conversion opportunities
   - Easy to change if feedback suggests otherwise

5. **Text generation model** (not reasoning model)
   - Cover letter writing is less complex than research
   - Faster and cheaper (Haiku vs Sonnet)
   - Consistent with resume generation approach
