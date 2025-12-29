# Slug Refactoring Implementation Plan

**Created:** 2025-12-28
**Status:** Planning
**Target Version:** 0.2.0

## Overview

Refactor jojo to eliminate the need for repeated `-j` flag usage by introducing a `jojo new` command that creates employer artifacts once, which are then reused by other commands. Replace the `-e` (employer name) flag with `--slug (-s)` for clarity.

## Goals

1. **Reduce repetition**: Parse job description once, reuse everywhere
2. **Improve clarity**: Use slug as explicit identifier instead of employer name
3. **Better UX**: Support `JOJO_EMPLOYER_SLUG` environment variable for context
4. **Cleaner workflow**: Separate setup (`new`) from usage (`resume`, `cover_letter`, etc.)

## Key Changes

### 1. New Command: `jojo new`

Creates initial artifacts for a new employer/position.

**Usage:**
```bash
jojo new -s acme-corp-senior-dev -j job_description.txt
jojo new -s bigco-principal -j https://careers.bigco.com/jobs/123
jojo new -s acme-corp-senior-dev -j job.txt --overwrite  # Recreate from scratch
```

**Behavior:**
- Creates employer directory: `employers/<slug>/`
- Saves raw job description
- Processes job description (URL → markdown, extract text)
- Creates `job_details.yml` with extracted metadata
- Only creates missing artifacts unless `--overwrite` flag is used

**Options:**
- `-s, --slug SLUG` (required) - Unique employer identifier
- `-j, --job JOB` (required) - Job description file path or URL
- `-o, --overwrite` (optional) - Overwrite existing artifacts

### 2. Global Flag Changes

**Remove:**
- `-e, --employer` - Replaced by `--slug`
- `-j, --job` as global option - Only for `jojo new` command

**Add:**
- `-s, --slug SLUG` - Employer slug (unique identifier)

**Keep:**
- `-v, --verbose`
- `-q, --quiet`
- `-t, --template`

### 3. Environment Variable Support

Commands will check for employer slug in this order:
1. `--slug` flag
2. `JOJO_EMPLOYER_SLUG` environment variable
3. If neither exists, error with helpful message

### 4. job_details.yml Schema

```yaml
# Auto-populated fields
company_name: "Acme Corp"           # Extracted from job description, fallback to slug
position_title: "Senior Engineer"    # Extracted from job description
created_at: "2025-12-28"            # Timestamp when created
job_url: "https://..."              # Original URL if -j was a URL (optional)

# Optional fields (extracted if present)
location: "Remote"
salary_range: "$150k-$200k"
department: "Engineering"
```

## Implementation Steps

### Phase 1: Add `jojo new` Command

**Files to modify:**
- `lib/jojo/cli.rb` - Add `new` command
- `lib/jojo/employer.rb` - Add methods for artifact creation

**New files:**
- `lib/jojo/job_details_extractor.rb` - Extract metadata from job description

**Tasks:**
1. Add `new` command to CLI with `-s`, `-j`, `-o` options
2. Implement `Employer#create_artifacts` method:
   - Create employer directory
   - Save raw job description to `raw_job_description.md`
   - Process job description (URL fetch, HTML→markdown)
   - Save processed description to `job_description.md`
   - Extract metadata and create `job_details.yml`
3. Implement `JobDetailsExtractor` class:
   - Parse job description for company name
   - Extract position title
   - Extract location, salary, department (if present)
   - Generate job_details.yml content
4. Handle `--overwrite` flag to recreate artifacts
5. Add error handling for missing/invalid job sources

### Phase 2: Update Employer Class

**Files to modify:**
- `lib/jojo/employer.rb`

**Tasks:**
1. Add new path methods:
   - `raw_job_description_path` - Raw job description from user
   - `job_details_path` - Path to job_details.yml
2. Add `job_details` method to load YAML
3. Add `company_name` method to read from job_details.yml
4. Update `initialize` to accept slug instead of name
5. Add validation to check if artifacts exist
6. Add `artifacts_exist?` helper method

### Phase 3: Update Global Options

**Files to modify:**
- `lib/jojo/cli.rb`

**Tasks:**
1. Replace global option:
   ```ruby
   # OLD
   class_option :employer, aliases: '-e', desc: 'Employer name'
   class_option :job, aliases: '-j', desc: 'Job description (file path or URL)'

   # NEW
   class_option :slug, aliases: '-s', desc: 'Employer slug (unique identifier)'
   ```
2. Add helper method `resolve_slug` to check:
   - Flag: `options[:slug]`
   - Env var: `ENV['JOJO_EMPLOYER_SLUG']`
   - Error if neither exists
3. Update all commands to use `resolve_slug`

### Phase 4: Update Existing Commands

**Files to modify:**
- `lib/jojo/cli.rb` - All command methods

**Commands to update:**
- `generate`
- `research`
- `resume`
- `cover_letter`
- `annotate`
- `website`

**Tasks for each command:**
1. Replace `-e` and `-j` usage with `--slug`
2. Use `resolve_slug` to get employer slug
3. Initialize `Employer` with slug
4. Check if artifacts exist, error if missing:
   ```ruby
   unless employer.artifacts_exist?
     error "Employer '#{slug}' not found."
     say "Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
     exit 1
   end
   ```
5. Use `employer.job_description_path` instead of processing `-j` flag
6. Use `employer.job_details` for metadata access

### Phase 5: Remove Job Description Processing from Commands

**Files to modify:**
- `lib/jojo/cli.rb` - Remove job description processing from commands
- `lib/jojo/job_description_processor.rb` - May need to move logic to `new` command

