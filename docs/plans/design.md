# Jojo Design

Jojo is a Job Search Management System (JSMS) - a Ruby CLI that transforms generic job applications into comprehensive, personalized marketing campaigns.

## Overview

Instead of sending a generic resume and cover letter, Jojo uses AI to generate:

- **Tailored Resume** - Customized from your structured resume data to match specific job requirements
- **Persuasive Cover Letter** - Written based on company research and role analysis
- **Professional Website** - Complete landing page with:
  - AI-generated branding statement
  - Selected portfolio projects relevant to the role
  - LinkedIn recommendations carousel
  - FAQ accordion answering common interview questions
  - Annotated job description showing how your experience matches requirements
  - Call-to-action (Calendly or email)
- **Company Research** - AI-generated insights about the company and role (with optional web search)
- **PDF Export** - Convert resume and cover letter to PDF via Pandoc
- **Status Logs** - Complete audit trail of decisions and token usage (JSON format)

Think of it as treating each job application like launching a product (you) to a specific customer (the company).

## Key Features

- **Slug-based workspaces** - Organize multiple applications with unique identifiers
- **Interactive dashboard** - TUI-based workflow for managing applications
- **AI-powered project selection** - Automatically chooses and scores relevant portfolio projects
- **Template system** - Customizable resume and website templates via ERB
- **Overwrite management** - Smart prompting for file overwrites with global preferences
- **Comprehensive testing** - Unit, integration, and service test categories
- **Token tracking** - Monitor AI usage costs per generation step
- **Environment variable support** - Convenient JOJO_APPLICATION_SLUG for multi-command workflows
- **State persistence** - Remember current application across commands

## Directory structure

The directory structure looks like this:

```
CLAUDE.md
LICENSE
README.md
.gitignore
.ruby-version
Gemfile
Gemfile.lock
Rakefile                             # Test runner tasks
lib/
  jojo/
    cli.rb                           # Thor-based CLI
    config.rb                        # Configuration management (singleton)
    application.rb                   # Application workspace management
    ai_client.rb                     # AI service integration
    status_logger.rb                 # JSON-based status logging
    overwrite_helper.rb              # File overwrite handling (mixin)
    project_selector.rb              # AI-powered project selection with scoring
    resume_data_loader.rb            # Load and validate resume_data.yml
    resume_data_formatter.rb         # Convert structured data to text
    state_persistence.rb             # Current application slug persistence
    erb_renderer.rb                  # Template rendering support
    template_validator.rb            # Validate template structure
    provider_helper.rb               # AI provider configuration
    commands/                        # Command-based organization
      annotate/
        command.rb                   # Command orchestration
        generator.rb                 # Content generation
        prompt.rb                    # AI prompt templates
      branding/
        command.rb
        generator.rb
        prompt.rb
      cover_letter/
        command.rb
        generator.rb
        prompt.rb
      faq/
        command.rb
        generator.rb
        prompt.rb
      interactive/
        command.rb                   # Entry point
        runner.rb                    # Main loop
        workflow.rb                  # Workflow management
        dashboard.rb                 # TUI display
        dialogs.rb                   # User prompts
      job_description/
        command.rb
        processor.rb                 # Fetch and process job descriptions
        prompt.rb
      new/
        command.rb
      pdf/
        command.rb
        converter.rb                 # Markdown to PDF conversion
        pandoc_checker.rb            # Pandoc availability check
      research/
        command.rb
        generator.rb
        prompt.rb
      resume/
        command.rb
        generator.rb
        prompt.rb
        curation_service.rb          # Resume data transformation
        transformer.rb               # Resume processing
      setup/
        command.rb
      version/
        command.rb
      website/
        generator.rb                 # Landing page generation
  jojo.rb                            # Main module
test/
  unit/                              # Fast unit tests, no external dependencies
    commands/                        # Tests organized by command
  integration/                       # Integration tests with mocked services
  service/                           # Tests with real API calls (costs money)
  fixtures/                          # Test data (NEVER use inputs/ in tests)
  support/                           # Test helpers
templates/
  config.yml.erb                     # Template for user configuration file
  .env.erb                           # Template for environment variables
  default_resume.md.erb              # Default resume template
  resume_data.yml                    # Example resume data schema
  website/
    default.html.erb                 # Default website template
    styles.css                       # Website stylesheet
    script.js                        # Website JavaScript
    icons.svg                        # SVG icon definitions
applications/                        # NOT tracked in git (in .gitignore)
  #{slug}/                           # Jojo-generated workspace (e.g., acme-corp-senior-dev)
    job_description_raw.md           # Original job description
    job_description.md               # Processed job description
    job_details.yml                  # Extracted metadata (company name, title, location, etc.)
    research.md                      # Generated research on company/role
    resume.md                        # Tailored resume
    branding.md                      # AI-generated branding statement
    cover_letter.md                  # Tailored cover letter
    job_description_annotations.json # Annotations data (JSON)
    faq.json                         # FAQ data (JSON)
    status.log                       # JSON log entries
    resume.pdf                       # Generated PDF (optional, requires Pandoc)
    cover_letter.pdf                 # Generated PDF (optional)
    website/
      index.html                     # Complete landing page
      styles.css                     # Website styles
      script.js                      # Website scripts
      icons.svg                      # Website icons
      branding_image.jpg             # Optional branding image (if provided)
inputs/                              # User-provided input files (NOT tracked in git)
  resume_data.yml                    # User's structured resume data
  templates/
    default_resume.md.erb            # User's resume template (optional)
  recommendations.md                 # User's LinkedIn recommendations (optional)
  branding_image.jpg                 # User's branding image (optional)
docs/
  plans/
    design.md                        # Design document (this file)
    implementation_plan.md           # Implementation plan document
    *.md                             # Various design and implementation documents
bin/
  jojo                               # Main CLI wrapper
  test                               # Test runner script
config.yml                           # User configuration (created by setup, NOT tracked in git)
.env                                 # API keys (NOT tracked in git)
.jojo_state                          # Current application slug (NOT tracked in git)
```

