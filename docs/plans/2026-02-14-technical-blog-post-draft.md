# Building Jojo: turning job applications into marketing campaigns

<!-- Draft v1 — 2026-02-14 -->

When you apply for a job, you're competing against hundreds of other candidates.
Most of them submit a resume and a cover letter. The ambitious ones tailor those
documents to the role. And then everyone waits.

The problem isn't effort — it's format. No matter how good your resume is, it's
still a PDF in a pile of PDFs. You're asking a hiring manager to do the work of
figuring out why you're a fit. What if you did that work for them?

That's the idea behind [Jojo](https://github.com/grymoire7/jojo), a Ruby CLI I
built to transform job applications into personalized marketing campaigns.
Instead of sending documents, you send a package: a tailored resume, a cover
letter informed by company research, and a dedicated landing page that shows
exactly why you're a match for the role.

The landing page is the centerpiece. It's a mini marketing site with an
annotated job description that maps your experience to their requirements,
portfolio projects selected for relevance to their tech stack, a branding
statement written for their company, LinkedIn recommendations, a FAQ section,
and a call-to-action to schedule a conversation. It turns a passive application
into an active pitch.

Think of it as treating each job application like a product launch. You're the
product. The company is the customer. Jojo builds the marketing campaign.

{{< mermaid >}}
flowchart LR
    A[Resume data] --> J(Jojo)
    B[Job description] --> J
    J --> C[Tailored resume]
    J --> D[Cover letter]
    J --> E[Company research]
    J --> F[Landing page website]
    J --> G[PDF exports]

    style J fill:#CC0000,stroke:#333,stroke-width:2px
    style A fill:#6F42C1,stroke:#333,stroke-width:2px
    style B fill:#6F42C1,stroke:#333,stroke-width:2px
{{< /mermaid >}}

## How it works

The workflow starts with two inputs: your resume data (a structured YAML file)
and a job description (a file or URL). From there, Jojo runs a pipeline of AI-
powered generation steps.

```bash
# Create a new application workspace
jojo new --slug acme-senior-dev --job posting.txt

# Generate everything
jojo generate --slug acme-senior-dev
```

That `generate` command kicks off a sequence:

1. **Research** — AI analyzes the job description and (optionally) searches the
   web to build a research document about the company, the role, and how to
   position yourself.
2. **Resume** — Your structured resume data is curated and rendered into a
   tailored resume, emphasizing the most relevant experience.
3. **Branding** — AI writes a personal branding statement specific to the
   company and role.
4. **Cover letter** — Generated from the research and tailored resume, so it
   references specific things about the company rather than generic platitudes.
5. **Annotations** — The job description is analyzed requirement by requirement,
   with each one mapped to your matching experience.
6. **FAQ** — AI generates role-specific questions and answers based on your
   background and the job requirements.
7. **Website** — Everything comes together in a self-contained landing page.
8. **PDF** — Resume and cover letter are converted to PDF via Pandoc.

Each step feeds into the next. The research informs the resume tailoring. The
resume informs the cover letter. The annotations and FAQ feed into the website.
It's a pipeline, not a collection of independent scripts.

Every application gets its own workspace directory organized by slug:

```
applications/acme-senior-dev/
├── job_description.md
├── job_details.yml
├── research.md
├── resume.md
├── cover_letter.md
├── branding.md
├── faq.json
├── job_description_annotations.json
├── status.log
└── website/
    └── index.html
```

For day-to-day use, there's also an interactive TUI mode. Running `jojo` with
no arguments launches a dashboard that shows all your applications, tracks which
steps are complete, detects when artifacts are stale (because you regenerated a
dependency), and lets you generate or regenerate individual steps with a
keypress. The staleness detection uses file modification times — if you
regenerate your research, the dashboard knows your resume is now stale because
it was built from the old research.

```
┌─ Jojo ────────────────────────────────────────────┐
│  Active: acme-senior-dev                          │
│  Company: Acme Corp  •  Role: Senior Developer    │
├───────────────────────────────────────────────────┤
│  Workflow                           Status        │
│  1. Job Description            $   ✓ Generated    │
│  2. Research                   $   ✓ Generated    │
│  3. Resume                     $   * Stale        │
│  4. Cover Letter               $   ○ Ready        │
│  ...                                              │
├───────────────────────────────────────────────────┤
│  [1-9] Generate item    [a] All ready    [q] Quit │
└───────────────────────────────────────────────────┘
```

