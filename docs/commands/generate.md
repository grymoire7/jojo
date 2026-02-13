---
title: generate
parent: Commands
nav_order: 4
---

# jojo generate

Run all generation steps in sequence: research, resume, cover letter, annotations, branding, FAQ, website, and PDFs.

## Usage

```bash
./bin/jojo generate -s SLUG
./bin/jojo generate  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `-t, --template TEMPLATE` | Website template name (default: `"default"`) |
| `--overwrite` | Overwrite existing files without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description (from `jojo new`) |
| `applications/<slug>/job_details.yml` | Extracted job metadata (from `jojo new`) |
| `inputs/resume_data.yml` | Your structured resume data |
| `inputs/templates/*` | Resume and website templates |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/research.md` | Company and role research |
| `applications/<slug>/resume.md` | Tailored resume |
| `applications/<slug>/cover_letter.md` | Personalized cover letter |
| `applications/<slug>/job_description_annotations.json` | Job requirement analysis |
| `applications/<slug>/branding_statement.json` | AI branding statement |
| `applications/<slug>/faq.json` | Role-specific FAQ content |
| `applications/<slug>/website/index.html` | Landing page |
| `applications/<slug>/resume.pdf` | PDF resume (requires Pandoc) |
| `applications/<slug>/cover_letter.pdf` | PDF cover letter (requires Pandoc) |
| `applications/<slug>/status_log.md` | Process log (JSON Lines format) |

## Step ordering

The `generate` command runs steps in dependency order:

1. **research** — Company and role research
2. **resume** — Tailored resume (uses research)
3. **cover_letter** — Cover letter (uses resume and research)
4. **annotate** — Job description annotations
5. **branding** — AI branding statement (uses resume)
6. **faq** — FAQ content (uses resume)
7. **website** — Landing page (uses all previous outputs)
8. **pdf** — PDF conversion (uses resume and cover letter)

To run individual steps, use the corresponding command directly (e.g., `jojo research`, `jojo resume`).
