---
title: Configuration
parent: Examples
nav_order: 1
---

# Configuration Example

A fully annotated `config.yml` showing every available option.

```yaml
# ─── Identity ───────────────────────────────────────────────────────
# Your name as it appears on generated materials
seeker_name: Tracy Atteberry

# Base URL where application websites will be deployed
# Each application's website goes to: <base_url>/<slug>/
base_url: https://tracyatteberry.com/applications

# ─── AI Models ──────────────────────────────────────────────────────
# Reasoning model: used for complex tasks like research, resume
# tailoring, and cover letter writing. Choose your strongest model.
reasoning_ai:
  service: anthropic
  model: claude-sonnet-4-5

# Text generation model: used for simpler tasks like job description
# processing, metadata extraction, and annotations. A faster, cheaper
# model works well here.
text_generation_ai:
  service: anthropic
  model: claude-3-5-haiku-20241022

# ─── Voice & Tone ──────────────────────────────────────────────────
# Guides the AI's writing style across all generated content
voice_and_tone: professional and friendly

# ─── Website Settings ───────────────────────────────────────────────
website:
  # Call-to-action button text and link on the landing page
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"
  # You can also use mailto: links
  # cta_link: "mailto:you@example.com"

# ─── Resume Data Permissions ────────────────────────────────────────
# Controls how AI curates your resume_data.yml for each job.
# Fields without permissions are read-only (passed through unchanged).
#
# Permission types:
#   remove  - Filter out irrelevant items from arrays
#   reorder - Change item order to prioritize relevance
#   rewrite - Reword text to emphasize relevant experience
resume_data:
  permissions:
    # ── Array fields: filter and reorder ──
    # AI can remove irrelevant items AND reorder by relevance
    skills: [remove, reorder]
    databases: [remove, reorder]
    tools: [remove, reorder]
    recommendations: [remove]

    # ── Array fields: reorder only ──
    # All items are kept, but order changes by relevance
    # Use this when every item matters but priority should shift
    experience: [reorder]
    projects: [reorder]
    languages: [reorder]

    # ── Text fields: rewrite ──
    # AI can reword these to emphasize relevant experience
    # Use sparingly — review output to ensure it still sounds like you
    summary: [rewrite]
    experience.description: [rewrite]
    education.description: [rewrite]

    # ── Nested array fields ──
    # Permissions on fields within array items (dot notation)
    experience.technologies: [remove, reorder]
    experience.tags: [remove, reorder]
    projects.skills: [reorder]

    # ── Read-only fields (no entry needed) ──
    # These are implicitly read-only because they have no permissions:
    #   name, email, phone, location
    #   experience.company, experience.title
    #   experience.start_date, experience.end_date
    #   education.degree, education.institution, education.year
    #   projects.name, projects.description
```
