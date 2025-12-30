# Jojo Design

Jojo is a Job Search Management System (JSMS) - a Ruby CLI that transforms generic job applications into comprehensive, personalized marketing campaigns.

## Overview

Instead of sending a generic resume and cover letter, Jojo uses AI to generate:

- **Tailored Resume** - Customized from your generic resume to match specific job requirements
- **Persuasive Cover Letter** - Written based on company research and role analysis
- **Professional Website** - Complete landing page with:
  - AI-generated branding statement
  - Selected portfolio projects relevant to the role
  - LinkedIn recommendations carousel
  - FAQ accordion answering common interview questions
  - Annotated job description showing how your experience matches requirements
  - Call-to-action (Calendly or email)
- **Company Research** - AI-generated insights about the company and role
- **Status Logs** - Complete audit trail of decisions and token usage

Think of it as treating each job application like launching a product (you) to a specific customer (the employer).

## Key Features

- **Slug-based workspaces** - Organize multiple applications with unique identifiers
- **AI-powered project selection** - Automatically chooses relevant portfolio projects
- **Template system** - Customizable website templates via ERB
- **Overwrite management** - Smart prompting for file overwrites with global preferences
- **Comprehensive testing** - Unit, integration, and service test categories
- **Token tracking** - Monitor AI usage costs per generation step
- **Environment variable support** - Convenient JOJO_EMPLOYER_SLUG for multi-command workflows

## Directory structure

The directory structure will look something like this:

```
CLAUDE.md
LICENSE
README.md
.gitignore
.ruby-version
Gemfile
Gemfile.lock
lib/
  jojo/
    cli.rb                       # Thor-based CLI
    config.rb                    # Configuration management
    employer.rb                  # Employer workspace management
    ai_client.rb                 # AI service integration
    job_description_processor.rb # Fetch and process job descriptions
    status_logger.rb             # Status logging
    overwrite_helper.rb          # File overwrite handling
    project_loader.rb            # Load projects.yml
    project_selector.rb          # AI-powered project selection
    recommendation_parser.rb     # Parse recommendations
    generators/
      research_generator.rb
      resume_generator.rb
      cover_letter_generator.rb
      website_generator.rb
      annotation_generator.rb
      faq_generator.rb
    prompts/
      research_prompt.rb
      resume_prompt.rb
      cover_letter_prompt.rb
      website_prompt.rb
      annotation_prompt.rb
      faq_prompt.rb
      job_description_prompts.rb
  jojo.rb                        # Main module
test/
  unit/                          # Fast unit tests, no external dependencies
  integration/                   # Integration tests with mocked services
  service/                       # Tests with real API calls
  fixtures/                      # Test data
templates/
  config.yml.erb                 # Template for user configuration file
  generic_resume.md              # Example generic resume in markdown format
  recommendations.md             # Example LinkedIn recommendations
  projects.yml                   # Example portfolio projects
  website/
    default.html.erb             # Default website template
employers/                       # NOT tracked in git (in .gitignore)
  #{employer_slug}/              # Jojo-generated workspace (e.g., acme-corp-senior-dev)
    job_description.md           # HTML processed to markdown if pulled from URL
    job_details.yml              # Extracted metadata (company name, title, location, etc.)
    research.md                  # Generated research on company/role to guide tailoring
    status_log.md                # Log of steps taken, decisions made, etc.
    resume.md                    # Tailored resume
    cover_letter.md              # Tailored cover letter
    job_description_annotated.md # Annotated job description with match analysis
    website/
      index.html                 # Complete landing page with all sections
      branding_image.jpg         # Optional branding image (if provided)
inputs/                          # User-provided input files (NOT tracked in git, in .gitignore)
  generic_resume.md              # User's actual generic resume with full work history
  recommendations.md             # User's actual LinkedIn recommendations (optional)
  projects.yml                   # User's portfolio projects (optional)
  branding_image.jpg             # User's branding image (optional, e.g., "I ❤️ CompanyName" shirt)
docs/
  plans/
    design.md                    # Design document (this file)
    implementation_plan.md       # Implementation plan document
    *.md                         # Various design and implementation documents
bin/
  jojo                           # Main CLI wrapper
config.yml                       # User configuration (created by setup, NOT tracked in git)
.env                             # API keys (NOT tracked in git)
```

The `.gitignore` file excludes the `employers/`, `inputs/`, `config.yml`, `.env`, and temporary directories.


## Landing page content

The generated `website/index.html` includes:

