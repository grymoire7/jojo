---
title: new
parent: Commands
nav_order: 3
---

# jojo new

Create a new application workspace directory.

## Usage

```bash
./bin/jojo new -s SLUG
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | **Required.** Unique identifier for this application |

## Inputs

| Input | Description |
|-------|-------------|
| `inputs/resume_data.yml` | Your structured resume data (checked for presence) |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/` | Workspace directory for the application |

## Next step

After creating the workspace, use [`jojo job_description`](job-description) to process the job posting:

```bash
jojo job_description -s SLUG -j <job_file_or_url>
```

## Examples

```bash
./bin/jojo new -s acme-corp-senior-dev
./bin/jojo new -s bigco-principal-eng
```

## Slug guidelines

The slug is used to organize files and reference the application in all subsequent commands.

| Format | Example |
|--------|---------|
| Company + seniority + role | `acme-corp-senior-dev` |
| Short company + level + role | `bigco-principal-eng` |
| With year (for repeat applications) | `startup-fullstack-2024` |

Use lowercase letters, numbers, and hyphens only. Keep it concise but descriptive.
