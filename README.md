# JoJo - Job Search Management System

✨ A new way to present yourself to a prospective employer, beyond the resume ✨

![Tests](https://github.com/grymoire7/jojo/actions/workflows/ruby.yml/badge.svg?branch=main)
![Ruby Version](https://img.shields.io/badge/Ruby-3.4.5-green?logo=Ruby&logoColor=red&label=Ruby%20version&color=green)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/grymoire7/jojo/blob/main/LICENSE.txt)

## What is this?

JoJo is a Ruby CLI that transforms job applications into comprehensive,
personalized marketing campaigns. Instead of sending a generic resume and cover
letter, JoJo generates:

- **Tailored resume**: Customized from your generic resume data to match specific job requirements
- **Persuasive cover Letter**: Written based on company research and role analysis
- **Company research**: AI-generated insights about the company and role
- **Professional website**: Landing page selling you as the perfect candidate
  - **Job description annotations**: Analysis of how your experience matches requirements
  - **Project portfolio**: Showcase relevant projects with descriptions and links
  - **Recommendations carousel**: Display LinkedIn recommendations to build credibility
  - **FAQ section**: Address common questions (again, a tailored component) proactively
  - **Call-to-action**: Encourage employers to schedule calls or reach out

```mermaid
flowchart LR

A[Resume data] --> J(Jojo)
B[Job description] --> J
J --> C[Tailored resume]
J --> D[Tailored cover letter]
J --> E[Marketing website]
J --> F[Compnay research]
```

Think of it as treating each job application like launching a product (you) to
a specific customer (the employer).

**[Read the technical blog post](https://tracyatteberry.com/posts/jojo)** about building this tool with Claude AI assistance.

## Table of contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Architecture](#architecture)
- [Development workflow](#development-workflow)

## Prerequisites

- **Ruby 3.4.5** - Install via rbenv or your preferred Ruby version manager
- **Bundler** - Install with `gem install bundler`
- **AI Provider API Key** - Get one from your chosen provider
  - Jojo supports all providers supported by [ruby_llm](https://rubyllm.com/available-models/)
- **Search API Key** - For web research capabilities via [DeepSeek](https://github.com/alexshagov/deepsearch-rb)
  - Get a Serper API key from [serper.dev](https://serper.dev/), or
  - Get a Tavily API key from [tavily.com](https://tavily.com/)
- **Pandoc** (optional) - For PDF generation: `brew install pandoc` on macOS

### API Costs

JoJo uses AI providers to generate application materials. You can configure any
provider supported by [ruby_llm](https://github.com/crmne/ruby_llm) (Anthropic,
OpenAI, etc.) in your `config.yml`.

Actual costs vary based on:
- AI provider and model selection
- Length of your resume and job description
- Amount of research content generated
- Number of projects in your portfolio

See your provider's pricing page for current rates.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/grymoire7/jojo.git
   cd jojo
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Run setup (creates .env, config.yml, and input templates):
   ```bash
   ./bin/jojo setup
   ```

   The setup wizard will guide you through:
   - **LLM Provider Selection**: Choose from 11 supported providers using arrow keys
   - **API Key Configuration**: Provide your API key for the chosen provider
   - **Model Selection**: Choose reasoning and text generation models using arrow keys
   - **Personal Information**: Your name and website URL
   - **Template Files**: Creates resume data template and recommendations template

   **Example:**
   ```
   Which LLM provider? (Use ↑/↓ arrow keys, press Enter to select)
   ‣ anthropic
     bedrock
     deepseek
     gemini
     ...
     vertexai

   Anthropic API key: sk-ant-***

   Your name: Tracy Atteberry
   Your website base URL: https://tracyatteberry.com

   Which model for reasoning tasks (company research, resume tailoring)?
   ‣ claude-sonnet-4-5
     claude-opus-4-5
     claude-3-5-sonnet-20241022
     claude-3-5-haiku-20241022
     ...
   ```

**Note**: The setup command is idempotent - you can run it multiple times safely. It only creates missing files.

## Configuration

### Environment Variables

The setup command creates `.env` with your provider-specific API key. You can edit it directly if needed:

```bash
# For Anthropic
ANTHROPIC_API_KEY=your_api_key_here

# For OpenAI
OPENAI_API_KEY=your_api_key_here

# For other providers (deepseek, gemini, mistral, etc.)
# The env var name depends on your chosen provider

SERPER_API_KEY=your_serper_key_here  # Optional, for web search
```

### User Configuration

After running `./bin/jojo setup`, you can edit `config.yml` to customize:

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
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com

# Resume data transformation permissions
# Controls how resume_data.yml is curated for each job opportunity
resume_data:
  permissions:
    # Array fields that can be filtered and reordered
    skills: [remove, reorder]
    databases: [remove, reorder]
    tools: [remove, reorder]
    recommendations: [remove]

    # Array fields that can only be reordered (all items preserved)
    experience: [reorder]
    projects: [reorder]
    languages: [reorder]

    # Text fields that can be rewritten to emphasize relevant experience
    summary: [rewrite]
    experience.description: [rewrite]
    education.description: [rewrite]

    # Nested array fields
    experience.technologies: [remove, reorder]
    experience.tags: [remove, reorder]
    projects.skills: [reorder]
```

### Supported LLM Providers

Jojo supports LLM providers via [RubyLLM](https://rubyllm.com/available-models/) including:

- **Anthropic** (Claude models)
- **OpenAI** (GPT models)
- **DeepSeek**
- **Google Gemini**
- **Mistral**
- **OpenRouter**
- **Perplexity**
- **Ollama** (local models)
- **AWS Bedrock**
- **Google Vertex AI**
- **GPUStack**

To switch providers, run `jojo setup --overwrite` or manually edit your `config.yml` and `.env` files.

### Input Files

The setup command creates these files in `inputs/` with example content:

1. **`inputs/resume_data.yml`** - Structured resume data (required)
   - YAML format containing your complete work history, skills, experience, and projects
   - Used with config-based permissions for intelligent resume curation
   - Permissions in `config.yml` control which fields can be filtered, reordered, or rewritten
   - Includes your projects as part of the structured data
   - **Delete the first comment line after customizing**

2. **`inputs/templates/default_resume.md.erb`** - Resume rendering template
   - ERB template used to render `resume_data.yml` into markdown
   - Customize to change how your resume is formatted
   - Uses standard ERB syntax with resume data fields as variables

3. **`inputs/recommendations.md`** (optional) - LinkedIn recommendations
   - Used in website carousel
   - Delete file if you don't want recommendations

**Important**: The first line of each template file contains a marker comment. Delete this line after you customize the file - jojo will warn you if templates are unchanged.

## Quick start

### Step 0: Run setup

If you haven't already, run setup to create your configuration and input files:

```bash
./bin/jojo setup
```

Then customize your input files:

1. **Edit your structured resume data** (required):
   ```bash
   nvim inputs/resume_data.yml  # or your preferred editor
   ```
   Replace the example content with your actual experience, skills, projects, and achievements.
   The config-based permissions in `config.yml` control how this data is curated for each job.
   **Delete the first comment line** when done.

2. **(Optional) Customize the resume template**:
   ```bash
   nvim inputs/templates/default_resume.md.erb
   ```
   Customize how your resume is rendered from the structured data.

3. **(Optional) Customize or delete recommendations**:
   ```bash
   nvim inputs/recommendations.md
   # Or delete: rm inputs/recommendations.md
   ```

**Note**: The `inputs/` directory is gitignored, so your personal information stays private.

### Step 1: Create employer workspace

First, create a workspace for the employer by processing their job description.

#### Choosing a Slug

The slug is a unique identifier for each job application. It's used to organize your files and reference the application in commands.

**Format guidelines:**
- Use lowercase letters, numbers, and hyphens only
- No spaces or special characters
- Keep it concise but descriptive
- Include company name and role

**Good examples:**
```
acme-corp-senior-dev       # Company + seniority + role
bigco-principal-eng        # Short company name + level + role
startup-fullstack-2024     # Include year if applying multiple times
tech-inc-lead-backend      # Company + level + specialty
```

**Avoid:**
```
ACME_Corp_Senior           # Use lowercase and hyphens, not underscores
acme                       # Too vague, which role?
acme-corp-senior-software-development-engineer  # Too long
```

#### Creating the workspace

Once you've chosen a slug, create the workspace:

```bash
./bin/jojo new \
  --slug acme-corp-senior-dev \
  --job job_description.txt
```

You can also provide a URL for the job description:

```bash
./bin/jojo new \
  --slug acme-corp-senior-dev \
  --job "https://careers.acmecorp.com/jobs/123"
```

This creates `employers/acme-corp-senior-dev/` with:
- `job_description.md` - Processed job description
- `job_details.yml` - Extracted metadata (company name, title, etc.)

### Step 2: Generate application materials

```bash
./bin/jojo generate --slug acme-corp-senior-dev
```

Or set the environment variable to avoid repeating the slug:

```bash
export JOJO_EMPLOYER_SLUG=acme-corp-senior-dev
./bin/jojo generate
```

This generates:
- `research.md` - Company and role research
- `resume.md` - Tailored resume
- `cover_letter.md` - Personalized cover letter
- `resume.pdf` - PDF version of resume (requires Pandoc)
- `cover_letter.pdf` - PDF version of cover letter (requires Pandoc)
- `job_description_annotations.json` - Analysis of job requirements
- `website/index.html` - Landing page
- `status_log.md` - Process log (JSON Lines format)

## Usage

### Workflow

1. **Find a job** you want to apply for
2. **Save job description** as a file or copy the URL
3. **Create employer workspace** with `jojo new -s <slug> -j <job-description>`
4. **Generate materials** with `jojo generate -s <slug>` (or set `JOJO_EMPLOYER_SLUG`)
5. **Review generated materials** in `employers/<slug>/`
6. **Customize as needed** - edit the markdown files
7. **Deploy website** to your personal site
8. **Apply** with tailored resume, cover letter, and website link

### Step-by-Step Commands

For more control, run individual steps:

```bash
# 1. Create employer workspace (required first step)
./bin/jojo new -s acme-corp-senior-dev -j job_desc.txt

# Set environment variable to avoid repeating slug (optional)
export JOJO_EMPLOYER_SLUG=acme-corp-senior-dev

# 2. Generate company research
./bin/jojo research

# 3. Generate tailored resume
./bin/jojo resume

# 4. Generate cover letter
./bin/jojo cover_letter

# 5. Generate annotated job description
./bin/jojo annotate

# 6. Generate website
./bin/jojo website

# 7. Generate PDF versions (requires Pandoc)
./bin/jojo pdf
```

### Using Environment Variables

To avoid repeating the `--slug` flag for every command, set the `JOJO_EMPLOYER_SLUG` environment variable:

```bash
# Set for the current shell session
export JOJO_EMPLOYER_SLUG=acme-corp-senior-dev

# Now you can omit --slug from all commands
./bin/jojo research
./bin/jojo resume
./bin/jojo cover_letter
./bin/jojo website
./bin/jojo generate
```

**When to use environment variables:**
- ✅ Working on multiple commands for the same employer
- ✅ Running the full generation workflow step-by-step
- ✅ Iterating on materials (regenerating resume, website, etc.)

**When to use the `--slug` flag:**
- ✅ One-off commands for different employers
- ✅ Switching between multiple applications
- ✅ Scripts or automation where explicit is better

**Tip**: Add the export to your shell's RC file (`.bashrc`, `.zshrc`) to persist across sessions:
```bash
# In ~/.zshrc or ~/.bashrc
export JOJO_EMPLOYER_SLUG=acme-corp-senior-dev
```

## Commands

| Command | Description | Required Options |
| ------- | ----------- | ---------------- |
| `jojo setup` | Create configuration file | None |
| `jojo new` | Create employer workspace and process job description | `-s`, `-j` |
| `jojo generate` | Generate all materials (research, resume, cover letter, website) | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo research` | Generate company/role research only | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo resume` | Generate tailored resume only | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo cover_letter` | Generate cover letter only | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo annotate` | Generate annotated job description | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo website` | Generate website only | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo pdf` | Generate PDF versions of resume and cover letter | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo test` | Run test suite | None |
| `jojo version` | Show version | None |
| `jojo help [COMMAND]` | Show help | None |

### Global Options

- `-s, --slug SLUG` - Employer slug (unique identifier for the job application)
- `-t, --template TEMPLATE` - Website template name (default: "default")
- `-v, --verbose` - Run verbosely with detailed output
- `-q, --quiet` - Suppress output, rely on exit code only
- `--overwrite` - Overwrite existing files without prompting
- `--no-overwrite` - Always prompt before overwriting files

### Overwriting Files

By default, jojo prompts before overwriting existing files:

```bash
./bin/jojo research --slug acme-corp
# If research.md exists: "research.md exists. Overwrite? (y/n)"
```

To skip prompts and overwrite automatically:

```bash
# Using flag
./bin/jojo research --slug acme-corp --overwrite

# Using environment variable (useful for CI/CD)
export JOJO_ALWAYS_OVERWRITE=true
./bin/jojo generate --slug acme-corp

# Force prompting even with env var set
./bin/jojo research --slug acme-corp --no-overwrite
```

**Precedence order:**
1. `--overwrite` flag → always overwrites
2. `--no-overwrite` flag → always prompts
3. `JOJO_ALWAYS_OVERWRITE=true` → overwrites
4. Default → prompts

### Custom Templates

JoJo supports custom website templates via the `--template` flag. The default template is a clean, professional single-page design.

**Using custom templates:**

```bash
# Use a custom template
./bin/jojo website -s acme-corp-senior-dev -t modern

# Or with generate command
./bin/jojo generate -s acme-corp-senior-dev -t modern
```

**Creating custom templates:**

Templates are ERB files located in `templates/website/`. To create a custom template:

1. Create a new template file:
   ```bash
   cp templates/website/default.html.erb templates/website/modern.html.erb
   ```

2. Edit the template with your custom HTML/CSS
3. Use these available template variables:
   - `<%= seeker_name %>` - Your name from config
   - `<%= company_name %>` - Company from job details
   - `<%= job_title %>` - Job title from job details
   - `<%= branding_statement %>` - AI-generated branding (HTML)
   - `<%= cta_text %>` - Call-to-action text from config
   - `<%= cta_link %>` - Call-to-action link from config
   - `<%= branding_image %>` - Path to branding image (if exists)
   - `<%= projects %>` - Array of selected projects
   - `<%= recommendations %>` - Array of recommendations
   - `<%= faqs %>` - Array of FAQ objects
   - `<%= annotated_job_description %>` - Annotated job description HTML

4. Reference your custom template:
   ```bash
   ./bin/jojo website -s acme-corp -t modern
   ```

**Note**: Templates should be self-contained HTML files with inline CSS. External stylesheets and JavaScript files are not currently supported.

### Environment Variables

- `JOJO_EMPLOYER_SLUG` - Set this to avoid repeating `--slug` flag for commands
- `JOJO_ALWAYS_OVERWRITE` - Set to `true`, `1`, or `yes` to skip overwrite prompts

### Examples

```bash
# Create a new employer workspace
./bin/jojo new -s acme-corp-senior -j job_posting.txt

# From URL
./bin/jojo new -s tech-startup-eng -j "https://example.com/careers/senior-dev"

# Generate everything for that employer
./bin/jojo generate -s acme-corp-senior

# Using environment variable to avoid repeating slug
export JOJO_EMPLOYER_SLUG=acme-corp-senior
./bin/jojo generate

# Verbose mode for debugging
./bin/jojo generate -v -s bigco-staff

# Just update the website after editing resume
./bin/jojo website -s acme-corp-senior

# Generate only research to decide if you want to apply
export JOJO_EMPLOYER_SLUG=acme-corp-senior
./bin/jojo research
```

## Troubleshooting

### Pandoc not found

If you see "Pandoc is not installed" when running `jojo pdf` or `jojo generate`:

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc

# Fedora/RHEL
sudo yum install pandoc

# Verify installation
pandoc --version
```

**Note**: PDF generation is optional. If Pandoc is not installed, `jojo generate` will skip PDF generation with a warning but continue successfully.

### API errors

If you encounter API-related errors:

- **Check your API key**: Verify it's correct in your `.env` file
- **Verify API credits**: Check your account at your provider's console (e.g., https://console.anthropic.com/)
- **Check internet connection**: Ensure you have network connectivity
- **Rate limiting**: If you see rate limit errors, wait a few minutes and try again

### Tests failing

```bash
# Run different test categories to isolate issues
./bin/jojo test --unit           # Fast unit tests
./bin/jojo test --integration    # Integration tests
./bin/jojo test --service        # Service tests (real API calls that cost money)
./bin/jojo test --standard       # Code style checks
./bin/jojo test --all            # All tests (includes service tests)

# Run with verbose output
./bin/jojo test --all -v
```

## Testing

Jojo includes comprehensive testing to ensure reliability and performance.

### Test Categories

- **Unit tests** - Fast tests with no external dependencies (default)
- **Integration tests** - Tests with mocked external services
- **Service tests** - Tests that make real API calls (may incur costs)
- **Standard tests** - Code style checks using Standard Ruby

### Running Tests

```bash
# Run unit tests (fast, default)
./bin/jojo test

# Run all tests (including service tests)
./bin/jojo test --all

# Run specific categories
./bin/jojo test --unit --integration
./bin/jojo test --service  # Requires confirmation

# Quiet mode (CI-friendly)
./bin/jojo test --unit --integration --standard -q
```

Service tests require real API keys and may cost money. You'll be prompted for confirmation unless `SKIP_SERVICE_CONFIRMATION=true` is set in your environment.

## Architecture

JoJo is built as a modular Ruby CLI application:

### Core Components

- **CLI Layer** (`lib/jojo/cli.rb`) - Thor-based command interface
- **Configuration** (`lib/jojo/config.rb`) - User settings management
- **Employer** (`lib/jojo/employer.rb`) - Per-application workspace management
- **AI Client** (`lib/jojo/ai_client.rb`) - Unified interface to AI services
- **Job Description Processor** - Fetch from URL or file, convert to markdown
- **Status Logger** - Track decisions and process flow

### Technology Stack

- **Ruby 3.4.5** - Modern Ruby with PRISM parser
- **Thor** - Command-line interface framework
- **ruby_llm** - Unified Ruby interface for AI services
- **deepsearch-rb** - Web search integration (optional)
- **html-to-markdown** - Convert job postings to markdown
- **dotenv** - Environment variable management
- **Minitest** - Testing framework

### Directory Structure

```
jojo/
├── bin/jojo              # CLI entry point
├── lib/jojo/             # Main application code
│   ├── cli.rb           # Thor command definitions
│   ├── config.rb        # Configuration management
│   ├── employer.rb      # Employer workspace
│   ├── ai_client.rb     # AI service integration
│   └── prompts/         # AI prompt templates
├── test/                 # Test suite
│   ├── unit/            # Fast unit tests
│   ├── integration/     # Integration tests
│   └── service/         # Tests with real APIs
├── templates/           # Template files for users
├── inputs/              # User's actual data (gitignored)
└── employers/           # Generated output (gitignored)
    └── company-name/
        ├── job_description.md
        ├── job_description_annotations.json
        ├── job_details.yml
        ├── research.md
        ├── resume.md
        ├── resume.pdf
        ├── cover_letter.md
        ├── cover_letter.pdf
        ├── status_log.md  # JSON Lines format
        └── website/
            └── index.html
```

## Development workflow

### Available Commands

| Command | Description |
| ------- | ----------- |
| `bundle install` | Install dependencies |
| `./bin/jojo test` | Run unit tests |
| `./bin/jojo test --all` | Run full test suite |
| `./bin/jojo --help` | View all commands |
| `EDITOR=nvim ./bin/jojo generate ...` | Set preferred editor for interactive prompts |

### Contributing

This is a personal project, but if you'd like to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run `./bin/jojo test --all` to verify
5. Submit a pull request

### Code Style

This project uses [Standard Ruby](https://github.com/standardrb/standard) for code formatting:

```bash
# Check style
bundle exec standardrb

# Auto-fix issues
bundle exec standardrb --fix

# Or use the test command
./bin/jojo test --standard
```

### Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `refactor:` - Code refactoring
- `style:` - Code style/formatting changes


## Credits

Created by [Tracy Atteberry](https://tracyatteberry.com) using:
- [Ruby](https://www.ruby-lang.org/) - Programming language
- [Thor](https://github.com/rails/thor) - CLI framework
- [ruby_llm](https://github.com/crmne/ruby_llm) - AI service integration
- [html-to-markdown](https://github.com/kreuzberg-dev/html-to-markdown) - Job posting conversion
- [deepsearch-rb](https://github.com/alexshagov/deepsearch-rb) - Web search capabilities
- [Claude AI](https://claude.ai) - Development assistance
- [Z AI](https://z.ai) - Development assistance

**[Read the full technical blog post](https://tracyatteberry.com/posts/jojo)** about the development process and lessons learned.

## License

MIT License - see [LICENSE](LICENSE) for details.