**Tasks:**
1. Move job description processing logic to `jojo new` command
2. Remove `-j` processing from `generate`, `research`, etc.
3. Commands should only read from `employer.job_description_path`

### Phase 6: Update Help Text

**Files to modify:**
- `lib/jojo/cli.rb` - All command descriptions

**Tasks:**
1. Update command descriptions to reference `--slug` instead of `--employer`
2. Remove references to `-j` from non-new commands
3. Add examples showing new workflow
4. Update error messages to guide users to `jojo new`

### Phase 7: Testing

**New tests:**
- `test/unit/job_details_extractor_test.rb` - Test metadata extraction
- `test/unit/cli_new_test.rb` - Test `new` command
- `test/integration/new_workflow_test.rb` - Test full workflow

**Tests to update:**
- All existing command tests to use new flag syntax
- Employer tests for new methods
- Integration tests for new workflow

**Test scenarios:**
1. `jojo new` creates all artifacts correctly
2. `jojo new` with `--overwrite` replaces existing artifacts
3. `jojo new` extracts job details correctly
4. Commands fail gracefully when artifacts missing
5. `JOJO_EMPLOYER_SLUG` env var works correctly
6. Commands work with `--slug` flag
7. Error messages guide users to correct commands

### Phase 8: Documentation Updates

**Files to update:**
- `README.md` - Update all examples and workflow
- `CHANGELOG.md` - Document breaking changes
- `docs/plans/design.md` - Update workflow description
- `templates/` - May need new template files

**Documentation tasks:**
1. Update README with new workflow:
   ```bash
   # Step 1: Create employer workspace
   jojo new -s acme-corp-senior -j job.txt

   # Step 2: Set context (optional)
   export JOJO_EMPLOYER_SLUG=acme-corp-senior

   # Step 3: Generate materials
   jojo research
   jojo resume
   jojo cover_letter
   jojo website
   ```
2. Document `JOJO_EMPLOYER_SLUG` environment variable
3. Add migration notes for existing users (though pre-1.0)
4. Update all command examples
5. Add troubleshooting section

## File Changes Summary

### New Files
- `lib/jojo/job_details_extractor.rb` - Extract metadata from job descriptions
- `test/unit/job_details_extractor_test.rb` - Tests for extractor
- `test/unit/cli_new_test.rb` - Tests for new command
- `test/integration/new_workflow_test.rb` - Integration tests
- `docs/plans/slug_refactoring_plan.md` - This document

### Modified Files
- `lib/jojo/cli.rb` - Add `new` command, update all commands, change global options
- `lib/jojo/employer.rb` - Add artifact methods, update initialization
- `lib/jojo/job_description_processor.rb` - Possibly refactor for use in `new` command
- `README.md` - Complete workflow update
- `CHANGELOG.md` - Document breaking changes
- `docs/plans/design.md` - Update workflow description
- All test files - Update to new flag syntax

## Breaking Changes

### Version Bump: 0.1.0 → 0.2.0

1. **Global option `-e` removed** - Replaced with `-s, --slug`
2. **Global option `-j` removed** - Only available on `new` command
3. **New command required** - Must run `jojo new` before other commands
4. **Employer identified by slug** - Not by name anymore

### Migration Path for Existing Users

Since jojo is pre-1.0 and not publicly released:
- No automated migration needed
- Users need to run `jojo new` for existing employers
- Document in CHANGELOG

## Error Messages

### Missing Slug
```
Error: No employer specified.
Provide --slug or set JOJO_EMPLOYER_SLUG environment variable.

Example:
  jojo resume --slug acme-corp-senior
  export JOJO_EMPLOYER_SLUG=acme-corp-senior && jojo resume
```

### Employer Not Found
```
Error: Employer 'acme-corp' not found.
Run 'jojo new -s acme-corp -j JOB_DESCRIPTION' to create it.

Tip: Check available employers in the employers/ directory.
```

### Missing Required Flag
```
Error: Missing required option: --job

Usage:
  jojo new -s SLUG -j JOB_DESCRIPTION

Examples:
  jojo new -s acme-corp-senior -j job.txt
  jojo new -s bigco-staff -j https://careers.bigco.com/jobs/123
```

## Success Criteria

- [ ] `jojo new` command creates all artifacts
- [ ] `jojo new --overwrite` recreates artifacts
- [ ] All commands work with `--slug` flag
- [ ] All commands work with `JOJO_EMPLOYER_SLUG` env var
- [ ] Commands fail gracefully with helpful messages
- [ ] job_details.yml correctly extracts metadata
- [ ] All tests passing
- [ ] README updated with new workflow
- [ ] CHANGELOG documents breaking changes

## Future Enhancements (Not in This Phase)

- `jojo list` command to show all employers
- Interactive selection when slug not provided
- `.jojo` file for per-directory context
- Status tracking in job_details.yml (applied, interviewing, etc.)
- `jojo switch` command to set JOJO_EMPLOYER_SLUG
- Shell completion for slugs

## Implementation Order

1. **Phase 1** - Add `jojo new` command (foundation)
2. **Phase 2** - Update Employer class (support new workflow)
3. **Phase 5** - Move job description processing (consolidate logic)
4. **Phase 3** - Update global options (break old interface)
5. **Phase 4** - Update existing commands (use new interface)
6. **Phase 6** - Update help text (user-facing polish)
7. **Phase 7** - Testing (ensure quality)
8. **Phase 8** - Documentation (complete user experience)

## Notes

- This is a breaking change but acceptable for pre-1.0 software
- Focus on making error messages helpful and actionable
- The new workflow is more explicit but less repetitive
- Environment variable support makes repeated operations convenient
- Artifact-based approach enables future enhancements (caching, status tracking)
