---
title: job_description
parent: Commands
nav_order: 4
---

# jojo job_description

Process a job description for an existing application workspace. Fetches or reads the job posting, extracts and saves the job description and key metadata.

## Usage

```bash
./bin/jojo job_description -s SLUG -j JOB_SOURCE
./bin/jojo job_description -j JOB_SOURCE  # uses current application from state
```

## Options

| Option | Description |
|--------|-------------|
| `-j, --job JOB_SOURCE` | **Required.** Path to a job description file or a URL |
| `-s, --slug SLUG` | Application slug (uses current application if omitted) |
| `--overwrite` | Overwrite existing files without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| Job source | A local file path or URL containing the job description |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/job_description_raw.md` | Original job description |
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted metadata (company, title, location, etc.) |
| `applications/<slug>/website/` | Website directory scaffold |

## Examples

From a local file:

```bash
./bin/jojo job_description -s acme-corp-senior-dev -j job_description.txt
```

From a URL:

```bash
./bin/jojo job_description -s acme-corp-senior-dev -j "https://careers.acmecorp.com/jobs/123"
```

Using the current application (set via interactive mode or `JOJO_APPLICATION_SLUG`):

```bash
./bin/jojo job_description -j job_description.txt
```
