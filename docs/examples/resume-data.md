---
title: Resume Data
parent: Examples
nav_order: 2
---

# Resume Data Example

A fully annotated `resume_data.yml` showing the expected schema.

## Full schema

```yaml
# ─── Contact Information ────────────────────────────────────────────
# These fields are always read-only (no permissions apply).
name: "Your Full Name"
email: "your.email@example.com"
phone: "+1-555-0123"
location: "City, State"

# ─── Professional Summary ──────────────────────────────────────────
# Can be rewritten per job if permissions include: summary: [rewrite]
# Keep your base summary general — the AI tailors it for each role.
summary: "Experienced software engineer with 10+ years building
  scalable web applications and distributed systems. Passionate about
  clean architecture and mentoring engineering teams."

# ─── Skills ─────────────────────────────────────────────────────────
# Array field. With [remove, reorder] permissions, AI can filter out
# irrelevant skills and prioritize the most relevant ones.
# List all your skills — the AI curates per job.
skills:
  - Ruby
  - Python
  - JavaScript
  - TypeScript
  - Go
  - SQL
  - GraphQL
  - REST APIs

# ─── Languages ──────────────────────────────────────────────────────
# Spoken/written languages. With [reorder], AI can prioritize
# languages relevant to the role (e.g., if job requires Spanish).
languages:
  - English (native)
  - Spanish (professional working proficiency)

# ─── Databases ──────────────────────────────────────────────────────
# With [remove, reorder], irrelevant databases are filtered out.
databases:
  - PostgreSQL
  - MySQL
  - Redis
  - MongoDB
  - Elasticsearch

# ─── Tools ──────────────────────────────────────────────────────────
# Development tools and platforms.
tools:
  - Docker
  - Kubernetes
  - Git
  - GitHub Actions
  - Terraform
  - AWS

# ─── Work Experience ────────────────────────────────────────────────
# Array of positions. With [reorder], most relevant experience
# moves to the top regardless of recency.
#
# Nested fields:
#   description: [rewrite] - AI can reword to emphasize relevant work
#   technologies: [remove, reorder] - filter/prioritize per role
#   tags: [remove, reorder] - filter/prioritize per role
experience:
  - company: "TechCorp Inc."
    title: "Senior Software Engineer"
    start_date: "2020-03"
    end_date: "present"
    description: "Led backend team of 5 engineers building microservices
      architecture serving 10M+ requests/day. Reduced API latency by 40%
      through caching strategy and query optimization."
    technologies:
      - Ruby on Rails
      - PostgreSQL
      - Redis
      - Docker
      - AWS
    tags:
      - backend
      - leadership
      - microservices

  - company: "StartupXYZ"
    title: "Full Stack Developer"
    start_date: "2017-06"
    end_date: "2020-02"
    description: "Built customer-facing web application from prototype
      to 50K MAU. Implemented real-time features, payment integration,
      and CI/CD pipeline."
    technologies:
      - Ruby on Rails
      - React
      - PostgreSQL
      - Heroku
    tags:
      - fullstack
      - startup
      - greenfield

# ─── Education ──────────────────────────────────────────────────────
# Nested field: description: [rewrite] allows AI to emphasize
# relevant coursework or achievements.
education:
  - degree: "BS Computer Science"
    institution: "University of California"
    year: "2017"
    description: "Focus on distributed systems and algorithms.
      Senior project: real-time collaborative editing system."

# ─── Projects ───────────────────────────────────────────────────────
# With [reorder], most relevant projects appear first.
# Nested field: skills: [reorder] prioritizes relevant tech.
projects:
  - name: "OpenSource CLI Tool"
    description: "Ruby CLI framework for building interactive
      command-line applications. 500+ GitHub stars."
    url: "https://github.com/username/cli-tool"
    skills:
      - Ruby
      - CLI Design
      - Open Source

  - name: "Real-Time Dashboard"
    description: "WebSocket-based monitoring dashboard for
      distributed systems. Handles 10K concurrent connections."
    url: "https://github.com/username/dashboard"
    skills:
      - Go
      - WebSockets
      - React
      - Redis

# ─── Endorsements/Recommendations ──────────────────────────────────
# With [remove], AI can select the most relevant quotes.
# These supplement the recommendations.md file used in the website.
endorsements:
  - "One of the most thoughtful engineers I've worked with.
     Always considers the bigger picture. — Engineering Manager"
  - "Exceptional at breaking down complex problems into
     manageable pieces. — Tech Lead"
```

## Required vs optional fields

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Used in resume header |
| `email` | Yes | Contact information |
| `phone` | No | Omit if you prefer not to share |
| `location` | No | City/state or "Remote" |
| `summary` | Yes | Professional summary |
| `skills` | Yes | Technical skills list |
| `experience` | Yes | Work history (at least one entry) |
| `education` | No | Formal education |
| `projects` | No | Portfolio projects (used in website) |
| `languages` | No | Spoken/written languages |
| `databases` | No | Can be merged into `skills` if preferred |
| `tools` | No | Can be merged into `skills` if preferred |
| `endorsements` | No | Short recommendation quotes |

## Tips

- **Be comprehensive** — List everything in your base data. The AI curates per job; you don't need to pre-filter.
- **Use concrete numbers** — "10M+ requests/day", "40% latency reduction", "team of 5" gives the AI specific details to work with.
- **Keep descriptions general** — Write descriptions that cover your full scope. The AI rewrites them to emphasize what matters for each role.
- **Update regularly** — Add new skills, projects, and experience as you gain them. The base data is your single source of truth.
