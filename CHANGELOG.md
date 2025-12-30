# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Improved setup process: single command creates all configuration files
- Template validation: warns when input files haven't been customized
- `--force` flag for setup command to overwrite existing files
- Comprehensive template examples for resume, recommendations, and projects
- `TemplateValidator` class for detecting unchanged template files
- `SetupService` class for managing setup workflow
- Interactive prompts for unchanged templates in `new` and `generate` commands

### Changed
- Setup command now creates input file templates automatically
- Input templates include placeholder markers for validation
- Setup is now idempotent - safe to run multiple times
- Templates updated with clear, actionable example content
- README updated with streamlined setup instructions

### Removed
- Manual template copying no longer required

## [0.2.0] - 2025-12-28

### Added
- **New `jojo new` command** to create employer workspaces
  - Creates employer directory with processed job description
  - Extracts job details (company name, position, etc.) to `job_details.yml`
  - Supports `--overwrite` flag to recreate artifacts
- **Environment variable support** - `JOJO_EMPLOYER_SLUG` can be set to avoid repeating `--slug` flag
- **Slug-based workflow** - Employers identified by unique slugs instead of names
- `Employer#job_details` method to access parsed job metadata
- `Employer#company_name` method to get company name from job_details.yml
- `Employer#artifacts_exist?` helper to check if workspace has been created

### Changed
- **BREAKING:** Global `-e, --employer` flag removed - replaced with `-s, --slug`
- **BREAKING:** Global `-j, --job` flag removed - only available on `new` command
- **BREAKING:** All commands now require `--slug` flag or `JOJO_EMPLOYER_SLUG` env var
- **BREAKING:** Must run `jojo new` before other commands
- **BREAKING:** `Employer#initialize` now accepts slug directly (no auto-slugification)
- Job description processing moved from individual commands to `new` command
- Commands now check for existing artifacts and show helpful error messages
- All generators use `employer.company_name` for display (from job_details.yml)

### Removed
- **BREAKING:** `-e, --employer` global option (use `-s, --slug`)
- **BREAKING:** Global `-j, --job` option (use `jojo new` command)
- `validate_generate_options!` and `validate_employer_option!` methods
- Auto-slugification logic from `Employer` class

### Migration Guide

#### Old Workflow (0.1.x)
```bash
# Generate everything in one command
./bin/jojo generate -e "Acme Corp" -j job_description.txt
```

#### New Workflow (0.2.0+)
```bash
# Step 1: Create employer workspace
./bin/jojo new -s acme-corp-senior-dev -j job_description.txt

# Step 2: Generate materials (slug required or use env var)
./bin/jojo generate -s acme-corp-senior-dev

# Or use environment variable
export JOJO_EMPLOYER_SLUG=acme-corp-senior-dev
./bin/jojo generate
```

### Why These Changes?

1. **Reduce repetition** - Parse job description once, reuse everywhere
2. **Improve clarity** - Slug is explicit identifier, not derived from name
3. **Better UX** - Environment variable support reduces typing
4. **Cleaner separation** - Setup (`new`) vs. usage (`generate`, `resume`, etc.)

## [0.1.0] - 2025-12-XX

Initial release - see git history for details.
