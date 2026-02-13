---
title: resume
parent: Commands
nav_order: 6
---

# jojo resume

Generate a tailored resume customized for a specific job opportunity.

## Usage

```bash
./bin/jojo resume -s SLUG
./bin/jojo resume  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing resume without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |
| `inputs/resume_data.yml` | Your structured resume data |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/resume.md` | Tailored resume in markdown |
| `applications/<slug>/status_log.md` | Process log |

## How it works

The resume command uses **permissions-based curation** to tailor your resume data for each job. Permissions defined in `config.yml` control what the AI can do with each field:

- **`remove`** — Filter out irrelevant items (e.g., unrelated skills)
- **`reorder`** — Prioritize the most relevant items first
- **`rewrite`** — Reword text to emphasize relevant experience

Fields without permissions are passed through unchanged, preserving your exact wording for things like dates, company names, and contact info.

See the [customizing your resume](../guides/customizing-resume) guide for details.