The `$` indicator shows which steps call paid APIs, so you know if each action
will cost something before you press the key. Steps that just combine existing
artifacts (like website generation) are free.

## Architecture: the command pipeline

Jojo is about 5,400 lines of Ruby across ~50 source files. Every command follows
the same three-file pattern:

```
lib/jojo/commands/{command_name}/
├── command.rb    — Orchestration: validates inputs, manages file I/O
├── generator.rb  — Content generation: builds context, calls AI
└── prompt.rb     — AI prompts: system and user prompt templates
```

This structure is deliberate. When I needed to add the FAQ command, I created
three files, followed the pattern from the existing commands, and it worked.
I didn't have to modify a central router or understand the internals of
unrelated commands. The pattern makes the codebase predictable: if you've read
one command, you understand the shape of all of them.

This wasn't the original architecture. The CLI started as an 877-line monolith
in `cli.rb` — Thor command definitions mixed with validation logic, file
handling, and generation orchestration. It worked fine for the first few
commands. By the time I had twelve commands plus an interactive TUI mode, adding
a new feature meant navigating a single massive file and hoping your changes
didn't break something unrelated.

The refactor extracted each command into its own module with a shared base class
that provides common behavior (slug resolution, config loading, AI client
setup). The CLI file shrank to a thin router — about 150 lines of one-liner
methods that delegate to command classes. Interactive mode, which previously had
a circular dependency calling back into the CLI class, now calls command classes
directly through a simple adapter.

### Dual AI models

Jojo configures two AI models: a reasoning model for complex tasks and a text
generation model for simpler ones.

Company research and resume tailoring need the strongest reasoning capabilities
— they're analyzing job requirements, cross-referencing your experience, and
making judgment calls about relevance. But extracting metadata from a job
description (company name, location, job title) is straightforward. Using a
powerful model for that is like hiring a senior architect to hang shelves.

The reasoning model handles research, resume curation, and cover letter writing.
The text generation model handles job description processing, annotations, FAQ
generation, and branding statements. Both models are configurable per provider,
so you can use Anthropic's Claude for reasoning and a faster model for text
generation, or whatever combination suits your budget and quality needs.

## Solving the hallucination problem

This is a technical decision that came from a hard fail.

The original resume generation worked like this: take the user's resume data
(stored as structured YAML), combine it with the job description and research,
and ask the AI to generate a tailored resume in markdown. The prompt included
extensive instructions about not fabricating information. It said things like
"only include skills the candidate actually has" and "do not add technologies
not present in the source data."

The AI ignored these instructions about 15% of the time. I'd review a
generated resume and find "Kubernetes" listed in my skills because the AI
noticed I mentioned Docker and helpfully inferred I must know Kubernetes too.
Or it would embellish a job description with responsibilities I never had. For
some content, AI creativity is a feature. For a resume, it's a liability.

The first instinct was to add more guardrails to the prompt. More emphatic
instructions. More examples of what not to do. This helped a little, but it
didn't solve the problem — the AI still had the *ability* to modify anything,
and language-level instructions are suggestions, not constraints.

### The insight: different fields have different risk profiles

A professional summary should be rewritten for each role — that's the whole
point. But a list of programming languages must not be modified. The years you
worked at a company are facts. Your name is your name.

The problem was that "AI shouldn't have the same permissions everywhere." Some
fields need creative tailoring. Others need strict preservation. And there's a
spectrum in between.

### Permission-based curation

The solution was a permission system embedded directly in the resume data:

```yaml
name: "Tracy Atteberry"          # default: read-only
email: "tracy@example.com"       # default: read-only

summary: |                       # permission: rewrite
  Polyglot developer who enjoys solving problems
  with software...

skills:                          # permission: remove, reorder
  - software engineering
  - full stack development
  - AI assisted development

languages:                       # permission: reorder
  - Ruby
  - Java
  - Python
  - Go

experience:                      # permission: reorder
  - company: "BenchPrep"
    role: "Senior Software Engineer"
    start_date: "2020-07"        # read-only (nested)
    description: |               # permission: rewrite
      Full-stack developer delivering a SaaS platform...
    technologies:                # permission: remove, reorder
      - Ruby on Rails
      - Vue
      - Python
      - Docker
```

