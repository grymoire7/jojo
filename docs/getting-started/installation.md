---
title: Installation
parent: Getting Started
nav_order: 1
---

# Installation

## Prerequisites

- **Ruby 3.4.5** — Install via [rbenv](https://github.com/rbenv/rbenv) or [mise](https://mise.jdx.dev/) before running setup
- **AI Provider API Key** — Jojo supports all providers available through [RubyLLM](https://rubyllm.com/available-models/) (Anthropic, OpenAI, Gemini, etc.)
- **Search API Key** (optional) — For web research capabilities:
  - [Serper](https://serper.dev/) API key, or
  - [Tavily](https://tavily.com/) API key

## Install Jojo

1. Clone the repository:

   ```bash
   git clone https://github.com/grymoire7/jojo.git
   cd jojo
   ```

2. Run the bootstrap script:

   ```bash
   ./bin/setup
   ```

   This installs Ruby gems, npm packages, and checks for optional system dependencies
   (pandoc and wkhtmltopdf for PDF export — offering to install them if missing). It then
   runs the configuration wizard to set up your API keys and preferences.
   See the [configure command](../commands/configure) for details on the configuration wizard.

## Verify installation

```bash
./bin/jojo version
```

## API costs

Jojo uses AI providers to generate application materials. Actual costs vary based on:

- AI provider and model selection
- Length of your resume and job description
- Amount of research content generated
- Number of projects in your portfolio

See your provider's pricing page for current rates.
