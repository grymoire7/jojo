---
title: Configuration
parent: Getting Started
nav_order: 2
---

# Configuration

## Environment variables

The `jojo setup` command creates a `.env` file with your provider-specific API key:

```bash
# For Anthropic
ANTHROPIC_API_KEY=your_api_key_here

# For OpenAI
OPENAI_API_KEY=your_api_key_here

# For other providers, the env var name depends on your chosen provider

# Optional: for web search during research
SERPER_API_KEY=your_serper_key_here
```

## User configuration

After running `./bin/jojo setup`, edit `config.yml` to customize:

```yaml
seeker_name: Your Name
base_url: https://yourwebsite.com/applications

reasoning_ai:
  service: anthropic           # Your chosen provider
  model: claude-sonnet-4-5     # For complex reasoning tasks

text_generation_ai:
  service: anthropic           # Your chosen provider
  model: claude-3-5-haiku-20241022  # Faster for simple tasks

voice_and_tone: professional and friendly

website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"

# Resume data transformation permissions
resume_data:
  permissions:
    skills: [remove, reorder]
    databases: [remove, reorder]
    tools: [remove, reorder]
    recommendations: [remove]
    experience: [reorder]
    projects: [reorder]
    languages: [reorder]
    summary: [rewrite]
    experience.description: [rewrite]
    education.description: [rewrite]
    experience.technologies: [remove, reorder]
    experience.tags: [remove, reorder]
    projects.skills: [reorder]
```

See the [customizing your resume](../guides/customizing-resume) guide for a deep dive into permissions.

## Supported LLM providers

Jojo supports providers via [RubyLLM](https://rubyllm.com/available-models/) including:

| Provider | Notes |
|----------|-------|
| **Anthropic** | Claude models |
| **OpenAI** | GPT models |
| **DeepSeek** | |
| **Google Gemini** | |
| **Mistral** | |
| **OpenRouter** | |
| **Perplexity** | |
| **Ollama** | Local models |
| **AWS Bedrock** | |
| **Google Vertex AI** | |
| **GPUStack** | |

To switch providers, run `jojo setup --overwrite` or manually edit `config.yml` and `.env`.

## Input files

The setup command creates these files in `inputs/`:

### `inputs/resume_data.yml` (required)

Structured resume data in YAML format containing your complete work history, skills, experience, and projects. Permissions in `config.yml` control which fields can be filtered, reordered, or rewritten for each job.

Delete the first comment line after customizing — Jojo warns you if templates are unchanged.

### `inputs/templates/default_resume.md.erb`

ERB template used to render `resume_data.yml` into markdown. Customize to change how your resume is formatted.

### `inputs/recommendations.md` (optional)

LinkedIn recommendations used in the website carousel. Delete the file if you don't want recommendations.

{: .note }
The `inputs/` directory is gitignored, so your personal information stays private.
