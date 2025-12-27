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

## Phase 1: CLI Framework and Configuration ✅

**Goal**: Working CLI with help, version, and setup command

**Status**: COMPLETED

### Tasks:

- [x] Create `Thorfile` with basic tasks structure
  ```ruby
  require_relative 'lib/jojo'
  require_relative 'lib/jojo/cli'
  ```

- [x] Create `lib/jojo/cli.rb` - Thor CLI class
  - `desc` and method for each command
  - Class options for `-e/--employer`, `-j/--job`, `-v/--verbose`
  - Commands: `setup`, `generate`, `research`, `resume`, `cover_letter`, `website`, `test`

- [x] Create `bin/jojo` wrapper script
  ```ruby
  #!/usr/bin/env ruby
  require_relative '../lib/jojo'
  require_relative '../lib/jojo/cli'

  Jojo::CLI.start(ARGV)
  ```
  - Make executable: `chmod +x bin/jojo`

- [x] Implement `setup` command in `lib/jojo/commands/setup.rb`
  - Check for existing `config.yml`, prompt to overwrite if exists
  - Create `config.yml` from `templates/config.yml.erb`
  - Prompt for seeker_name
  - Create `.env` if doesn't exist, prompt for ANTHROPIC_API_KEY
  - Create `inputs/` directory if doesn't exist
  - Provide instructions on what to put in `inputs/`

- [x] Create `templates/config.yml.erb`
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

- [x] Create `templates/generic_resume.md` - example resume

- [x] Create `templates/recommendations.md` - example recommendations

- [x] Create `lib/jojo/config.rb` - Configuration loader
  - Load and parse `config.yml`
  - Validate required fields
  - Provide accessor methods

- [x] Add tests for Config class

**Validation**: ✅ All criteria met, tests passing

## Phase 2: Job Description Processing ✅

**Goal**: Process job description from file or URL, save to employer directory

**Status**: COMPLETED

### Tasks:

- [x] Create `lib/jojo/employer.rb` - Employer class
  - Generate slug from employer name
  - Create employer directory structure
  - Provide paths to all employer files (including job_description_raw_path and job_details_path)

- [x] Create `lib/jojo/ai_client.rb` - Wrapper for ruby-llm
  - Initialize with config (API key, model selection)
  - Methods for reasoning vs text generation
  - Error handling and retries
  - Token usage logging

- [x] Create `lib/jojo/prompts/job_description_prompts.rb`
  - Template for description extraction prompt
  - Template for key details prompt

- [x] Create `lib/jojo/job_description_processor.rb`
  - Handle file input: read markdown/text file
  - Handle URL input: fetch HTML, convert to markdown using html-to-markdown gem
  - Save raw markdown as `employers/#{slug}/job_description_raw.md` (for URLs)
  - Use AI to extract clean job description to `employers/#{slug}/job_description.md`
  - Extract key details using AI and save as `employers/#{slug}/job_details.yml`

- [x] Add `html-to-markdown` gem (v2.16) to Gemfile

- [x] Create tests for JobDescriptionProcessor (27 tests passing)

- [x] Wire up `generate` command to:
  - Validate required options (`-e` and `-j`)
  - Create employer directory
  - Process and save job description
  - Log to `status_log.md`

**Validation**: ✅ Command structure validated. Directory creation and file processing work correctly. Full end-to-end test requires valid Anthropic API key in `.env`

## Phase 3: Research Generation ✅

**Goal**: Generate company/role research using AI

**Status**: COMPLETED

### Tasks:

- [x] Create `lib/jojo/status_logger.rb`
  - Log entries with timestamps
  - Markdown formatting
  - Append to status_log.md
  - Metadata support for step logging

- [x] Create `lib/jojo/prompts/research_prompt.rb`
  - Template for research generation prompt
  - Include job description, web search results, generic resume
  - Request company research, role analysis, strategic positioning, tailoring recommendations
  - Output format specification (markdown sections)
  - Graceful degradation when inputs are missing

- [x] Create `lib/jojo/generators/research_generator.rb`
  - Read job description
  - Read generic resume from inputs/
  - Extract company name from job details
  - Perform web search using deepsearch-rb gem
  - Build comprehensive prompt
  - Call AI (reasoning model)
  - Save to `employers/#{slug}/research.md`
  - Graceful error handling

- [x] Implement `research` command in CLI
  - Run research generator only
  - Use StatusLogger for logging

- [x] Add to `generate` command workflow
  - Run after job description processing
  - Before resume generation (Phase 4)

- [x] Create tests for StatusLogger
  - Test log creation and appending
  - Test timestamp formatting
  - Test metadata logging

- [x] Create tests for ResearchGenerator
  - Mock AI responses
  - Mock web search results
  - Test graceful degradation
  - Test error handling

- [x] Add deepsearch-rb integration
  - Add gem to Gemfile
  - Update Config to support search_provider settings
  - Configure search provider (serper, tavily, searxng, duckduckgo)
  - Graceful degradation when search provider not configured

