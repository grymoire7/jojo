---
title: cover-letter
parent: Commands
nav_order: 7
---

# jojo cover_letter

Generate a personalized cover letter based on company research, job analysis, and your tailored resume.

## Usage

```bash
./bin/jojo cover_letter -s SLUG
./bin/jojo cover_letter  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing cover letter without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |
| `applications/<slug>/resume.md` | Tailored resume (from `jojo resume`) |
| `inputs/resume_data.yml` | Your structured resume data |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/cover_letter.md` | Personalized cover letter |
| `applications/<slug>/status_log.md` | Process log |

{: .important }
The cover letter depends on the tailored resume. Run `jojo resume` first, or use `jojo generate` which handles ordering automatically.
