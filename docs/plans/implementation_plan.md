# Jojo Implementation Plan

This document outlines the implementation strategy for Jojo, a Job Search Management System.

## Implementation Approach

We'll build Jojo incrementally in phases, with each phase delivering working functionality:

1. **Phase 0**: Project scaffolding and setup
2. **Phase 1**: CLI framework and configuration
3. **Phase 2**: Job description processing
4. **Phase 3**: Research generation
5. **Phase 4**: Resume generation
6. **Phase 5**: Cover letter generation
7. **Phase 6**: Website generation
8. **Phase 7**: PDF generation and polish

Each phase will include tests and be potentially shippable.

## Prerequisites

- Ruby 3.4.5 installed
- Bundler installed (`gem install bundler`)
- Pandoc installed for PDF generation (can defer to Phase 7)
- Anthropic API key

## Phase 0: Project Scaffolding ✅

**Goal**: Set up basic project structure and dependencies

**Status**: COMPLETED

### Tasks:

- [x] Create directory structure
  - `lib/jojo/` - main source code
  - `test/` - minitest tests
  - `templates/` - template files
  - `inputs/` - user input directory (gitignored)
  - `employers/` - generated output directory (gitignored)
  - `bin/` - executable wrapper
  - `docs/` - already exists

- [x] Create `.gitignore`
  ```
  employers/
  inputs/
  .env
  config.yml
  *.gem
  .bundle/
  vendor/bundle/
  ```

- [x] Create `Gemfile`
  ```ruby
  source 'https://rubygems.org'

  ruby '3.4.5'

  gem 'thor', '~> 1.3'
  gem 'ruby_llm', '~> 1.9'
  gem 'dotenv', '~> 3.1'

  group :development, :test do
    gem 'minitest', '~> 5.25'
    gem 'minitest-reporters', '~> 1.7'
  end
  ```

- [x] Create `.ruby-version`
  ```
  3.4.5
  ```

- [x] Create `.rbenv-gemsets`
  ```
  jojo
  ```

- [x] Run `bundle install`

- [x] Create basic `lib/jojo.rb` entry point
  ```ruby
  require 'thor'
  require 'dotenv/load'

  module Jojo
    VERSION = '0.1.0'
  end
  ```

- [x] Create `test/test_helper.rb`
  ```ruby
  require 'minitest/autorun'
  require 'minitest/reporters'
  Minitest::Reporters.use!

  require_relative '../lib/jojo'
  ```

**Validation**: ✅ `bundle install` succeeds, `ruby -Ilib -e "require 'jojo'; puts Jojo::VERSION"` prints version

## Phase 1: CLI Framework and Configuration

**Goal**: Working CLI with help, version, and setup command

### Tasks:

- [ ] Create `Thorfile` with basic tasks structure
  ```ruby
  require_relative 'lib/jojo'
  require_relative 'lib/jojo/cli'
  ```

- [ ] Create `lib/jojo/cli.rb` - Thor CLI class
  - `desc` and method for each command
  - Class options for `-e/--employer`, `-j/--job`, `-v/--verbose`
  - Commands: `setup`, `generate`, `research`, `resume`, `cover_letter`, `website`, `test`

- [ ] Create `bin/jojo` wrapper script
  ```ruby
  #!/usr/bin/env ruby
  require_relative '../lib/jojo'
  require_relative '../lib/jojo/cli'

  Jojo::CLI.start(ARGV)
  ```
  - Make executable: `chmod +x bin/jojo`

- [ ] Implement `setup` command in `lib/jojo/commands/setup.rb`
  - Check for existing `config.yml`, prompt to overwrite if exists
  - Create `config.yml` from `templates/config.yml.erb`
  - Prompt for seeker_name
  - Create `.env` if doesn't exist, prompt for ANTHROPIC_API_KEY
  - Create `inputs/` directory if doesn't exist
  - Provide instructions on what to put in `inputs/`

