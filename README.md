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
- **Anthropic API Key** - Get one from [console.anthropic.com](https://console.anthropic.com)
- **Pandoc** (optional) - For PDF generation: `brew install pandoc` on macOS

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

3. Set up your environment:
   ```bash
   cp .env.example .env
   # Edit .env and add your ANTHROPIC_API_KEY
   ```

4. Run setup to create configuration:
   ```bash
   ./bin/jojo setup
   ```

   This creates `~/.config/jojo/config.yml` with your preferences.

## Configuration

### Environment Variables

Edit `.env` in the project root:

```bash
ANTHROPIC_API_KEY=your_api_key_here
SERPER_API_KEY=your_serper_key_here  # Optional, for web search
```

### User Configuration

After running `./bin/jojo setup`, edit `~/.config/jojo/config.yml`:

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

Create these files in the `inputs/` directory (which is gitignored):

1. **`inputs/generic_resume.md`** - Your complete work history in markdown
   - Copy from `templates/generic_resume.md` as a starting point
   - Include all experience, skills, and achievements

2. **`inputs/recommendations.md`** (optional) - LinkedIn recommendations
   - Copy from `templates/recommendations.md` for format
   - Used in website carousel

3. **`inputs/projects.yml`** (optional) - Portfolio projects
   - Copy from `templates/projects.yml` for format
   - Used for project selection and highlighting

## Quick start

### Step 1: Create employer workspace

First, create a workspace for the employer by processing their job description:

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

### Environment Variables

- `JOJO_EMPLOYER_SLUG` - Set this to avoid repeating `--slug` flag for commands

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
- [Anthropic Claude](https://www.anthropic.com/) - AI model for content generation
- [html-to-markdown](https://github.com/soundasleep/html-to-markdown) - Job posting conversion
- [deepsearch-rb](https://github.com/serpapi/deepsearch-rb) - Web search capabilities
- [Claude AI](https://claude.ai) - Development assistance

**[Read the full technical blog post](https://tracyatteberry.com/posts/jojo)** about the development process and lessons learned.

## License

MIT License - see [LICENSE](LICENSE) for details.

