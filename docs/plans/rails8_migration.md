# Rails 8 SaaS Migration Plan

**Date:** 2026-02-27
**Status:** Estimate / Pre-planning
**Scope:** Migrate jojo CLI to a multi-user Rails 8 SaaS with one-time purchase per generated bundle

---

## Overview

Jojo is currently a single-user Ruby CLI (Thor-based) that generates AI-powered job application
bundles: tailored resume, cover letter, landing page HTML, annotations, and FAQ. The goal is to
migrate it to a multi-user web application where users purchase and download their generated
bundles.

---

## Constraints and Decisions

| Decision         | Choice                         | Rationale                                       |
| ---------------- | ------------------------------ | ----------------------------------------------- |
| Pricing model    | One-time purchase per bundle   | Simplest Stripe integration; no subscriptions   |
| UI framework     | Hotwire / Turbo                | Natural fit for Rails 8; no JS build complexity |
| Hosting          | Managed (Render or Fly.io)     | Removes devops overhead                         |
| AI cost tracking | Per sale/bundle, not per user  | Simpler; track cost as part of generation job   |
| Background jobs  | Solid Queue (Rails 8 built-in) | No Redis/Sidekiq needed                         |
| Developer        | 1 senior dev + Claude Code     | ~40% calendar time reduction on implementation  |

---

## Reusability Assessment

| Component                                      | Reuse % | Notes                                      |
| ---------------------------------------------- | ------- | ------------------------------------------ |
| Generator classes (resume, cover letter, etc.) | ~80%    | Extract to service objects / jobs          |
| AI client integration (ruby_llm)               | ~90%    | Keep as-is                                 |
| ERB template rendering                         | ~90%    | Already framework-agnostic                 |
| Resume data transformation                     | ~85%    | Minor API changes                          |
| Prompt logic                                   | ~95%    | Pure functions, easily extracted           |
| CLI commands (Thor)                            | ~0%     | Replace with controllers + background jobs |
| Config singleton                               | ~0%     | Replace with per-user DB config            |
| File I/O layer                                 | ~10%    | Replace with ActiveStorage + S3/R2         |
| Interactive TUI                                | ~0%     | Replace with web UI                        |

**~30% of existing code is directly reusable.** The other 70% is single-user CLI infrastructure
that gets replaced by Rails conventions.

---

## Key Architectural Decision: Generate-Before-Pay vs Pay-Before-Generate

This must be decided before implementation begins.

