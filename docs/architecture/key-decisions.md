---
title: Key Decisions
parent: Architecture
nav_order: 2
---

# Key Decisions

## Permission-based resume curation

**Decision:** Use a permissions system to control how AI modifies resume data, rather than letting AI freely rewrite the entire resume.

**Alternatives considered:**
- Free-form AI rewriting of the entire resume
- Manual editing for each application
- Template-based fill-in-the-blank approach

**Rationale:** Granular permissions give you control over what changes. Factual data (dates, company names, contact info) stays untouched while allowing AI to filter, reorder, and reword specific fields. This balances personalization with data integrity and produces predictable, reviewable results.

## Dual AI models

**Decision:** Configure two separate AI models — a reasoning model for complex tasks and a text generation model for simpler tasks.

**Alternatives considered:**
- Single model for everything
- Per-command model configuration
- Auto-selection based on task complexity

**Rationale:** Company research and resume tailoring benefit from the strongest reasoning capabilities, but job description processing and metadata extraction don't need that power. Using a faster, cheaper model for simple tasks reduces cost and latency without sacrificing quality where it matters. Two models is the right granularity — per-command would be over-engineered.

## Command pipeline pattern

**Decision:** Every command follows the same `command.rb` / `generator.rb` / `prompt.rb` structure.

**Alternatives considered:**
- Monolithic command classes
- Plugin/middleware architecture
- Configuration-driven pipeline

**Rationale:** Consistent structure makes the codebase predictable. Adding a new command means creating three files following an established pattern. Separation of orchestration (command), content generation (generator), and AI interaction (prompt) keeps each file focused and testable.

## Status logging

**Decision:** Write a JSON Lines audit trail (`status_log.md`) for every generation step.

**Alternatives considered:**
- No logging (just output files)
- Verbose stdout logging
- Structured database

**Rationale:** JSON Lines format provides a machine-readable audit trail for debugging, cost tracking, and process verification without requiring a database. Each line is a self-contained record, making it easy to grep and analyze. The log lives alongside the application files for easy access.

## Web search integration

**Decision:** Make web search optional with graceful degradation, supporting multiple search providers.

**Alternatives considered:**
- Required web search
- Built-in web scraping
- No web search (AI knowledge only)

**Rationale:** Web search enriches company research significantly, but not everyone has a search API key and search APIs have costs. Graceful degradation means the tool works without it — research is generated from the job description alone. Supporting multiple providers (Serper, Tavily) avoids vendor lock-in.

## Template system

**Decision:** Use ERB templates for website generation, producing self-contained HTML files.

**Alternatives considered:**
- Static site generator (Jekyll, Hugo)
- React/Vue SPA
- Markdown-to-HTML conversion

**Rationale:** ERB templates provide maximum flexibility with minimal dependencies. Self-contained HTML means the landing page works anywhere — drop it on any web server, no build step needed. This matches the use case: one page per application, deployed to a personal site.
