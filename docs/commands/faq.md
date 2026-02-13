---
title: faq
parent: Commands
nav_order: 10
---

# jojo faq

Generate role-specific FAQ content derived from your background and the job requirements.

## Usage

```bash
./bin/jojo faq -s SLUG
./bin/jojo faq  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing FAQ without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |
| `applications/<slug>/resume.md` | Tailored resume |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/faq.json` | FAQ questions and answers |

## FAQ content

The generated FAQ includes both standard and custom questions:

- **Standard questions** — Common employer questions (e.g., "Why are you interested in this role?")
- **Custom questions** — Role-specific questions derived from the job description and your background

FAQ content is rendered as an accordion section on the [website](website) landing page.
