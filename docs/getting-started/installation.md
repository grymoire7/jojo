---
title: Installation
parent: Getting Started
nav_order: 1
---

# Installation

## Prerequisites

- **Ruby 3.4.5** — Install via [rbenv](https://github.com/rbenv/rbenv) or your preferred Ruby version manager
- **Bundler** — Install with `gem install bundler`
- **AI Provider API Key** — Jojo supports all providers available through [RubyLLM](https://rubyllm.com/available-models/) (Anthropic, OpenAI, Gemini, etc.)
- **Search API Key** — For web research capabilities:
  - [Serper](https://serper.dev/) API key, or
  - [Tavily](https://tavily.com/) API key
- **Pandoc** (optional) — For PDF generation: `brew install pandoc` on macOS

## Install Jojo

1. Clone the repository:

   ```bash
   git clone https://github.com/grymoire7/jojo.git
   cd jojo
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Run setup:

   ```bash
   ./bin/jojo setup
   ```

   The setup wizard guides you through provider selection, API key configuration, and model selection. See the [setup command](../commands/setup) for details.

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
