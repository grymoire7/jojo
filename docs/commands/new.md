---
title: new
parent: Commands
nav_order: 3
---

# jojo new

Create an application workspace and process a job description.

## Usage

```bash
./bin/jojo new -s SLUG -j JOB_SOURCE
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | **Required.** Unique identifier for this application |
| `-j, --job JOB_SOURCE` | **Required.** Path to a job description file or a URL |

## Inputs

| Input | Description |
|-------|-------------|
| Job source | A local file path or URL containing the job description |
| `inputs/resume_data.yml` | Your structured resume data |

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
./bin/jojo new -s acme-corp-senior-dev -j job_description.txt
```

From a URL:

```bash
./bin/jojo new -s acme-corp-senior-dev -j "https://careers.acmecorp.com/jobs/123"
```

## Slug guidelines

The slug is used to organize files and reference the application in all subsequent commands.

| Format | Example |
|--------|---------|
| Company + seniority + role | `acme-corp-senior-dev` |
| Short company + level + role | `bigco-principal-eng` |
| With year (for repeat applications) | `startup-fullstack-2024` |

Use lowercase letters, numbers, and hyphens only. Keep it concise but descriptive.