- **Personal branding statement** - AI-generated, tailored to company and role
- **Portfolio highlights** - AI-selected projects from `inputs/projects.yml` that are relevant to the job
  - Each project includes: name, description, technologies, role, impact metrics, and link
  - Projects are selected using AI analysis of job requirements
- **LinkedIn recommendations carousel** - Professional testimonials from `inputs/recommendations.md`
  - Rotating carousel with recommendations from colleagues
  - Each includes recommender's name, title, company, and quote
- **FAQ accordion** - AI-generated frequently asked questions
  - Questions and answers tailored to the role
  - Expandable/collapsible sections
- **Annotated job description** - Shows how your experience matches requirements
  - Each requirement linked to specific experience from your resume
  - Generated from `job_description_annotated.md`
- **Call to Action (CTA)** - Configured in `config.yml`
  - Calendly link for scheduling a call
  - Or direct email link
- **Branding image** (optional) - User-provided image from `inputs/branding_image.jpg`
  - Example: Photo with "I ❤️ #{employer_name}" T-shirt

## Architecture

Jojo is a Ruby CLI that uses Thor for command line interface management.

### Technology Stack

- **Ruby 3.4.5** - Modern Ruby with PRISM parser
- **Thor** (~1.3) - Command-line interface framework
- **ruby_llm** (~1.9) - Unified interface for AI services (Anthropic, OpenAI, etc.)
- **deepsearch-rb** (~0.1) - Web search integration via Serper API (optional)
- **html-to-markdown** (~2.16) - Convert job postings from URLs to markdown
- **dotenv** (~3.1) - Environment variable management (.env file)
- **reline** - Enhanced line editing for interactive prompts
- **Minitest** (~5.25) - Testing framework with minitest-reporters

### Core Components

- **CLI** (`lib/jojo/cli.rb`) - Thor-based command definitions and orchestration
- **Config** (`lib/jojo/config.rb`) - User configuration management (config.yml)
- **Employer** (`lib/jojo/employer.rb`) - Per-application workspace management
- **AIClient** (`lib/jojo/ai_client.rb`) - Unified interface to AI services with token tracking
- **JobDescriptionProcessor** - Fetch from URL or file, convert HTML to markdown
- **StatusLogger** - Track all steps, decisions, and token usage in status_log.md
- **OverwriteHelper** - Handle file overwrite prompts and preferences
- **ProjectLoader** - Load and validate projects.yml
- **ProjectSelector** - AI-powered selection of relevant portfolio projects
- **RecommendationParser** - Parse LinkedIn recommendations from markdown
- **Generators** - Modular generators for each artifact type:
  - ResearchGenerator - Company and role research
  - ResumeGenerator - Tailored resume
  - CoverLetterGenerator - Personalized cover letter
  - AnnotationGenerator - Job description annotations
  - WebsiteGenerator - Landing page with all sections
  - FAQGenerator - Frequently asked questions
- **Prompts** - Encapsulated AI prompts for each generation task

### Templating

- **ERB** - Used for configuration file template and website template
- **Default website template** - `templates/website/default.html.erb`
- **Custom templates** - Users can create additional templates in `templates/website/`

### API Keys

API keys are managed via `.env` file (NOT tracked in git):
- `ANTHROPIC_API_KEY` - Required for Claude AI
- `SERPER_API_KEY` - Optional for web search integration

### Website Deployment

The generated website (`employers/#{slug}/website/index.html`) is a self-contained HTML file with inline CSS and JavaScript.

**Deployment options:**
1. **Manual copy** - Copy the generated `index.html` to your personal website's static directory
   - For Hugo sites: `cp employers/acme-corp/website/index.html ~/my-site/static/applications/acme-corp/index.html`
2. **Future versions** - Direct generation into Hugo layouts/partials for seamless integration

## Configuration

User configuration is stored in `config.yml` (created from `templates/config.yml.erb` during setup):

