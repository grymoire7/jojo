# Technical blog post design

**Date**: 2026-02-14
**Status**: Draft

## Purpose

Write a technical deep dive blog post about Jojo for Tracy's portfolio site
(tracyatteberry.com/posts/jojo). The intended audience is prospective employers
and collaborators. The post should demonstrate technical depth, practical
problem-solving, and willingness to iterate — all through the lens of building
a real tool that solves a real problem.

## Writing style

- Casual expertise — like a friendly, talented teacher explaining complex topics
  with simple language and examples
- More like an entertaining conference talk than a business whitepaper
- Simple, direct language — compelling but not flowery or dramatic
- Sentence case for headings (e.g., "Document processing pipeline")
- Avoid "not just X, but Y" constructions
- Avoid "the real... is..." or "that's when the real X happens"
- Scannable — clear headings that work as a table of contents for readers who
  skim before committing to read

## Target length

3,000-4,000 words. Enough depth to reward careful readers, structured enough
that skimmers can find what interests them.

## Approach

Problem-forward narrative (Approach 1 from brainstorming). Start with the
problem, show the solution, then peel back layers to reveal technical depth.
Progressive disclosure — casual readers get the "what and why" up front, deep
readers get architecture and trade-offs as they continue.

## Outline

### 1. The problem (~300 words)

**Hook:** The job search numbers game — hundreds of applicants per posting, most
submitting roughly the same documents. Customizing a resume helps, but it
doesn't solve the fundamental problem: you're a PDF in a pile of PDFs.

**The UVP:** Instead of just tailoring documents, give each company their own
landing page — a mini marketing site that shows exactly why you're a match for
*their* role. Annotated job descriptions mapping your experience to their
requirements. Curated portfolio projects relevant to their tech stack. A
branding statement written for their company. A call-to-action to schedule a
conversation.

**The product-launch framing:** Jojo treats each application like launching a
product (you) to a specific customer (the company). The resume and cover letter
are part of the package, but the landing page is the centerpiece — it turns a
passive application into an active pitch.

**What Jojo does:** Brief overview of the pipeline — one command generates the
full package.

**Include:** Flow diagram (inputs → Jojo → outputs).

### 2. How it works (~400 words)

**The pipeline walkthrough:** What happens when you run `jojo generate` — job
description processing, research generation, resume curation, cover letter,
website generation. Concrete command examples.

**Slug-based workspaces:** Each application gets its own directory. Brief file
tree showing the generated artifacts.

**The interactive dashboard:** The TUI mode with dependency tracking, staleness
detection, status at a glance. Shows UX thinking beyond "it runs AI prompts."

**Purpose:** Give the reader a mental model of the system before going deeper. A
prospective employer should think "this is a real tool with real workflow design,
not a wrapper around an API."

### 3. Architecture — the command pipeline (~500 words)

**The pattern:** Every command follows command.rb / generator.rb / prompt.rb.
Why this matters — adding a new command means creating three files following an
established pattern, not modifying a monolith.

**The refactoring story (brief):** CLI started as an 877-line monolith. As it
grew, adding commands meant modifying a single massive file. The refactor to
command modules made each command self-contained and independently testable.
Keep it concise — enough to show willingness to refactor when architecture isn't
working.

**Dual AI models:** Reasoning model for complex tasks (research, resume
tailoring), text generation model for simpler tasks (metadata extraction,
annotations). The cost/quality trade-off in a sentence or two.

**Key takeaway for readers:** Deliberate architecture decisions, consistent
patterns, and the discipline to refactor when something outgrows its design.

### 4. Solving the hallucination problem (~600 words, centerpiece)

**The problem:** AI is great at writing but it fabricates details. When you ask
it to tailor a resume, it might add skills you don't have or exaggerate
experience. For a resume, that's a dealbreaker.

**The first approach and its failure:** Let AI freely rewrite the resume from
structured YAML data. Despite extensive anti-fabrication prompts, hallucinations
still appeared — especially in skills and technology lists.

**The insight:** Different resume fields have different risk profiles. A
professional summary *should* be rewritten for each role. A list of programming
languages *must not* be modified. The problem isn't "AI can't be trusted" — it's
"AI shouldn't have the same permissions everywhere."