- [ ] Create `templates/config.yml.erb`
  ```yaml
  seeker_name: <%= seeker_name %>
  reasoning_ai:
    service: anthropic
    model: sonnet
  text_generation_ai:
    service: anthropic
    model: haiku
  voice_and_tone: professional and friendly
  ```

- [ ] Create `templates/generic_resume.md` - example resume

- [ ] Create `templates/recommendations.md` - example recommendations

- [ ] Create `lib/jojo/config.rb` - Configuration loader
  - Load and parse `config.yml`
  - Validate required fields
  - Provide accessor methods

- [ ] Add tests for Config class

**Validation**: `./bin/jojo help` shows commands, `./bin/jojo setup` creates config.yml and .env

## Phase 2: Job Description Processing

**Goal**: Process job description from file or URL, save to employer directory

### Tasks:

- [ ] Create `lib/jojo/employer.rb` - Employer class
  - Generate slug from employer name
  - Create employer directory structure
  - Provide paths to all employer files

- [ ] Create `lib/jojo/job_description_processor.rb`
  - Handle file input: read markdown/text file
  - Handle URL input: fetch HTML, convert to markdown (use `reverse_markdown` gem or AI)
  - Save as `employers/#{slug}/job_description.md`
  - Extract key details (job title, company name, etc.) for use in other components

- [ ] Add `reverse_markdown` gem to Gemfile (or use AI for HTML→markdown)

- [ ] Create tests for JobDescriptionProcessor

- [ ] Wire up basic `generate` command to:
  - Validate required options (`-e` and `-j`)
  - Create employer directory
  - Process and save job description
  - Log to `status_log.md`

**Validation**: `./bin/jojo generate -e "Acme Corp" -j test_job.txt` creates directory and saves job description

## Phase 3: Research Generation

**Goal**: Generate company/role research using AI

### Tasks:

- [ ] Create `lib/jojo/ai_client.rb` - Wrapper for ruby-llm
  - Initialize with config (API key, model selection)
  - Methods for reasoning vs text generation
  - Error handling and retries
  - Token usage logging

- [ ] Create `lib/jojo/prompts/research_prompt.rb`
  - Template for research generation prompt
  - Include job description
  - Request company research, role analysis, culture insights
  - Output format specification (markdown sections)

- [ ] Create `lib/jojo/generators/research_generator.rb`
  - Read job description
  - Build prompt
  - Call AI (reasoning model)
  - Save to `employers/#{slug}/research.md`
  - Log to status_log

- [ ] Implement `research` command in CLI
  - Run research generator only

- [ ] Add to `generate` command workflow

- [ ] Create tests for ResearchGenerator

**Validation**: `./bin/jojo research -e "Acme Corp" -j test_job.txt` generates research.md with relevant company insights

## Phase 4: Resume Generation

**Goal**: Generate tailored resume from generic resume + job description + research

### Tasks:

- [ ] Create `lib/jojo/generators/resume_generator.rb`
  - Read `inputs/generic_resume.md`
  - Read job description and research
  - Build tailoring prompt
  - Call AI (text generation model)
  - Save to `employers/#{slug}/resume.md`
  - Include link to landing page in resume
  - Log to status_log

- [ ] Create `lib/jojo/prompts/resume_prompt.rb`
  - Instructions for tailoring resume
  - Emphasis on relevance to job description
  - Use research insights
  - Maintain voice and tone from config
  - Output markdown format

- [ ] Implement `resume` command in CLI

- [ ] Add to `generate` command workflow (after research)

- [ ] Create tests for ResumeGenerator

**Validation**: `./bin/jojo resume -e "Acme Corp" -j test_job.txt` generates tailored resume.md

## Phase 5: Cover Letter Generation

**Goal**: Generate cover letter based on research and tailored resume

### Tasks:

- [ ] Create `lib/jojo/generators/cover_letter_generator.rb`
  - Read job description, research, and tailored resume
  - Build cover letter prompt
  - Call AI (text generation model)
  - Save to `employers/#{slug}/cover_letter.md`
  - Include link to landing page
  - Log to status_log