The `.gitignore` file excludes `applications/`, `inputs/`, `config.yml`, `.env`, `.jojo_state`, and temporary directories.


## Landing page content

The generated `website/index.html` includes:

- **Personal branding statement** - AI-generated, tailored to company and role
- **Portfolio highlights** - AI-selected projects from resume data that are relevant to the job
  - Each project includes: name, description, technologies, role, impact metrics, and link
  - Projects are selected and scored using AI analysis of job requirements
  - Configurable limits: 5 for landing page, 3 for resume, 2 for cover letter
- **LinkedIn recommendations carousel** - Professional testimonials from `inputs/recommendations.md`
  - Rotating carousel with recommendations from colleagues
  - Each includes recommender's name, title, company, and quote
- **FAQ accordion** - AI-generated frequently asked questions
  - Questions and answers tailored to the role
  - Expandable/collapsible sections
- **Annotated job description** - Shows how your experience matches requirements
  - Each requirement linked to specific experience from your resume
  - Generated from `job_description_annotations.json`
- **Call to Action (CTA)** - Configured in `config.yml`
  - Calendly link for scheduling a call
  - Or direct email link
- **Branding image** (optional) - User-provided image from `inputs/branding_image.jpg`
  - Example: Photo with "I ❤️ #{company_name}" T-shirt

## Architecture

Jojo is a Ruby CLI that uses Thor for command line interface management.

### Technology Stack

- **Ruby 3.4.5** - Modern Ruby with PRISM parser
- **Thor** (~1.3) - Command-line interface framework
- **ruby_llm** (~1.9) - Unified interface for AI services (Anthropic, OpenAI, etc.)
- **deepsearch-rb** (~0.1) - Web search integration via Serper or Tavily API (optional)
- **html-to-markdown** (~2.16) - Convert job postings from URLs to markdown
- **dotenv** (~3.1) - Environment variable management (.env file)
- **reline** - Enhanced line editing for interactive prompts
- **Minitest** (~5.25) - Testing framework with minitest-reporters

**TUI Dependencies (Interactive Dashboard):**
- **tty-prompt** (~0.23) - Interactive prompts
- **tty-box** (~0.7) - Box drawing
- **tty-cursor** (~0.7) - Cursor movement
- **tty-reader** (~0.9) - Key input
- **tty-screen** (~0.8) - Terminal dimensions

**Development/Testing:**
- **standard** (~1.0) - Ruby code style
- **rake** (~13.0) - Task runner
- **simplecov** - Code coverage

### Core Components