**The solution — permission-based curation:** A permission system embedded in
the YAML resume data:

- `read-only` — don't touch it (contact info, dates)
- `remove` — can exclude irrelevant items (tools, databases)
- `reorder` — can prioritize by relevance (skills, experience entries)
- `rewrite` — can generate new content (professional summary, descriptions)

**The two-pass architecture:**

1. Pass 1 curates: filter and reorder based on permissions
2. Pass 2 generates: rewrite only the fields explicitly marked as safe
3. ERB templates render the final output — no AI touching the markdown structure

**Concrete example:** "The AI used to add 'Kubernetes' to my skills when I
mentioned Docker. Now it can't — skills are `reorder` only, so it can
prioritize Docker higher but can't invent new entries."

**Key takeaway:** Problem decomposition — breaking a fuzzy problem ("AI
hallucinates") into a precise solution (field-level permissions with a two-pass
pipeline).

### 5. Testing as a development discipline (~400 words)

**The thesis:** Testing matters more, not less, with AI-assisted development. AI
assistants are eager to write features and often need nudging toward test
coverage — just like human developers.

**Three-tier test organization:**

- Unit tests — fast, no external dependencies
- Integration tests — mocked services
- Service tests — real API calls, costs money

Explain the decision rule: real external call → service, mocked → integration,
pure logic → unit.

**The coverage story:** The push from ~31% to 84% coverage was a deliberate
effort, not an afterthought. The `coverage_summary` script for tracking it.

**VCR for HTTP mocking:** Testing a tool that talks to AI APIs is tricky — you
don't want tests that cost money on every run, but you want realistic responses.
VCR records real HTTP interactions and replays them.

**Fixture discipline:** The `inputs/` directory protection rule — tests must
never touch production data. `test/fixtures/` exists for a reason.

**Key takeaway:** Testing is a first-class concern, not a checkbox. The
three-tier structure shows thoughtfulness about test economics (speed vs.
realism vs. cost).

### 6. Building with AI (~400 words)

**The meta angle:** A tool that uses AI to generate content, built with AI
assistance.

**What worked well:** Rapid prototyping, generating boilerplate, exploring
design alternatives, test generation.

**What required human judgment:** Architecture decisions, permission system
design, knowing *when* to refactor, quality standards for prompts.

**Honest assessment:** AI accelerated development significantly (486 commits in
~2 months), but the interesting decisions — the ones this post is about — were
human decisions. AI was a force multiplier, not a replacement for thinking.

**Key takeaway:** Practical, grounded experience with AI-assisted development —
knows where AI helps and where it doesn't.

### 7. What I'd do differently and what's next (~300 words)

**Lessons learned:** 1-2 specific things (e.g., starting with structured YAML
data earlier instead of free-form markdown, building the interactive mode
sooner).

**What's next:** Interview prep generation, direct Hugo integration, application
tracking. Brief — shows forward thinking without over-promising.

**Closing:** Circle back to the opening. Link to the GitHub repo. Invitation to
try it or reach out.

## Structure summary

| # | Section | ~Words | Purpose |
|---|---------|--------|---------|
| 1 | The problem | 300 | Hook — relatable, sets up the UVP |
| 2 | How it works | 400 | Mental model of the system |
| 3 | Architecture | 500 | Technical depth, patterns, refactoring |
| 4 | Permission-based curation | 600 | Centerpiece — novel problem-solving |
| 5 | Testing | 400 | Discipline and test economics |
| 6 | Building with AI | 400 | Dedicated AI section |
| 7 | What's next | 300 | Reflection and forward-looking |
| | **Total** | **~2,900** | Room to expand to 3,500+ during drafting |

## Sources

- Git commit history and messages (486 commits, Dec 2025 - Feb 2026)
- `docs/plans/design.md` — full design document
- `docs/plans/implementation_plan.md` — phase-by-phase build history
- `docs/plans/2026-01-03-resume-curation-redesign.md` — permission system design
- `docs/plans/2026-02-01-cli-commands-refactor-design.md` — refactoring story
- `docs/plans/2026-01-25-interactive-cli-design.md` — TUI dashboard design
- `docs/architecture/key-decisions.md` — architectural decision records
- `docs/architecture/overview.md` — architecture overview
- `README.md` — project overview
- Conversation history from this session
