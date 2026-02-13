---
title: website
parent: Commands
nav_order: 11
---

# jojo website

Generate a professional landing page that showcases you as the ideal candidate.

## Usage

```bash
./bin/jojo website -s SLUG
./bin/jojo website -s SLUG -t modern  # use a custom template
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `-t, --template TEMPLATE` | Template name (default: `"default"`) |
| `--overwrite` | Overwrite existing website without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/job_description.md` | Processed job description |
| `applications/<slug>/job_details.yml` | Extracted job metadata |
| `applications/<slug>/resume.md` | Tailored resume |
| `applications/<slug>/research.md` | Company research (optional) |
| `applications/<slug>/faq.json` | FAQ content |
| `applications/<slug>/job_description_annotations.json` | Job annotations |
| `applications/<slug>/branding_statement.json` | Branding statement |
| `inputs/templates/*` | Website templates |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/website/index.html` | Landing page |
| `applications/<slug>/status_log.md` | Process log |

## Landing page sections

The default template includes:

- **Masthead** — Your name, branding statement, and call-to-action
- **Portfolio** — Selected projects relevant to the role
- **Recommendations** — LinkedIn recommendations carousel
- **Annotated job description** — Interactive view showing how your experience matches requirements
- **FAQ accordion** — Role-specific questions and answers
- **Call-to-action** — Encourage employers to schedule a call or reach out

## Custom templates

Use the `-t` flag to select a different template. See the [website templates](../guides/website-templates) guide for details on creating custom templates.