- [ ] Create `lib/jojo/prompts/cover_letter_prompt.rb`
  - Instructions for professional cover letter
  - Use research insights
  - Reference specific qualifications from resume
  - Include call to action
  - Voice and tone from config

- [ ] Implement `cover_letter` command in CLI

- [ ] Add to `generate` command workflow (after resume)

- [ ] Create tests for CoverLetterGenerator

**Validation**: `./bin/jojo cover_letter -e "Acme Corp" -j test_job.txt` generates cover_letter.md

## Phase 6: Website Generation

**Goal**: Generate landing page and supporting HTML files

### Tasks:

- [ ] Create `lib/jojo/generators/website_generator.rb`
  - Read all context (job description, research, resume, cover letter)
  - Generate index.html (landing page)
  - Generate other pages as needed
  - Copy/generate assets (CSS, images if provided)
  - Save to `employers/#{slug}/website/`
  - Log to status_log

- [ ] Create `lib/jojo/prompts/website_prompt.rb`
  - Instructions for landing page HTML/CSS
  - Include elements from design.md:
    - Personal branding statement
    - Portfolio highlights
    - AI usage philosophy (from inputs/ if exists)
    - CTA (Calendly link, contact info from config)
    - Optional: custom image if provided
  - Modern, professional design
  - Mobile responsive

- [ ] Create templates/website CSS if not AI-generated

- [ ] Implement `website` command in CLI

- [ ] Add to `generate` command workflow (after cover_letter)

- [ ] Create tests for WebsiteGenerator

**Validation**: `./bin/jojo website -e "Acme Corp" -j test_job.txt` generates website/ with index.html

## Phase 7: PDF Generation and Polish

**Goal**: Convert markdown to PDF, add interview prep, finalize workflow

### Tasks:

- [ ] Create `lib/jojo/pdf_generator.rb`
  - Use Pandoc to convert resume.md → resume.pdf
  - Use Pandoc to convert cover_letter.md → cover_letter.pdf
  - Handle Pandoc errors gracefully
  - Log to status_log

- [ ] Add PDF generation to `generate` workflow

- [ ] Create `lib/jojo/generators/interview_prep_generator.rb`
  - Generate interview_prep.md based on research and job description
  - Common interview questions
  - Company-specific preparation tips
  - STAR method examples from resume

- [ ] Add interview prep to `generate` workflow

- [ ] Improve `status_log.md` formatting
  - Timestamps for each step
  - Token usage statistics
  - Decisions made (AI model used, etc.)

- [ ] Add verbose mode logging throughout

- [ ] Error handling and user-friendly messages

- [ ] Create comprehensive README.md
  - Installation instructions
  - Usage examples
  - Configuration guide
  - Troubleshooting

**Validation**: `./bin/jojo generate -e "Acme Corp" -j test_job.txt` creates complete application package with PDFs

## Testing Strategy

- **Unit tests**: Test each generator, processor, and utility class in isolation
- **Integration tests**: Test full `generate` workflow end-to-end
- **Fixtures**: Create sample job descriptions and generic resumes for testing
- **Run tests**: `./bin/jojo test` or `ruby -Ilib:test test/**/*_test.rb`

## Future Enhancements (Post-v1)

- [ ] Application tracking: list all employers, status, dates
- [ ] Template system: multiple resume formats, website themes
- [ ] Direct Hugo integration: generate into personal site repo
- [ ] Email draft generation
- [ ] LinkedIn message templates
- [ ] Follow-up tracking and reminders
- [ ] Analytics: which applications got responses
- [ ] Multi-model support: OpenAI, local models
- [ ] Interactive mode: ask questions during generation
- [ ] Resume optimization suggestions
- [ ] Skill gap analysis

## Development Workflow

1. Create feature branch for each phase
2. Implement tasks in order
3. Write tests as you go
4. Run tests frequently
5. Commit with conventional commit format
6. When phase is complete, test end-to-end
7. Merge to main

## Notes

- Start simple, add complexity as needed
- Focus on working software over perfect code
- Use AI to generate initial templates and content
- Test with real job descriptions early
- Iterate based on actual usage
