---
title: Commands
nav_order: 3
has_children: true
---

# Commands

## Overview

| Command | Description | Required Options |
|---------|-------------|------------------|
| [`jojo setup`](setup) | Interactive setup wizard for first-time configuration | None |
| [`jojo new`](new) | Create application workspace and process job description | `-s`, `-j` |
| [`jojo generate`](generate) | Generate all materials in sequence | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo research`](research) | Generate company/role research only | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo resume`](resume) | Generate tailored resume only | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo cover_letter`](cover-letter) | Generate cover letter only | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo annotate`](annotate) | Generate annotated job description | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo branding`](branding) | Generate AI branding statement | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo faq`](faq) | Generate FAQ content | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo website`](website) | Generate landing page | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo pdf`](pdf) | Generate PDF versions of resume and cover letter | `-s` or `JOJO_APPLICATION_SLUG` |
| [`jojo interactive`](interactive) | TUI dashboard mode | None |
| `jojo version` | Show version | None |
| `jojo help [COMMAND]` | Show help | None |

## Global options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (unique identifier for the job application) |
| `-t, --template TEMPLATE` | Website template name (default: `"default"`) |
| `-v, --verbose` | Run verbosely with detailed output |
| `-q, --quiet` | Suppress output, rely on exit code only |
| `--overwrite` | Overwrite existing files without prompting |
| `--no-overwrite` | Always prompt before overwriting files |

## Environment variables

| Variable | Description |
|----------|-------------|
| `JOJO_APPLICATION_SLUG` | Set this to avoid repeating `--slug` for every command |
| `JOJO_ALWAYS_OVERWRITE` | Set to `true`, `1`, or `yes` to skip overwrite prompts |

## Overwrite precedence

When a command would overwrite an existing file, Jojo follows this precedence:

1. `--overwrite` flag — always overwrites
2. `--no-overwrite` flag — always prompts
3. `JOJO_ALWAYS_OVERWRITE=true` — overwrites
4. Default — prompts