Four permission levels:

- **read-only** (default) — AI cannot modify, delete, add, or reorder. Contact
  info, dates, company names.
- **remove** — AI can exclude irrelevant items but can't modify the ones it
  keeps. A database list can drop SQLite if the role is all PostgreSQL.
- **reorder** — AI can prioritize by relevance but can't remove or modify. Your
  programming languages list stays complete but puts the most relevant ones
  first.
- **rewrite** — AI can generate new content using the original as a factual
  baseline. Professional summary, job descriptions.

The key constraint: AI can never *add* items that aren't in the source data.

### Two-pass pipeline

The curation happens in two passes:

**Pass 1: Filter and reorder.** The AI receives the full resume data and the
job description. It returns a filtered, reordered version — respecting the
permissions on each field. Skills marked `remove, reorder` get filtered to ~70%
of the most relevant items and sorted by relevance. Languages marked
`reorder` get sorted but all items are preserved.

**Pass 2: Rewrite safe fields.** The AI receives the filtered data and
generates new content for fields marked `rewrite` — the professional summary,
experience descriptions. It uses the original content as a factual baseline.

Then an ERB template renders the final markdown. The template handles structure
and formatting — the AI never touches the output format.

Here's what makes this work as an engineering solution: the Ruby code
*enforces* the permissions where possible. If the AI returns a reordered list
that's shorter than the original for a field that only has `reorder`
permission, the `Transformer` class raises a `PermissionViolation` error:

```ruby
unless can_remove
  if indices.length != original_count
    raise PermissionViolation,
      "LLM removed items from reorder-only field: #{field_path}"
  end
end
```

The permissions aren't just prompt instructions that the AI might ignore.
They're enforced in code. The AI provides *suggestions* for how to curate the
data, and the Ruby code validates those suggestions against the permission
rules before applying them. If the AI tries to exceed its permissions, the
operation fails rather than silently producing a resume with fabricated content.

The result: my skills section always contains skills I actually have. My job
dates are always accurate. But my professional summary is freshly written for
each role, emphasizing the experience most relevant to that specific position.

## What structured data enables

In order to make the permission system work, we had to switch from an unstructured
markdown resume to a structured YAML format. This was a significant
architectural change — it required reworking the entire resume generation
pipeline — but it was necessary to solve the hallucination problem.

The permission system is the most visible benefit of using structured data, but
there are other advantages:

- **Narrower AI focus** — With structured data, the AI can focus on curating specific
  fields rather than trying to parse and understand a free-form markdown
  document. This leads to better quality and more consistent results.
- **Better output control** — The ERB template handles formatting and
  structure, so the AI only generates content. This reduces the chances of
  formatting errors or hallucinated sections and increases the human control over
  the final output.
- **Easier testing** — Structured data is easier to work with in tests. You can
  create synthetic resume data with specific permissions and verify that the
  output respects those permissions. With unstructured markdown, it's harder to
  assert that the AI didn't add or modify content it shouldn't have.


## Testing as a development discipline

Jojo has 530 tests across two tiers, with 84% code coverage. Getting there was
a deliberate investment, not something that happened naturally.

AI coding assistants are enthusiastic about writing features. They're less
enthusiastic about writing tests. This mirrors human tendencies — tests aren't
as exciting as shipping the next feature — but with AI-accelerated development
the gap is amplified.

When the first large refactor was needed I noticed that test coverage was
sitting at 31%. The code worked, but I had no safety net for refactoring. The
push to 84% was a conscious decision to invest in change enablement.

### Three kinds of tests

Jojo has three kinds of tests:

| Kind of test...    | It tests...                   |
| ------------------ | ----------------------------- |
| Unit tests         | Do small units work?          |
| Inetegration tests | Do small units work together? |
| Linting            | Static code analysis          |

All tests run on every `./bin/test` (or `rake test:all`) invocation and in CI.

### Testing AI-dependent code

The trickiest part of testing Jojo is that a lot of the interesting work
involves AI API calls. You can't run those in CI without spending money on
every test run, but you also want tests that exercise real response parsing.

