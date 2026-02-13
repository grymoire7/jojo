---
title: setup
parent: Commands
nav_order: 2
---

# jojo setup

Interactive setup wizard for first-time configuration.

## Usage

```bash
./bin/jojo setup [--overwrite]
```

## Options

| Option | Description |
|--------|-------------|
| `--overwrite` | Recreate configuration files even if they already exist |

## Outputs

| File | Description |
|------|-------------|
| `.env` | API key for your chosen provider |
| `config.yml` | User configuration (models, permissions, website settings) |
| `inputs/resume_data.yml` | Structured resume data template |
| `inputs/templates/default_resume.md.erb` | Resume rendering template |

## Example

```
$ ./bin/jojo setup

Which LLM provider? (Use ↑/↓ arrow keys, press Enter to select)
‣ anthropic
  bedrock
  deepseek
  gemini
  ...

Anthropic API key: sk-ant-***

Your name: Tracy Atteberry
Your website base URL: https://tracyatteberry.com

Which model for reasoning tasks (company research, resume tailoring)?
‣ claude-sonnet-4-5
  claude-opus-4-5
  claude-3-5-sonnet-20241022
  ...
```

{: .note }
The setup command is idempotent — you can run it multiple times safely. It only creates missing files. Use `--overwrite` to recreate existing files.