- **CLI** (`lib/jojo/cli.rb`) - Thor-based command definitions and orchestration
- **Config** (`lib/jojo/config.rb`) - User configuration management (singleton pattern)
- **Application** (`lib/jojo/application.rb`) - Per-application workspace management
- **AIClient** (`lib/jojo/ai_client.rb`) - Unified interface to AI services with token tracking
- **StatusLogger** (`lib/jojo/status_logger.rb`) - Track all steps, decisions, and token usage in status.log (JSON format)
- **OverwriteHelper** (`lib/jojo/overwrite_helper.rb`) - Handle file overwrite prompts and preferences (mixin)
- **ProjectSelector** (`lib/jojo/project_selector.rb`) - AI-powered selection and scoring of relevant portfolio projects
- **ResumeDataLoader** (`lib/jojo/resume_data_loader.rb`) - Load and validate resume_data.yml
- **ResumeDataFormatter** (`lib/jojo/resume_data_formatter.rb`) - Convert structured resume data to text
- **StatePersistence** (`lib/jojo/state_persistence.rb`) - Persist current application slug
- **ErbRenderer** (`lib/jojo/erb_renderer.rb`) - Template rendering support
- **TemplateValidator** (`lib/jojo/template_validator.rb`) - Validate template structure
- **ProviderHelper** (`lib/jojo/provider_helper.rb`) - AI provider configuration

### Command-Based Organization

Each command is organized in its own directory under `lib/jojo/commands/` with a consistent structure:

```
lib/jojo/commands/{command_name}/
├── command.rb    # Command orchestration (extends Base)
├── generator.rb  # Content generation logic
├── prompt.rb     # AI prompt templates
```

**Commands:**
- **annotate** - Generate job description annotations
- **branding** - Generate branding statement
- **cover_letter** - Generate personalized cover letter
- **faq** - Generate FAQ content
- **interactive** - TUI dashboard (default command)
- **job_description** - Process/extract job description
- **new** - Create new application workspace
- **pdf** - Generate PDF from markdown files
- **research** - Generate company/role research
- **resume** - Generate tailored resume
- **setup** - Interactive setup wizard
- **version** - Show version
- **website** - Generate landing page HTML

### Templating

- **ERB** - Used for configuration file template, resume template, and website template
- **Default resume template** - `templates/default_resume.md.erb`
- **Default website template** - `templates/website/default.html.erb`
- **Custom templates** - Users can create additional templates in `inputs/templates/`

### API Keys

API keys are managed via `.env` file (NOT tracked in git):
- `ANTHROPIC_API_KEY` - Required for Claude AI
- `SERPER_API_KEY` or `TAVILY_API_KEY` - Optional for web search integration

### Website Deployment

The generated website (`applications/#{slug}/website/`) includes:
- `index.html` - Main landing page
- `styles.css` - Stylesheet
- `script.js` - JavaScript
- `icons.svg` - SVG icons

**Deployment options:**
1. **Manual copy** - Copy the generated `website/` directory to your personal website's static directory
   - For Hugo sites: `cp -r applications/acme-corp/website/* ~/my-site/static/applications/acme-corp/`
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

# Web search configuration (optional)
web_search:
  provider: serper  # or tavily
  # API key in .env file

# Website configuration
website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

### Environment Variables

- `JOJO_APPLICATION_SLUG` - Set to avoid repeating `--slug` flag on commands (backward compatible: `JOJO_EMPLOYER_SLUG`)
- `JOJO_ALWAYS_OVERWRITE` - Set to `true`, `1`, or `yes` to skip overwrite prompts
- `ANTHROPIC_API_KEY` - Required for Claude AI (stored in `.env`)
- `SERPER_API_KEY` or `TAVILY_API_KEY` - Optional for web search (stored in `.env`)
- `SKIP_SERVICE_CONFIRMATION` - Set to `true` to skip confirmation prompt for service tests

## Workflow

### Interactive Mode (Default)

```bash
jojo
# or
jojo interactive
```

Launches the TUI dashboard for managing applications with:
- Application selection/creation
- Step-by-step generation workflow
- Status tracking
- Keyboard navigation

### Step 1: Create Application Workspace

```bash
jojo new -s company-slug -j job_description.txt
# or
jojo new -s company-slug -j "https://careers.company.com/job/123"
```

This creates `applications/company-slug/` with:
- `job_description_raw.md` - Original job description
- `job_description.md` - Processed job description (HTML converted to markdown if from URL)
- `job_details.yml` - Extracted metadata (company name, job title, location, etc.)

### Step 2: Generate Application Materials

```bash
jojo generate -s company-slug
# or set environment variable
export JOJO_APPLICATION_SLUG=company-slug
jojo generate
```

This runs all steps in sequence:

