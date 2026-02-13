---
title: research
parent: Commands
nav_order: 5
---

# jojo research

Generate company and role research using AI and optional web search.

## Usage

```bash
./bin/jojo research -s SLUG
./bin/jojo research  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing research without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/research.md` | Company and role research |
| `applications/<slug>/status_log.md` | Process log |

{: .note }
If a Serper or Tavily API key is configured, research includes live web search results for richer company insights. Without a search key, research is generated from the job description alone.
