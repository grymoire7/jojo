# JoJo - Job Search Management System

✨ A new way to present yourself to a prospective employer, beyond the resume ✨

![Tests](https://github.com/grymoire7/jojo/actions/workflows/ruby.yml/badge.svg?branch=main)
![Ruby Version](https://img.shields.io/badge/Ruby-3.4.5-green?logo=Ruby&logoColor=red&label=Ruby%20version&color=green)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/grymoire7/jojo/blob/main/LICENSE.txt)

## What is this?

JoJo is a Job Search Management System - a Ruby CLI that transforms job applications into comprehensive, personalized marketing campaigns. Instead of sending a generic resume and cover letter, JoJo generates:

- **Tailored Resume**: Customized from your generic resume to match specific job requirements
- **Persuasive Cover Letter**: Written based on company research and role analysis
- **Professional Website**: Landing page selling you as the perfect candidate
- **Company Research**: AI-generated insights about the company and role
- **Job Description Annotations**: Analysis of how your experience matches requirements

Think of it as treating each job application like launching a product (you) to a specific customer (the employer).

**[Read the technical blog post](https://tracyatteberry.com/posts/jojo)** about building this tool with Claude AI assistance.

![screenshot](screenshot.png)

## Table of contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Commands](#commands)
- [Testing](#testing)
- [Architecture](#architecture)
- [Development workflow](#development-workflow)

## Prerequisites

- **Ruby 3.4.5** - Install via rbenv or your preferred Ruby version manager
- **Bundler** - Install with `gem install bundler`
- **AI Provider API Key** - Get one from your chosen provider:
  - [Anthropic Claude](https://console.anthropic.com) (default configuration)
  - [OpenAI](https://platform.openai.com) (requires config changes)
  - Other providers supported by [ruby_llm](https://github.com/alexrudall/ruby_llm)
- **Pandoc** (optional) - For PDF generation: `brew install pandoc` on macOS

### API Costs

JoJo uses AI providers to generate application materials. You can configure any provider supported by [ruby_llm](https://github.com/alexrudall/ruby_llm) (Anthropic, OpenAI, etc.) in your `config.yml`.

**Example costs using Anthropic's Claude** (default configuration):

- **Research generation**: ~$0.15-0.30 (Sonnet model, ~30K-60K tokens)
- **Resume generation**: ~$0.10-0.20 (Haiku model, ~20K-40K tokens)
- **Cover letter generation**: ~$0.05-0.10 (Haiku model, ~10K-20K tokens)
- **Website generation**: ~$0.10-0.20 (Haiku model, ~20K-40K tokens)
- **Job description annotations**: ~$0.10-0.15 (Sonnet model, ~20K-30K tokens)

**Estimated total cost per application: $0.50-0.95** (with Anthropic Claude)

Actual costs vary based on:
- AI provider and model selection
- Length of your resume and job description
- Amount of research content generated
- Number of projects in your portfolio

See your provider's pricing page for current rates:
- [Anthropic pricing](https://www.anthropic.com/pricing)
- [OpenAI pricing](https://openai.com/api/pricing/)

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

   This will guide you through:
   - Setting up your Anthropic API key
   - Configuring your personal information
   - Creating input file templates

**Note**: The setup command is idempotent - you can run it multiple times safely. It only creates missing files.

## Configuration

### Environment Variables

The setup command creates `.env` with your API key. You can edit it directly if needed:

```bash
ANTHROPIC_API_KEY=your_api_key_here
SERPER_API_KEY=your_serper_key_here  # Optional, for web search
```

### User Configuration

After running `./bin/jojo setup`, you can edit `config.yml` to customize:

```yaml
seeker_name: Your Name
base_url: https://yourwebsite.com/applications

reasoning_ai:
  service: anthropic
  model: sonnet        # or opus for higher quality

text_generation_ai:
  service: anthropic
  model: haiku         # faster for simple tasks

voice_and_tone: professional and friendly

website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

### Input Files

The setup command creates these files in `inputs/` with example content:

1. **`inputs/generic_resume.md`** (required) - Your complete work history
   - Contains examples you should replace with your actual experience
   - Include ALL your skills and experience - tailoring will select what's relevant
   - **Delete the first comment line after customizing**

2. **`inputs/recommendations.md`** (optional) - LinkedIn recommendations
   - Used in website carousel
   - Delete file if you don't want recommendations

3. **`inputs/projects.yml`** (optional) - Portfolio projects
   - Used for project selection and highlighting
   - Delete file if you don't have projects to showcase

**Important**: The first line of each template file contains a marker comment. Delete this line after you customize the file - jojo will warn you if templates are unchanged.

## Quick start

### Step 0: Run setup

If you haven't already, run setup to create your configuration and input files:

```bash
./bin/jojo setup
```

Then customize your input files:

1. **Edit your generic resume**:
   ```bash
   nvim inputs/generic_resume.md  # or your preferred editor
   ```
   Replace the example content with your actual experience, skills, and achievements.
   **Delete the first comment line** (`<!-- JOJO_TEMPLATE_PLACEHOLDER -->`) when done.

2. **(Optional) Customize or delete recommendations**:
   ```bash
   nvim inputs/recommendations.md
   # Or delete: rm inputs/recommendations.md
   ```

3. **(Optional) Customize or delete projects**:
   ```bash
   nvim inputs/projects.yml
   # Or delete: rm inputs/projects.yml
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
- `website/index.html` - Landing page
- `status_log.md` - Process log

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

## Testing

Jojo includes comprehensive testing to ensure reliability and performance.

### Test Categories

- **Unit tests** - Fast tests with no external dependencies (default)
- **Integration tests** - Tests with mocked external services
- **Service tests** - Tests that make real API calls (may incur costs)

### Running Tests

```bash
# Run unit tests (fast, default)
./bin/jojo test

# Run all tests
./bin/jojo test --all

# Run specific categories
./bin/jojo test --unit --integration
./bin/jojo test --service  # Requires confirmation

# Quiet mode (CI-friendly)
./bin/jojo test --all -q
```

Service tests require real API keys and may cost money. You'll be prompted for confirmation unless `SKIP_SERVICE_CONFIRMATION=true` is set in your environment.

## Architecture

JoJo is built as a modular Ruby CLI application:

### Core Components

- **CLI Layer** (`lib/jojo/cli.rb`) - Thor-based command interface
- **Configuration** (`lib/jojo/config.rb`) - User settings management
- **Employer** (`lib/jojo/employer.rb`) - Per-application workspace management
- **AI Client** (`lib/jojo/ai_client.rb`) - Unified interface to AI services (Anthropic)
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
        ├── research.md
        ├── resume.md
        ├── cover_letter.md
        ├── status_log.md
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

### Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `refactor:` - Code refactoring


## Credits

Created by [Tracy Atteberry](https://tracyatteberry.com) using:
- [Ruby](https://www.ruby-lang.org/) - Programming language
- [Thor](https://github.com/rails/thor) - CLI framework
- [ruby_llm](https://github.com/alexrudall/ruby_llm) - AI service integration
- [html-to-markdown](https://github.com/soundasleep/html-to-markdown) - Job posting conversion
- [deepsearch-rb](https://github.com/serpapi/deepsearch-rb) - Web search capabilities
- [Claude AI](https://claude.ai) - Development assistance

**[Read the full technical blog post](https://tracyatteberry.com/posts/jojo)** about the development process and lessons learned.

## License

MIT License - see [LICENSE](LICENSE) for details.