**Validation**: ✅ `./bin/jojo research -e "Acme Corp" -j test_job.txt` generates research.md with relevant company insights, role analysis, strategic positioning, and tailoring recommendations. Status log is updated. Tests pass without calling third-party APIs.

**Notes**:
- Web search functionality uses deepsearch-rb gem (user-configurable search provider)
- Requires search provider configuration in config.yml (optional but recommended)
- In standalone execution without search config, research uses job description only
- Generic resume (inputs/generic_resume.md) is optional but recommended for personalized research

## Phase 4: Resume Generation ✅

**Goal**: Generate tailored resume from generic resume + job description + research

**Status**: COMPLETED

### Tasks:

- [x] Create `lib/jojo/generators/resume_generator.rb`
  - Read `inputs/generic_resume.md`
  - Read job description and research
  - Build tailoring prompt
  - Call AI (text generation model)
  - Save to `employers/#{slug}/resume.md`
  - Include link to landing page in resume
  - Log to status_log

- [x] Create `lib/jojo/prompts/resume_prompt.rb`
  - Instructions for tailoring resume
  - Emphasis on relevance to job description
  - Use research insights
  - Maintain voice and tone from config
  - Output markdown format

- [x] Implement `resume` command in CLI

- [x] Add to `generate` command workflow (after research)

- [x] Create tests for ResumeGenerator

- [x] Update configuration for base_url field

**Validation**: ✅ `./bin/jojo resume -e "Acme Corp" -j test_job.txt` generates tailored resume.md with landing page link

## Phase 5: Cover Letter Generation ✅

**Goal**: Generate cover letter based on research and tailored resume

**Status**: COMPLETED

### Tasks:

- [x] Create `lib/jojo/generators/cover_letter_generator.rb`
  - Read job description, research, and tailored resume
  - Build cover letter prompt
  - Call AI (text generation model)
  - Save to `employers/#{slug}/cover_letter.md`
  - Include link to landing page
  - Log to status_log

- [x] Create `lib/jojo/prompts/cover_letter_prompt.rb`
  - Instructions for professional cover letter
  - Use research insights
  - Reference specific qualifications from resume
  - Include call to action
  - Voice and tone from config

- [x] Implement `cover_letter` command in CLI

- [x] Add to `generate` command workflow (after resume)

- [x] Create tests for CoverLetterGenerator

**Validation**: ✅ `./bin/jojo cover_letter -e "Acme Corp" -j test_job.txt` generates cover_letter.md with landing page link. Tests passing.

## Phase 6: Website Generation

**Goal**: Generate comprehensive landing page for job applications

**Status**: IN PROGRESS

**Design Decisions**:
- **Architecture**: Template-based system with AI-generated content (not AI-generated HTML/CSS)
- **Template Strategy**: Multiple templates supported via `--template` CLI flag, with `default` as baseline
- **AI Role**: Generates content only (branding statements, portfolio descriptions, etc.), not styling
- **Approach**: Phased implementation - build foundation first, then add interactive features incrementally
- **Landing Page Sections** (full vision):
  - Masthead with "Am I a good match?" messaging
  - Annotated job description with hover-over explanations
  - Recommendation quotes (carousel)
  - Relevant work project highlights
  - FAQ accordion (tech stack, remote work, AI philosophy, resume/cover letter links)
  - Tailored personal branding statement
  - Clear CTA (Calendly/contact)

### Phase 6a: Foundation & Core Content ✅

**Goal**: Template system, basic landing page, AI-generated branding

**Status**: COMPLETED

**Design Document**: `docs/plans/2025-12-26-phase-6a-website-generation-design.md`

#### Tasks:

- [x] Create `lib/jojo/generators/website_generator.rb`
  - Read context (job description, research, resume)
  - Generate personalized branding statement via AI
  - Support multiple templates via `template:` parameter
  - Render template with ERB
  - Copy branding image from inputs/ if exists
  - Save to `employers/#{slug}/website/index.html`
  - Log to status_log

- [x] Create `lib/jojo/prompts/website_prompt.rb`
  - Branding statement generation prompt
  - Use text_generation_ai (Haiku)
  - 2-3 paragraphs, 150-250 words
  - Focus on "why me for this company"
  - Graceful degradation without research

- [x] Create `templates/website/default.html.erb`
  - Complete HTML5 document with inline CSS
  - Responsive design (mobile-friendly)
  - Sections: masthead, branding statement, CTA, footer
  - Template variables: seeker_name, company_name, job_title, branding_statement, cta_text, cta_link, branding_image
  - No JavaScript (static content only)

- [x] Add `--template` CLI option
  - Add class option to CLI: `--template NAME` (alias: `-t`)
  - Default to 'default' template
  - Pass to WebsiteGenerator

- [x] Update `lib/jojo/config.rb`
  - Add `website_cta_text` method with default
  - Add `website_cta_link` method (returns nil if not configured)

