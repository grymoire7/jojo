---
title: Your First Application
parent: Guides
nav_order: 1
---

# Your First Application

This guide walks you through creating a complete job application with Jojo, from finding a job to deploying your personalized landing page.

## 1. Find a job

Find a job posting you're interested in. Save the job description as a text file or copy the URL.

```bash
# Option A: Save to a file
pbpaste > job_description.txt

# Option B: Have the URL ready
# https://careers.acmecorp.com/jobs/senior-software-engineer
```

## 2. Choose a slug

Pick a short, descriptive identifier for this application. You'll use it in every command.

```bash
# Good: company + level + role
acme-corp-senior-dev
bigco-principal-eng
startup-fullstack-2024
```

Use lowercase letters, numbers, and hyphens only. See the [new command](../commands/new) for detailed slug guidelines.

## 3. Create the workspace

```bash
# From a file
./bin/jojo new -s acme-corp-senior-dev -j job_description.txt

# From a URL
./bin/jojo new -s acme-corp-senior-dev -j "https://careers.acmecorp.com/jobs/123"
```

This creates `applications/acme-corp-senior-dev/` with the processed job description and extracted metadata.

Verify the workspace:

```bash
ls applications/acme-corp-senior-dev/
# job_description.md  job_description_raw.md  job_details.yml  website/
```

Review `job_details.yml` to confirm the company name, job title, and other metadata were extracted correctly.

## 4. Generate all materials

Set the slug once and generate everything:

```bash
export JOJO_APPLICATION_SLUG=acme-corp-senior-dev
./bin/jojo generate
```

This runs all generation steps in order: research, resume, cover letter, annotations, branding, FAQ, website, and PDFs.

The process takes a few minutes depending on your AI provider and model.

## 5. Review the output

Your `applications/acme-corp-senior-dev/` directory now contains:

```
applications/acme-corp-senior-dev/
├── branding_statement.json
├── cover_letter.md
├── cover_letter.pdf
├── faq.json
├── job_description.md
├── job_description_annotations.json
├── job_details.yml
├── research.md
├── resume.md
├── resume.pdf
├── status_log.md
└── website/
    └── index.html
```

Review each file:

- **research.md** — Does the company research look accurate?
- **resume.md** — Are the right skills and experience highlighted?
- **cover_letter.md** — Does it sound like you and address the role?
- **website/index.html** — Open in a browser to preview

## 6. Customize as needed

Edit any markdown file and regenerate specific outputs:

```bash
# Edit resume, then regenerate cover letter and website
nvim applications/acme-corp-senior-dev/resume.md
./bin/jojo cover_letter
./bin/jojo website
```

## 7. Deploy the website

Copy the website directory to your hosting:

```bash
cp -r applications/acme-corp-senior-dev/website/ \
  /path/to/your-site/applications/acme-corp-senior-dev/
```

The landing page is a self-contained HTML file — no build step needed.

## 8. Apply

You now have:
- A tailored **resume** (markdown and PDF)
- A personalized **cover letter** (markdown and PDF)
- A professional **landing page** with portfolio, recommendations, and FAQ

Include the website link in your application to give employers a comprehensive view of what you bring to the role.

## Next steps

- [Customizing Your Resume](customizing-resume) — Control how your resume is tailored
- [Website Templates](website-templates) — Customize the landing page design
- [Commands](../commands/) — Run individual generation steps
