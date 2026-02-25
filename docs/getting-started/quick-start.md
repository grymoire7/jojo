---
title: Quick Start
parent: Getting Started
nav_order: 3
---

# Quick Start

## Step 0: Setup and customize inputs

If you haven't already, bootstrap and configure Jojo:

```bash
./bin/setup        # installs deps and runs the configuration wizard
```

If you've already run `./bin/setup`, you can re-run the configuration wizard alone:

```bash
./bin/jojo setup
```

Then edit your structured resume data:

```bash
nvim inputs/resume_data.yml
```

Replace the example content with your actual experience, skills, projects, and achievements. **Delete the first comment line** when done.

Optionally customize the resume template and recommendations:

```bash
nvim inputs/templates/default_resume.md.erb
nvim inputs/recommendations.md  # or delete if not needed
```

## Step 1: Create application workspace

Choose a slug — a unique identifier for each job application.

**Good slugs:**
```
acme-corp-senior-dev       # Company + seniority + role
bigco-principal-eng        # Short company name + level + role
startup-fullstack-2024     # Include year if applying multiple times
```

**Avoid:**
```
ACME_Corp_Senior           # Use lowercase and hyphens, not underscores
acme                       # Too vague
acme-corp-senior-software-development-engineer  # Too long
```

Create the workspace from a file or URL:

```bash
# From a file
./bin/jojo new -s acme-corp-senior-dev -j job_description.txt

# From a URL
./bin/jojo new -s acme-corp-senior-dev -j "https://careers.acmecorp.com/jobs/123"
```

This creates `applications/acme-corp-senior-dev/` with:
- `job_description.md` — Processed job description
- `job_details.yml` — Extracted metadata (company name, title, etc.)

## Step 2: Generate application materials

```bash
./bin/jojo generate -s acme-corp-senior-dev
```

Or set the environment variable to avoid repeating the slug:

```bash
export JOJO_APPLICATION_SLUG=acme-corp-senior-dev
./bin/jojo generate
```

This generates:

| File | Description |
|------|-------------|
| `research.md` | Company and role research |
| `resume.md` | Tailored resume |
| `cover_letter.md` | Personalized cover letter |
| `job_description_annotations.json` | Analysis of job requirements |
| `faq.json` | Role-specific FAQ content |
| `website/index.html` | Landing page |
| `resume.pdf` | PDF resume (requires Pandoc) |
| `cover_letter.pdf` | PDF cover letter (requires Pandoc) |
| `status_log.md` | Process log (JSON Lines format) |

## Next steps

- Review and edit the generated materials in `applications/<slug>/`
- Deploy the website to your personal hosting
- Apply with your tailored resume, cover letter, and website link

See the [Your First Application](../guides/first-application) guide for a detailed walkthrough.