- [x] Update `templates/config.yml.erb`
  - Add `website:` section with `cta_text` and `cta_link`

- [x] Implement `website` command in CLI
  - Generate website only
  - Support `--template` option

- [x] Add to `generate` command workflow
  - Run after cover_letter generation
  - Pass `--template` option through

- [x] Create `test/unit/website_generator_test.rb`
  - Test with all inputs, minimal inputs, custom template
  - Test error cases (missing template, missing required files)
  - Test branding image handling
  - Test graceful degradation (12 tests)

- [x] Create `test/unit/website_prompt_test.rb`
  - Test prompt includes all required context
  - Test graceful degradation without optional inputs (7 tests)

- [x] Create `test/integration/website_workflow_test.rb`
  - Test end-to-end website generation
  - Test integration with generate command (5 tests)

- [x] Test fixtures created in test files
  - Custom templates created dynamically in tests
  - Branding images created as needed in tests

**Validation**: ✅
- `./bin/jojo generate -e "CyberCoders" -j inputs/cybercoders.md` successfully generates website/index.html
- Website includes masthead, AI-generated branding statement, CTA, and footer
- All tests pass: 103 tests (98 unit + 5 integration), 403 assertions, 0 failures, 0 errors
- Responsive design works, graceful CTA handling (nil link displays no CTA section)
- Comprehensive test coverage: prompt generation, generator functionality, end-to-end workflows

### Phase 6b: Portfolio Highlights ✅

**Goal**: Display relevant projects and achievements

**Status**: COMPLETED

**Design Document**: `docs/plans/2025-12-27-projects-yaml-design.md`

#### Tasks:

- [x] Create ProjectLoader for YAML loading and validation
- [x] Create ProjectSelector for skill-based matching
- [x] Integrate projects into WebsiteGenerator
- [x] Update default template with projects section
- [x] Add image handling for project images
- [x] Integrate projects into ResumeGenerator
- [x] Integrate projects into CoverLetterGenerator
- [x] Create comprehensive test coverage
- [x] Update templates/projects.yml example

**Validation**: ✅ Landing page includes relevant project highlights selected by skill matching. Resume and cover letter prompts include relevant projects for AI to weave into content. Images are properly handled (copied or linked).

### Phase 6c: Interactive Job Description

**Goal**: Annotated job description with hover tooltips

**Status**: PLANNED

#### Tasks:

- [ ] AI annotates job description
  - Identify key requirements
  - Match to candidate experience
  - Generate hover tooltip content

- [ ] Add JavaScript for hover interactions
  - Tooltip positioning
  - Highlighting system
  - Mobile-friendly tap interactions

- [ ] Update template with annotated job description section
  - "Compare me to the Job Description" heading
  - Highlighted terms with data attributes

- [ ] Create tests for annotation generation

**Validation**: Job description terms have hover tooltips showing relevant experience

### Phase 6d: Recommendations Carousel

**Goal**: Display recommendation quotes with carousel

**Status**: PLANNED

#### Tasks:

- [ ] Parse `inputs/recommendations.md`
  - Extract individual recommendations
  - Parse author/relationship metadata

- [ ] Create carousel JavaScript component
  - Auto-advance with manual controls
  - Responsive design

- [ ] Update template with recommendations section
  - "What do my co-workers say?" heading
  - Carousel container

- [ ] Create tests for recommendation parsing

**Validation**: Recommendations display in rotating carousel

### Phase 6e: FAQ Accordion

**Goal**: Interactive FAQ with accordion UI

**Status**: PLANNED

#### Tasks:

- [ ] AI generates role-specific FAQs
  - Standard questions (tech stack, remote work, AI philosophy)
  - Custom questions based on job description
  - Answers based on resume, research, inputs

- [ ] Create accordion JavaScript component
  - Expand/collapse interactions
  - Keyboard accessible

- [ ] Update template with FAQ section
  - "Your questions, answered" heading
  - Accordion container
  - Links to resume.pdf, cover_letter.pdf in answers

- [ ] Create tests for FAQ generation

**Validation**: FAQ accordion displays with standard + custom questions. Resume/cover letter download links work.

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

## Test Organization

**Structure**: Tests are organized by category in separate directories:

- `test/unit/` - Fast unit tests with no external dependencies (default)
- `test/integration/` - Integration tests with mocked external services
- `test/service/` - Tests that call real external APIs (Serper, OpenAI, etc.)

**Running Tests**:

```bash
./bin/jojo test                       # Unit tests only (fast, default)
./bin/jojo test --all                 # All test categories
./bin/jojo test --unit --integration  # Multiple categories
./bin/jojo test --service             # Service tests (confirmation required)
./bin/jojo test -q                    # Quiet mode
```

**Decision Rule**:
- Real external service call → `test/service/`
- Mocked external service → `test/integration/` or `test/unit/`
- Pure unit logic → `test/unit/`

**Environment Variables**:
- `SKIP_SERVICE_CONFIRMATION=true` - Skip confirmation prompt for service tests (useful for CI)

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
