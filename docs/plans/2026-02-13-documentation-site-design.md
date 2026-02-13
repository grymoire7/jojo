# Documentation Site Design

**Date:** 2026-02-13
**Status:** APPROVED

## Purpose

Create a comprehensive Jekyll documentation site for Jojo that serves dual audiences:
1. **End users** (job seekers) who want to use Jojo for their job search
2. **Developers/employers** evaluating the engineering quality as a portfolio piece

The site replaces the README as the canonical documentation source. The README will be slimmed down to a concise project overview with links to the docs site.

## Approach

Flat navigation using `just-the-docs` parent/child page ordering (`nav_order` front matter). All pages live in the `docs/` root or shallow subdirectories. No Jekyll collections or custom plugins beyond what's already configured.

## Site Structure

```
Home (index.md)                          nav_order: 1
Getting Started/                         nav_order: 2
  ├── Installation                         nav_order: 1
  ├── Configuration                        nav_order: 2
  └── Quick Start                          nav_order: 3
Commands/                                nav_order: 3
  ├── Overview                             nav_order: 1
  ├── setup                                nav_order: 2
  ├── new                                  nav_order: 3
  ├── generate                             nav_order: 4
  ├── research                             nav_order: 5
  ├── resume                               nav_order: 6
  ├── cover-letter                         nav_order: 7
  ├── annotate                             nav_order: 8
  ├── branding                             nav_order: 9
  ├── faq                                  nav_order: 10
  ├── website                              nav_order: 11
  ├── pdf                                  nav_order: 12
  └── interactive                          nav_order: 13
Guides/                                  nav_order: 4
  ├── Your First Application               nav_order: 1
  ├── Customizing Your Resume              nav_order: 2
  └── Website Templates                    nav_order: 3
Architecture/                            nav_order: 5
  ├── Overview                             nav_order: 1
  └── Key Decisions                        nav_order: 2
Examples/                                nav_order: 6
  ├── Configuration                        nav_order: 1
  └── Resume Data                          nav_order: 2
```

### File Layout

```
docs/
├── index.md
├── getting-started/
│   ├── installation.md
│   ├── configuration.md
│   └── quick-start.md
├── commands/
│   ├── index.md
│   ├── setup.md
│   ├── new.md
│   ├── generate.md
│   ├── research.md
│   ├── resume.md
│   ├── cover-letter.md
│   ├── annotate.md
│   ├── branding.md
│   ├── faq.md
│   ├── website.md
│   ├── pdf.md
│   └── interactive.md
├── guides/
│   ├── first-application.md
│   ├── customizing-resume.md
│   └── website-templates.md
├── architecture/
│   ├── overview.md
│   └── key-decisions.md
└── examples/
    ├── configuration.md
    └── resume-data.md
```

## Page Content

### Home (index.md)

Hero description of Jojo: what it does, why it exists (treating each job application as a product launch). High-level workflow diagram using mermaid. Links into Getting Started.

### Getting Started

- **Installation** - Prerequisites (Ruby 3.4+, Bundler, optional Pandoc), clone & bundle install, verify with `./bin/jojo version`.
- **Configuration** - `config.yml` structure, `.env` setup, AI provider selection (11+ providers supported), search provider setup, resume data permissions system.
- **Quick Start** - End-to-end walkthrough: setup, new, generate. Expected output at each step.

### Commands

- **Overview** - Summary table (migrated from existing `commands.md`), global options (`-s`, `-v`, `-q`, `--overwrite`), environment variables (`JOJO_APPLICATION_SLUG`, `JOJO_ALWAYS_OVERWRITE`).
- **Per-command pages** - Each follows a consistent template: description, usage syntax, options, inputs (files read), outputs (files generated), examples.

### Guides

- **Your First Application** - Narrative walkthrough creating a real application from scratch, explaining what happens at each step and why.
- **Customizing Your Resume** - Deep dive into the permissions system (`remove`, `reorder`, `rewrite`), how AI curation works, field-level control examples.
- **Website Templates** - How the template system works, default template features (masthead, portfolio, recommendations carousel, annotated job description, FAQ accordion), creating custom templates.

### Architecture

- **Overview** - System architecture diagram, command pipeline pattern (command.rb, generator.rb, prompt.rb), dual AI model strategy, directory structure.
- **Key Decisions** - Permission-based resume curation rationale, dual model approach (reasoning vs text generation), template system design, status logging as audit trail, web search integration strategy.

### Examples

- **Configuration** - Annotated `config.yml` with explanations of each section (migrated from `examples/config_permissions_example.yml`).
- **Resume Data** - Annotated `resume_data.yml` showing the schema with explanations (migrated from `examples/resume_data_example.yml`).

## Jekyll Configuration Changes

Update `_config.yml`:
- `title`: "Jojo Documentation"
- `description`: Proper project description
- `aux_links`: Point to actual Jojo GitHub repo
- Remove placeholder values (`email`, `twitter_username`, `github_username`)
- Keep `plans/` excluded from build
- Keep mermaid plugin

## GitHub Pages Setup

Add `.github/workflows/pages.yml` for GitHub Actions deployment:
- Trigger on push to main (docs path changes)
- Build Jekyll from `docs/` subdirectory
- Deploy to GitHub Pages
- Uses `<username>.github.io/<repo>` URL initially

## Cleanup

- Remove `_posts/2026-02-09-welcome-to-jekyll.markdown` (boilerplate)
- Remove `about.markdown` (boilerplate)
- Replace existing `commands.md` with `commands/` directory structure
- Update `404.html` with project-appropriate messaging

## README Changes

Slim down `README.md` to:
- Project name and one-line description
- Status badges (if applicable)
- Brief "what is Jojo" paragraph
- Link to documentation site
- Quick install snippet
- Contributing section
- License

All detailed content (installation, configuration, usage, troubleshooting, architecture) moves to the docs site.
