# Branding Statement Extraction Design

## Overview

Extract branding statement generation from `WebsiteGenerator` into a standalone `jojo branding` command. This allows website regeneration (after template changes, for example) without incurring API fees.

## Command & File Structure

**New Command:**
```
jojo branding -s <slug> [--overwrite]
```

**Output File:**
```
employers/<slug>/branding.md
```

The file contains only the branding statement text - no frontmatter, no markdown headers.

**Required Inputs:**
- `job_description.md`
- `resume.md`

**Optional Inputs:**
- `research.md`
- `job_details.yml`

## Behavior

### `jojo branding`

- If `branding.md` exists and `--overwrite` not provided: refuse with error
- If `branding.md` exists and `--overwrite` provided: regenerate
- If `branding.md` doesn't exist: generate and save

### `jojo website`

- If `branding.md` exists: use it (no staleness checks)
- If `branding.md` doesn't exist or empty: fail with error

Error message:
```
Error: branding.md not found for 'cybercoders'
Run 'jojo branding -s cybercoders' first to generate branding statement.
```

### `jojo generate`

- Calls branding generation as part of its flow
- Respects `--overwrite` for branding.md if it already exists

## Implementation Changes

**New file:** `lib/jojo/generators/branding_generator.rb`
- Extracts `generate_branding_statement` logic from WebsiteGenerator
- Reads inputs, calls AI, writes `branding.md`

**Modified:** `lib/jojo/cli.rb`
- Add `branding` command with `-s` and `--overwrite` options

**Modified:** `lib/jojo/generators/website_generator.rb`
- Remove `generate_branding_statement` method
- Read branding from `branding.md` instead
- Fail with clear error if `branding.md` missing

## Workflow

```
jojo new -s acme -j job.txt    # Create workspace
jojo branding -s acme          # Generate branding (API call)
jojo website -s acme           # Generate website (no API call)
jojo website -s acme --template minimal  # Regenerate (no API call)
```
