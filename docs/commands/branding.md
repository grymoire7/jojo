---
title: branding
parent: Commands
nav_order: 9
---

# jojo branding

Generate an AI branding statement that positions you for a specific role.

## Usage

```bash
./bin/jojo branding -s SLUG
./bin/jojo branding  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing branding statement without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |
| `applications/<slug>/resume.md` | Tailored resume |
| `applications/<slug>/research.md` | Company research (optional) |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/branding_statement.json` | AI-generated branding statement |

The branding statement is used by the [website](website) command in the landing page header.