**Option A: Pay → Generate**
- User purchases first, generation runs after payment confirmed
- Simpler (no waste on unpurchased bundles)
- Harder to sell (user can't preview before committing)
- Lower AI cost risk

**Option B: Generate → Pay → Download**
- User generates bundle, previews summary, then purchases to unlock download
- Better UX and conversion
- Burns AI credits regardless of purchase; needs abuse prevention
- Recommended if conversion rate matters

---

## Data Model

```
User
  has_many :job_applications
  has_many :resume_profiles

ResumeProfile
  belongs_to :user
  data: jsonb  (structured resume data, replaces inputs/resume_data.yml)

JobApplication
  belongs_to :user
  slug: string
  job_details: jsonb        (extracted metadata: company, title, location, etc.)
  job_description: text
  status: enum (pending, generating, ready, purchased)
  has_many :generated_files
  has_one :purchase

GeneratedFile
  belongs_to :job_application
  file_type: enum (resume, cover_letter, website, annotations, faq, bundle_zip)
  attachment: ActiveStorage blob (S3/R2)

Purchase
  belongs_to :job_application
  stripe_checkout_session_id: string
  stripe_payment_intent_id: string
  amount_cents: integer
  ai_cost_cents: integer   (cost of generation for this bundle)
  purchased_at: datetime
```

---

## Phase Breakdown

### Phase 1 — Rails Foundation (1–1.5 weeks)

- Rails 8 app skeleton with Postgres
- `rails generate authentication` for baseline auth (add email confirmation)
- Pundit for authorization / multi-tenant scoping
- Models and migrations (see data model above)
- ActiveStorage configured for S3 or Cloudflare R2
- Solid Queue configured for background jobs
- Render deployment: app, Postgres, domain, SSL

### Phase 2 — Port Business Logic (1–1.5 weeks)

Each existing generator class maps to a pair:
- `app/services/{step}_generator.rb` — pure generation logic (ported from `lib/jojo/commands/`)
- `app/jobs/{step}_generation_job.rb` — enqueues generator, writes output to ActiveStorage

File I/O layer changes: `File.write(path, content)` → `blob.upload(content)` via ActiveStorage.
Everything else (prompts, AI client, ERB rendering) is unchanged.

Steps to port: `research`, `resume`, `branding`, `cover_letter`, `annotate`, `faq`, `website`, `pdf`

### Phase 3 — Payments & Downloads (1 week)

Stripe Checkout (one-time payment, no subscriptions):

1. `POST /purchases` → create Stripe Checkout Session → redirect to Stripe
2. Stripe webhook: `checkout.session.completed` → mark `Purchase` paid → enqueue download prep job
3. `GET /applications/:id/download/:file_type` → verify purchase → redirect to signed ActiveStorage URL (24hr expiry)

No customer portal, no proration, no subscription lifecycle. 3 controllers, 1 webhook endpoint.

Record `ai_cost_cents` on `Purchase` at generation time for cost-per-sale tracking.

### Phase 4 — Web UI (2–3 weeks)

Core views (Hotwire/Turbo throughout):

- **Dashboard** — application list, status badges, create button
- **New application flow** — paste/upload job description, select resume profile
- **Application detail** — step status list, generation progress via Turbo Streams
- **Resume profile editor** — nested form for structured YAML data (experience, projects,
  education); this is the most complex form; plan ~3 days
- **Download center** — file list with purchase CTA; signed URL downloads post-purchase
- **Account page** — email, password, billing history

Real-time generation progress: Turbo Stream broadcast from each `*GenerationJob` as steps
complete. No Action Cable required for basic polling fallback.

### Phase 5 — Infrastructure (0.5 weeks)

Render setup:
- Web service (Rails)
- Postgres database
- Background worker (Solid Queue, same dyno or separate)
- Environment variables: Stripe keys, AI API keys, ActiveStorage credentials
- Custom domain + auto-SSL

### Phase 6 — Testing (1 week)

- Port unit tests for service objects (generators)
- System tests for critical flows: auth, generate, purchase, download
- Update VCR cassettes for service-object context
- Stripe webhook testing via Stripe CLI

---

## Timeline Summary

| Phase                | Estimate      |
| -------------------- | ------------- |
| Rails Foundation     | 1–1.5 weeks   |
| Port Business Logic  | 1–1.5 weeks   |
| Payments & Downloads | 1 week        |
| Web UI               | 2–3 weeks     |
| Infrastructure       | 0.5 weeks     |
| Testing              | 1 week        |
| **Total**            | **7–9 weeks** |

Realistic calendar time: **8 weeks** with good scope discipline.

---

## Where Claude Code Helps Most

- Boilerplate scaffolding: models, migrations, controllers, policies
- Mechanical porting: CLI generators → service objects (repetitive, well-defined)
- Standard integrations: Stripe Checkout, ActiveStorage setup
- Writing unit tests for service objects

## Where Human Judgment Is Still Required

- Architectural decisions (generate-before/after pay, data model finalization)
- Reviewing and testing all generated output before trusting it
- UX decisions and visual polish
- Edge case handling (generation failure post-purchase, partial bundles)
- Integration testing in staging

---

## Biggest Risks

1. **Resume profile editor complexity** — Nested arrays (experience, projects, education) with
   add/remove/reorder are non-trivial with Turbo/Stimulus. Underestimated most often.

2. **Generation failure post-purchase** — If AI generation fails after payment, need a clear
   retry/refund path. Define this before building.

3. **Real-time progress UX** — Getting Turbo Stream broadcasting right from background jobs
   requires careful connection handling. Test early.

4. **Multi-tenant data isolation** — Every ActiveRecord query must scope to `current_user`.
   A missed scope is a security bug. Use Pundit scopes consistently.

5. **Bundle definition** — What exactly is in a "bundle"? All files? Only PDFs? Zip + HTML?
   Decide before building the download center.
