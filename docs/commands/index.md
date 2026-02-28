---
title: Commands
nav_order: 3
has_children: true
---

# Commands

## Overview

| Command | Description | Required Options |
|---------|-------------|------------------|
| [`jojo configure`](configure) | Interactive configuration wizard for API keys and preferences | None |
| [`jojo new`](new) | Create a new application workspace | `-s` |
| [`jojo job_description`](job-description) | Process job description for an application | `-j` |
| [`jojo research`](research) | Generate company/role research only | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo resume`](resume) | Generate tailored resume only | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo cover_letter`](cover-letter) | Generate cover letter only | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo annotate`](annotate) | Generate annotated job description | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo branding`](branding) | Generate AI branding statement | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo faq`](faq) | Generate FAQ content | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo website`](website) | Generate landing page | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo pdf`](pdf) | Generate PDF versions of resume and cover letter | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo interactive`](interactive) | TUI dashboard mode | None |
| `jojo version` | Show version | None |
| `jojo help [COMMAND]` | Show help | None |

## Inputs/Outputs

| Command | Inputs | Outputs |
|---------|--------|---------|
| [`jojo configure`](configure) | None (interactive) | `.env`, `config.yml`, `inputs/resume_data.yml` |
| [`jojo new`](new) | `inputs/resume_data.yml` | `applications/<slug>/` (workspace directory) |
| [`jojo job_description`](job-description) | Job source (file or URL via `-j`) | `applications/<slug>/job_description_raw.md`, `job_description.md`, `job_details.yml`, `website/` |
| [`jojo research`](research) | `applications/<slug>/job_description.md`, `job_details.yml` | `applications/<slug>/research.md`, `status_log.md` |
| [`jojo resume`](resume) | `applications/<slug>/job_description.md`, `job_details.yml`, `inputs/resume_data.yml`, `resume_data_curated.yml` (cache, if present) | `applications/<slug>/resume.md`, `resume_data_curated.yml` (cache), `status_log.md` |
| [`jojo cover_letter`](cover-letter) | `applications/<slug>/job_description.md`, `job_details.yml`, `resume.md`, `inputs/resume_data.yml` | `applications/<slug>/cover_letter.md`, `status_log.md` |
| [`jojo annotate`](annotate) | `applications/<slug>/job_description.md`, `job_details.yml` | `applications/<slug>/job_description_annotations.json` |
| [`jojo branding`](branding) | `applications/<slug>/job_description.md`, `job_details.yml`, `resume.md`, optional: `research.md` | `applications/<slug>/branding_statement.json` |
| [`jojo faq`](faq) | `applications/<slug>/job_description.md`, `job_details.yml`, `resume.md` | `applications/<slug>/faq.json` |
| [`jojo website`](website) | `applications/<slug>/job_description.md`, `job_details.yml`, `resume.md`, optional: `research.md`, `faq.json`, `job_description_annotations.json`, `templates/*` | `applications/<slug>/website/index.html`, `status_log.md` |
| [`jojo pdf`](pdf) | `applications/<slug>/resume.md`, `cover_letter.md` | `applications/<slug>/resume.pdf`, `cover_letter.pdf` |

## Global options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (unique identifier for the job application) |
| `-t, --template TEMPLATE` | Website template name (default: `"index"`) |
| `-v, --verbose` | Run verbosely with detailed output |
| `-q, --quiet` | Suppress output, rely on exit code only |
| `--overwrite` | Overwrite existing files without prompting |
| `--no-overwrite` | Always prompt before overwriting files |

## Environment variables

| Variable | Description |
|----------|-------------|
| `JOJO_APPLICATION_SLUG` | Set this to avoid repeating `--slug` for every command |
| `JOJO_ALWAYS_OVERWRITE` | Set to `true`, `1`, or `yes` to skip overwrite prompts |

## Overwrite precedence

When a command would overwrite an existing file, Jojo follows this precedence:

1. `--overwrite` flag — always overwrites
2. `--no-overwrite` flag — always prompts
3. `JOJO_ALWAYS_OVERWRITE=true` — overwrites
4. Default — prompts
