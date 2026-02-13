---
title: annotate
parent: Commands
nav_order: 8
---

# jojo annotate

Generate annotations that analyze how your experience matches each job requirement.

## Usage

```bash
./bin/jojo annotate -s SLUG
./bin/jojo annotate  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing annotations without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/job_description_annotations.json` | Job requirement annotations |

## Annotation format

Each job requirement is categorized with a match tier:

| Tier | Meaning |
|------|---------|
| **Strong** | Direct, demonstrable experience matching the requirement |
| **Moderate** | Related experience that partially satisfies the requirement |
| **Mention** | Tangential experience worth noting |

Annotations are used by the [website](website) command to render an interactive annotated job description on the landing page.