```yaml
seeker_name: Tracy Atteberry
base_url: https://tracyatteberry.com/applications
reasoning_ai:
  service: anthropic
  model: sonnet
text_generation_ai:
  service: anthropic
  model: haiku
voice_and_tone: professional and friendly

# Website configuration
website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

### Environment Variables

- `JOJO_EMPLOYER_SLUG` - Set to avoid repeating `--slug` flag on commands
- `JOJO_ALWAYS_OVERWRITE` - Set to `true`, `1`, or `yes` to skip overwrite prompts
- `ANTHROPIC_API_KEY` - Required for Claude AI (stored in `.env`)
- `SERPER_API_KEY` - Optional for web search (stored in `.env`)
- `SKIP_SERVICE_CONFIRMATION` - Set to `true` to skip confirmation prompt for service tests

## Workflow

### Step 1: Create Employer Workspace

```bash
jojo new -s company-slug -j job_description.txt
# or
jojo new -s company-slug -j "https://careers.company.com/job/123"
```

This creates `employers/company-slug/` with:
- `job_description.md` - Processed job description (HTML converted to markdown if from URL)
- `job_details.yml` - Extracted metadata (company name, job title, location, etc.)

### Step 2: Generate Application Materials

```bash
jojo generate -s company-slug
# or set environment variable
export JOJO_EMPLOYER_SLUG=company-slug
jojo generate
```

This runs all steps in sequence:

1. **Research**: Generate `research.md` with company/role research to guide tailoring
2. **Resume**: Generate tailored `resume.md` from `inputs/generic_resume.md` + job description + research
3. **Cover Letter**: Generate `cover_letter.md` based on research and tailored resume
4. **Annotations**: Generate annotated job description showing how experience matches requirements
5. **Website**: Generate `website/index.html` landing page with:
   - Branding statement
   - Selected portfolio projects (from `inputs/projects.yml`)
   - LinkedIn recommendations carousel (from `inputs/recommendations.md`)
   - FAQ accordion
   - Annotated job description
   - Call-to-action
6. **Status Log**: Record all decisions and steps in `status_log.md`

Individual commands (`research`, `resume`, `cover_letter`, `annotate`, `website`) execute only their specific step.

### Slug-based Workflow

Most commands require a slug to identify the employer workspace:

```bash
# Option 1: Use --slug flag
jojo research --slug company-slug
jojo resume --slug company-slug

# Option 2: Set environment variable (convenient for multiple commands)
export JOJO_EMPLOYER_SLUG=company-slug
jojo research
jojo resume
jojo cover_letter
jojo website
```

### File Overwrite Behavior

By default, Jojo prompts before overwriting existing files:

```bash
# Default: prompts before overwriting
jojo research -s company-slug

# Always overwrite without prompting
jojo research -s company-slug --overwrite

# Never overwrite, always prompt
jojo research -s company-slug --no-overwrite

# Set global overwrite preference
export JOJO_ALWAYS_OVERWRITE=true
jojo generate -s company-slug  # Skips all prompts
```

**Precedence**: `--overwrite` flag > `--no-overwrite` flag > `JOJO_ALWAYS_OVERWRITE` env var > default (prompt)

## Commands Reference

### Setup and Initialization

- **`jojo setup`** - Interactive setup wizard
  - Creates `config.yml` from template
  - Creates `.env` file with API keys
  - Creates `inputs/` directory
  - No options required

- **`jojo new`** - Create employer workspace
  - Required: `-s, --slug SLUG` - Unique identifier for this application
  - Required: `-j, --job JOB` - Job description file path or URL
  - Optional: `--overwrite` - Skip overwrite prompts
  - Creates `employers/#{slug}/` directory with job artifacts

### Generation Commands

All generation commands require a slug (via `-s` flag or `JOJO_EMPLOYER_SLUG` env var):

- **`jojo generate`** - Generate all materials (research → resume → cover letter → annotations → website)
- **`jojo research`** - Generate company and role research only
- **`jojo resume`** - Generate tailored resume only (requires research)
- **`jojo cover_letter`** - Generate cover letter only (requires resume)
- **`jojo annotate`** - Generate job description annotations only
- **`jojo website`** - Generate landing page only (requires resume)
  - Optional: `-t, --template TEMPLATE` - Website template name (default: "default")

### Testing

- **`jojo test`** - Run test suite
  - `--unit` - Run unit tests only (default, fast)
  - `--integration` - Run integration tests
  - `--service` - Run service tests (requires API keys, costs money)
  - `--all` - Run all test categories
  - `--no-service` - Exclude service tests from `--all`
  - `-q, --quiet` - Quiet mode for CI/CD

### Utility Commands

- **`jojo version`** - Show version number
- **`jojo help [COMMAND]`** - Show help for all commands or specific command

### Global Options

Available on all commands:

- `-v, --verbose` - Show detailed output including AI prompts and responses
- `-q, --quiet` - Suppress all output except errors, rely on exit codes
- `-s, --slug SLUG` - Employer slug (or set `JOJO_EMPLOYER_SLUG` env var)
- `-t, --template TEMPLATE` - Website template name (default: "default")
- `--overwrite` - Always overwrite files without prompting
- `--no-overwrite` - Always prompt before overwriting (even if `JOJO_ALWAYS_OVERWRITE` is set)