1. **Research**: Generate `research.md` with company/role research (optional web search)
2. **Resume**: Generate tailored `resume.md` from `inputs/resume_data.yml` + job description + research
3. **Branding**: Generate `branding.md` with AI-generated branding statement
4. **Cover Letter**: Generate `cover_letter.md` based on research and tailored resume
5. **Annotations**: Generate `job_description_annotations.json` showing how experience matches requirements
6. **FAQ**: Generate `faq.json` with frequently asked questions
7. **Website**: Generate `website/index.html` landing page with all sections
8. **Status Log**: Record all decisions and steps in `status.log` (JSON format)

Individual commands (`research`, `resume`, `branding`, `cover_letter`, `annotate`, `faq`, `website`) execute only their specific step.

### Slug-based Workflow

Most commands require a slug to identify the application workspace:

```bash
# Option 1: Use --slug flag
jojo research --slug company-slug
jojo resume --slug company-slug

# Option 2: Set environment variable (convenient for multiple commands)
export JOJO_APPLICATION_SLUG=company-slug
jojo research
jojo resume
jojo cover_letter
jojo website

# Option 3: Use interactive mode (remembers current application)
jojo
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
  - Creates `inputs/` directory with example files
  - No options required

- **`jojo new`** - Create application workspace
  - Required: `-s, --slug SLUG` - Unique identifier for this application
  - Required: `-j, --job JOB` - Job description file path or URL
  - Optional: `--overwrite` - Skip overwrite prompts
  - Creates `applications/#{slug}/` directory with job artifacts

### Generation Commands

All generation commands require a slug (via `-s` flag or `JOJO_APPLICATION_SLUG` env var):

- **`jojo generate`** - Generate all materials (research → resume → branding → cover letter → annotations → faq → website)
- **`jojo research`** - Generate company and role research only (with optional web search)
- **`jojo resume`** - Generate tailored resume only (requires research)
- **`jojo branding`** - Generate branding statement only
- **`jojo cover_letter`** - Generate cover letter only (requires resume)
- **`jojo annotate`** - Generate job description annotations only
- **`jojo faq`** - Generate FAQ content only
- **`jojo website`** - Generate landing page only (requires resume)
  - Optional: `-t, --template TEMPLATE` - Website template name (default: "default")
- **`jojo pdf`** - Generate PDF from resume and/or cover letter (requires Pandoc)

### Interactive Mode

- **`jojo`** or **`jojo interactive`** - Launch TUI dashboard
  - Application selection and creation
  - Step-by-step generation workflow
  - Keyboard-driven navigation

### Testing

Tests are run via Rake or the bin/test script:

```bash
./bin/test              # Run all tests that don't cost money (unit + integration)
rake test:unit          # Run unit tests only
rake test:integration   # Run integration tests only
rake test:service       # Run service tests (requires API keys, costs money)
rake test:all           # Run all test categories
```

### Utility Commands

- **`jojo version`** - Show version number
- **`jojo help [COMMAND]`** - Show help for all commands or specific command

### Global Options

Available on all commands:

- `-v, --verbose` - Show detailed output including AI prompts and responses
- `-q, --quiet` - Suppress all output except errors, rely on exit codes
- `-s, --slug SLUG` - Application slug (or set `JOJO_APPLICATION_SLUG` env var)
- `-t, --template TEMPLATE` - Website template name (default: "default")
- `--overwrite` - Always overwrite files without prompting
- `--no-overwrite` - Always prompt before overwriting (even if `JOJO_ALWAYS_OVERWRITE` is set)

## Resume Data Structure

Instead of a generic markdown resume, Jojo uses structured YAML data in `inputs/resume_data.yml`:

```yaml
name: Your Name
email: you@example.com
phone: (555) 123-4567
location: City, State
linkedin: linkedin.com/in/yourname
github: github.com/yourname
website: yourwebsite.com

summary: |
  Brief professional summary...

experience:
  - company: Company Name
    title: Job Title
    location: City, State
    dates: Jan 2020 - Present
    highlights:
      - Achievement or responsibility
      - Another achievement

education:
  - school: University Name
    degree: Degree Type
    field: Field of Study
    dates: 2016 - 2020

skills:
  - category: Programming Languages
    items: [Python, Ruby, JavaScript]
  - category: Frameworks
    items: [Rails, React, FastAPI]

projects:
  - name: Project Name
    description: Brief description
    technologies: [Tech1, Tech2]
    role: Your role
    impact: Impact metrics
    link: https://project.url
    image: project-screenshot.png  # Optional
```

The `ResumeDataLoader` validates this structure, and `ResumeDataFormatter` converts it to text for AI processing. The `CurationService` transforms the data for specific job applications.