The solution was the VCR gem. VCR records real HTTP interactions the first
time a test runs and saves them as "cassettes." On subsequent runs, it replays
the recorded responses instead of making real API calls. You get fast,
deterministic tests that still exercise the full response-parsing pipeline.

### Fixture discipline

One rule that might seem like overkill but has saved me more than once: tests
(and AI) never touch the `inputs/` directory. That directory contains real
resume data — my actual work history, recommendations, and contact information.
Tests use `test/fixtures/` exclusively, with synthetic data designed for
testability.

This is codified in the project's AI guidelines, which was previously prone
to such mistakes. The instructions explicit, emphatic, and took few iterations
to be effective.

## Building with AI

There's a meta quality to this project: it's a tool that uses AI to generate
content, and it was built with AI assistance. Both
[Claude](https://claude.ai/code) and [Z](https://z.ai) helped with
development — not as novelties, but as daily tools throughout the process.

The project has 486 commits over about two months. For a hobby project, that's
not a bad pace. It's not a "built in a weekend" kind of pace, but it's faster than
the typical pace of a project of this scope without AI assistance.
AI is good at generating boilerplate, exploring design alternatives, writing
test cases, and automating the tedious parts of refactoring (like updating 50
files when you rename a class).

But the decisions this post is about — the curation system, the architecture,
the decision to refactor and when, the test organization — those were human
decisions. AI helped implement them a bit faster, but it didn't tell me they
were needed.

The most valuable part of AI-assisted development was arguably the ability to
explore approaches quickly. When I was designing the permission system, I could
describe three different architectures to Claude, brainstorm, and get working
prototypes of each in minutes, then evaluate them against real data. That kind
of rapid experimentation is transformative. The design thinking, however, still
has to be yours.

The least valuable part was trusting AI to know when to stop building features
and start testing. Also, let's be honest, the temptation to let the AI go a
little too long before reviewing its output. Left to its own devices, an AI
assistant will happily build feature after feature, each one working in
isolation, with no test coverage and growing technical debt. Just like a human
developer on a deadline, it needs someone to say "we're not adding anything
else until we address the technical debt, and that includes tests."

## What I learned and what's next

A few things I'd do differently if I started over:

**Start with structured data sooner.** The original design used a free-form
markdown resume as input. This worked fine until I needed to curate individual
fields — you can't set permissions on a paragraph of markdown. The switch to
structured YAML data (`resume_data.yml`) was the right call, but it required
reworking the entire resume generation pipeline. If I'd started with structured
data, the permission system would have been a natural extension rather than a
redesign.

**Build the interactive mode earlier.** The TUI dashboard made the tool
dramatically more usable, but it came in Phase 6 out of 7. Earlier access to
the dependency graph and staleness detection would have improved my own
workflow during development.

**Force TDD from the start, or very near it.** I had a test suite from the
beginning, but it wasn't until I hit a major refactor that I made a conscious
decision to invest in test coverage. If I had enforced TDD from the start, I
would have had a safety net for refactoring much earlier, which would have made
the architecture more flexible and reduced the risk of breaking things when
adding features.

Basically, I would have spent a lot more time up front on planning the
architecture and testing strategy, which would have made the development
process smoother and more maintainable. AI assistance can be great, but
it's also really good at seducing you into bad habits.

### What's next

A few potential things for the roadmap:

- **Interview prep generation** — STAR-method examples drawn from your resume
  data, tailored to the specific role
- **Direct Hugo integration** — Generate pages directly into a Hugo site
  structure instead of copying static files
- **Application tracking** — Status tracking across all applications with dates,
  notes, and follow-up reminders
- **Full SaaS product** — A Rails app version of Jojo with a user-friendly interface
  and full job search management features — this would be a much bigger project
  but could help a wider audience.

### Try it out

Jojo is open source and available on [GitHub](https://github.com/grymoire7/jojo).
It's a Ruby CLI that requires an AI provider API key (Anthropic, OpenAI, or
others via the [RubyLLM](https://github.com/crmne/ruby_llm) gem). Setup takes
about five minutes.

If you're interested in the code, the architecture, or just want to talk about
AI-assisted development, I'd enjoy hearing from you. You can find me on
[LinkedIn](https://linkedin.com/in/tracyatteberry) or [Mastodon](https://mastodon.social/@grymoire7).

