# Jojo design

Jojo is a Job Search Management System (JSMS). It's a Ruby CLI that takes a
generic resume, additional work history data, and a job description as input
and produces not only a tailored resume and cover letter but also a
comprehensive website with landing page selling a single product (you) to a
single customer (the employer).

## Directory structure

The directory structure will look something like this:

```
CLAUDE.md
LICENSE
README.md
.gitignore
.rbenv-gemsets
.ruby-version
Gemfile
Gemfile.lock
Thorfile
lib/
test/                   # minitest/spec unit tests
templates/
  config.yml.erb        # template for user configuration file
  generic_resume.md     # example generic resume in markdown format
  recommendations.md    # example LinkedIn recommendations for tailoring
employers/              # NOT tracked in git (in .gitignore)
  #{employer_slug}/     # Jojo-generated
    job_description.md  # html processed to markdown if pulled from URL
    research.md         # generated research on company/role to guide tailoring
    interview_prep.md   # generated interview preperation guide
    status_log.md       # log of steps taken, decisions made, etc.
    resume.md
    resume.pdf          # generated from resume.md with pandoc
    cover_letter.md
    cover_letter.pdf    # generated from cover_letter.md with pandoc
    website/
      index.html        # landing page -- marketing "product" page with CTAs, include link to here from resume.md/pdf and cover_letter.md/pdf
      contact.html      # if CTA is a calendly link or email link, then may not be needed
      ai_usage_philosophy.html        # should be a blog post on personal site too, maybe this is a link in index.html?
      job_description_annotated.html  # annotated job description with notes on how I fit the role, can this be part of the landing page?
inputs/                 # user-provided input files (NOT tracked in git, in .gitignore)
  generic_resume.md     # user's actual generic resume with full work history
  recommendations.md    # user's actual LinkedIn recommendations (optional)
  ai_usage_philosophy.md # user's AI usage philosophy statement (optional)
docs/
  plans/
    design.md                    # design document (this file)
    implementation_plan.md       # implementation plan document
  posts/
    jojo_technical_blog_post.md  # technical blog post about Jojo
bin/
  jojo                  # main CLI wrapper
```

The `.gitignore` file will exclude the `employers/` and `inputs/` directories.


## Landing page content ideas

- Personal branding statement tailored to company
- Progress graphic showing application journey
- Portfolio highlights relevant to the job
- AI usage philosophy section
- Call to Action (CTA)
  - Contact information
  - Calendly link
- Image of me with "I :heart: #{employer_name}" T-shirt (optional, user-provided)

## Architecture

Jojo is a Ruby CLI that uses Thor for command line interface management.
It uses Ruby 3.4.5, ruby-llm for AI interactions, Pandoc for conversion to PDF,
and ERB for templating. API keys are managed via environment variables (.env file).

## Usage

For the initial version, the user will clone the repo and run the CLI from
there (`./bin/jojo`). This could be largely a wrapper script for thor tasks
that do the actual work. The CLI will accept some command line options, but
most options are provided via configuration file. Only the most variable inputs
are provided via CLI options.

```bash
❯ ./bin/jojo help
Usage: jojo [options] COMMAND [ARGS]...
    -v, --[no-]verbose               Run verbosely
    -e, --employer EMPLOYER          Employer name (required for most commands)
    -j, --job JOB                    Job description input: file path or URL (required for most commands)
    -h, --help                       Show this message
    -V, --version                    Show version

Commands:
    setup           Setup configuration file, run bundle, etc. (interactive)
    generate        Generate everything: research, resume, cover letter, and website (runs all steps)
    research        Generate company/role research only
    resume          Generate tailored resume only
    cover_letter    Generate cover letter only
    website         Generate website only
    test            Run tests
    help [COMMAND]  Describe available commands or one specific command
```

The `bin/jojo` wrapper script parses command-line arguments and delegates to
Thor tasks for actual implementation.

This initial plan is to manually copy the generated website content to the
static section of a hugo-based personal website. Future versions could use a
hugo theme layout and generate directly into the personal website repo.

## Configuration

User configuration is stored in `config.yml` (created from `templates/config.yml.erb` during setup):

```yaml
seeker_name: Tracy Atteberry
reasoning_ai:
  service: anthropic
  model: sonnet
text_generation_ai:
  service: anthropic
  model: haiku
voice_and_tone: professional and friendly
```

API keys are stored in `.env` file (NOT tracked in git):

```bash
ANTHROPIC_API_KEY=sk-ant-...
```

## Workflow

When running `jojo generate -e "Company Name" -j job_description.txt`:

1. **Research**: Generate `employers/company-name/research.md` with company/role research to guide tailoring
2. **Resume**: Generate tailored `resume.md` from `inputs/generic_resume.md` + job description
3. **Cover Letter**: Generate `cover_letter.md` based on research and tailored resume
4. **Website**: Generate landing page and supporting HTML files
5. **PDFs**: Convert resume.md and cover_letter.md to PDF using Pandoc
6. **Status Log**: Record all decisions and steps in `status_log.md`

Individual commands (`research`, `resume`, `cover_letter`, `website`) execute only their specific step.

