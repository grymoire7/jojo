# Phase 4: Resume Generation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build resume generation feature that creates tailored resumes using conservative tailoring with strategic pruning.

**Architecture:** ResumeGenerator follows ResearchGenerator pattern, using text_generation_ai to transform generic resume into targeted version. ResumePrompt module provides prompt templates. Config extended to include base_url for landing page links.

**Tech Stack:** Ruby 3.4.5, ruby-llm gem, Minitest, Thor CLI, ERB templates

---

## Task 1: Update Configuration for base_url

**Files:**
- Modify: `templates/config.yml.erb`
- Modify: `lib/jojo/config.rb`
- Test: `test/unit/config_test.rb`

### Step 1: Write failing test for base_url config

Add to `test/unit/config_test.rb` after existing tests:

```ruby
it "returns base_url from config" do
  config = Jojo::Config.new('test/fixtures/test_config.yml')
  _(config.base_url).must_equal "https://tracyatteberry.com"
end

it "validates base_url is present" do
  # Create config without base_url
  File.write('test/fixtures/invalid_config.yml', <<~YAML
    seeker_name: Test User
    reasoning_ai:
      service: anthropic
      model: sonnet
  YAML
  )

  config = Jojo::Config.new('test/fixtures/invalid_config.yml')
  error = assert_raises(SystemExit) do
    config.base_url
  end
end
```

### Step 2: Run test to verify it fails

Run: `./bin/jojo test --unit`
Expected: FAIL with "undefined method `base_url'"

### Step 3: Add base_url to config template

In `templates/config.yml.erb`, add after seeker_name:

```yaml
seeker_name: <%= seeker_name %>
base_url: <%= base_url %>
reasoning_ai:
  service: anthropic
  model: sonnet
text_generation_ai:
  service: anthropic
  model: haiku
voice_and_tone: professional and friendly
```

### Step 4: Add base_url method to Config class

In `lib/jojo/config.rb`, add method after `voice_and_tone`:

```ruby
def base_url
  url = config['base_url']
  if url.nil? || url.strip.empty?
    abort "Error: base_url is required in config.yml"
  end
  url
end
```

### Step 5: Update test fixture with base_url

In `test/fixtures/test_config.yml`, add:

```yaml
base_url: https://tracyatteberry.com
```

### Step 6: Run tests to verify they pass

Run: `./bin/jojo test --unit`
Expected: PASS

### Step 7: Commit configuration changes

```bash
git add templates/config.yml.erb lib/jojo/config.rb test/unit/config_test.rb test/fixtures/test_config.yml
git commit -m "feat: add base_url to configuration"
```

---

## Task 2: Update Setup Command for base_url

**Files:**
- Modify: `lib/jojo/cli.rb` (create_config_yml method)

### Step 1: Update create_config_yml to prompt for base_url

In `lib/jojo/cli.rb`, modify `create_config_yml` method:

```ruby
def create_config_yml(errors)
  seeker_name = ask("Your name:")

  if seeker_name.strip.empty?
    errors << "Name is required for config.yml"
    return
  end

  base_url = ask("Your website base URL (e.g., https://yourname.com):")

  if base_url.strip.empty?
    errors << "Base URL is required for config.yml"
    return
  end

  begin
    template = ERB.new(File.read('templates/config.yml.erb'))
    File.write('config.yml', template.result(binding))
    say "✓ Created config.yml", :green
  rescue => e
    errors << "Failed to create config.yml: #{e.message}"
  end
end
```

### Step 2: Manually test setup command

Run: `./bin/jojo setup` (in a test directory)
Expected: Prompts for name and base_url, creates config.yml with both fields

### Step 3: Commit setup command changes

```bash
git add lib/jojo/cli.rb
git commit -m "feat: prompt for base_url in setup command"
```

---

## Task 3: Create ResumePrompt Module

**Files:**
- Create: `lib/jojo/prompts/resume_prompt.rb`
- Test: `test/unit/prompts/resume_prompt_test.rb`

### Step 1: Write failing test for prompt generation

Create `test/unit/prompts/resume_prompt_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/prompts/resume_prompt'

describe Jojo::Prompts::Resume do
  it "generates prompt with all inputs" do
    job_description = "Senior Ruby Developer role..."
    research = "# Company Profile\n\nAcme Corp..."
    generic_resume = "# Jane Doe\n\n## Experience..."
    job_details = { 'job_title' => 'Senior Ruby Developer', 'company_name' => 'Acme Corp' }
    voice_and_tone = "professional and friendly"

    prompt = Jojo::Prompts::Resume.generate_prompt(
      job_description: job_description,
      research: research,
      generic_resume: generic_resume,
      job_details: job_details,
      voice_and_tone: voice_and_tone
    )

    _(prompt).must_include "Senior Ruby Developer"
    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "Jane Doe"
    _(prompt).must_include "professional and friendly"
    _(prompt).must_include "PRESERVE"
    _(prompt).must_include "PRUNE"
  end

  it "generates prompt without optional inputs" do
    job_description = "Ruby Developer role..."
    generic_resume = "# Jane Doe..."

    prompt = Jojo::Prompts::Resume.generate_prompt(
      job_description: job_description,
      research: nil,
      generic_resume: generic_resume,
      job_details: nil,
      voice_and_tone: "professional"
    )

    _(prompt).must_include "Ruby Developer"
    _(prompt).must_include "Jane Doe"
    _(prompt).wont_include "# Company Profile"
  end
end
```

### Step 2: Run test to verify it fails

Run: `./bin/jojo test --unit`
Expected: FAIL with "uninitialized constant Jojo::Prompts::Resume"

### Step 3: Create ResumePrompt module

Create `lib/jojo/prompts/resume_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module Resume
      def self.generate_prompt(job_description:, generic_resume:, research: nil, job_details: nil, voice_and_tone:)
        <<~PROMPT
          You are an expert resume writer helping tailor a generic resume to a specific job opportunity.

          Your task is to transform the generic resume using CONSERVATIVE TAILORING WITH STRATEGIC PRUNING:
          - Maintain truthfulness and structure
          - Filter out less relevant content (keep 60-80% most relevant)
          - Optimize keyword usage and phrasing

          # Job Information

          ## Job Description

          #{job_description}

          #{job_details ? format_job_details(job_details) : ""}

          #{research ? "## Research Insights\n\n#{research}" : ""}

          # Source Material

          ## Generic Resume

          #{generic_resume}

          # Tailoring Instructions

          ## PRESERVE (Do not modify):
          - All dates, job titles, company names
          - All degrees, certifications, educational credentials
          - Truthfulness of all achievements and responsibilities

          ## PRUNE (Strategic filtering):
          - Remove skills that don't align with job requirements
          - Remove projects/experiences with low relevance
          - Remove bullet points that don't support the target role
          - KEEP 60-80% of most relevant content

          ## OPTIMIZE (Improve without fabrication):
          - Rewrite professional summary to target this specific role
          - Reorder items within sections (most relevant first)
          - Rephrase bullet points to include job description keywords
          - Match company culture and language from research
          - Use action verbs and quantifiable results from original

          # Output Requirements

          ## Format:
          - Clean markdown matching the generic resume structure
          - Same section headings as original resume
          - ATS-friendly (no tables, simple bullets with -)
          - Target 1-2 pages of content

          ## Voice and Tone:
          #{voice_and_tone}

          ## Quality Standards:
          - Every statement must be truthful (no fabrication)
          - Use strong action verbs (led, built, designed, implemented)
          - Include quantifiable results where present in original
          - Maintain professional formatting and consistency

          # Important:
          - Do NOT add experiences, skills, or achievements not in the generic resume
          - Do NOT modify dates or factual details
          - Focus on SELECTING and REPHRASING existing content strategically
          - Output ONLY the tailored resume markdown, no commentary
        PROMPT
      end

      private

      def self.format_job_details(job_details)
        return "" unless job_details

        <<~DETAILS
          ## Structured Job Details

          #{job_details.map { |k, v| "- #{k}: #{v}" }.join("\n")}
        DETAILS
      end
    end
  end
end
```

### Step 4: Run tests to verify they pass

Run: `./bin/jojo test --unit`
Expected: PASS

### Step 5: Commit prompt module

```bash
git add lib/jojo/prompts/resume_prompt.rb test/unit/prompts/resume_prompt_test.rb
git commit -m "feat: add resume generation prompt module"
```

---

## Task 4: Create ResumeGenerator Class

**Files:**
- Create: `lib/jojo/generators/resume_generator.rb`
- Test: `test/unit/generators/resume_generator_test.rb`

### Step 1: Write failing tests for ResumeGenerator

Create `test/unit/generators/resume_generator_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/resume_generator'
require_relative '../../../lib/jojo/prompts/resume_prompt'

describe Jojo::Generators::ResumeGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::ResumeGenerator.new(@employer, @ai_client, config: @config, verbose: false)

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
    FileUtils.mkdir_p('inputs')
    File.write('inputs/generic_resume.md', "# Jane Doe\n\n## Professional Summary\n\nExperienced developer...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    FileUtils.rm_f('inputs/generic_resume.md')
    @config.verify if @config
  end

  it "generates resume from all inputs" do
    expected_resume = "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer..."
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    result = @generator.generate

    _(result).must_include "Specifically for Acme Corp"
    _(result).must_include "https://tracyatteberry.com/resume/acme-corp"
    _(result).must_include expected_resume

    @ai_client.verify
    @config.verify
  end

  it "saves resume to file" do
    expected_resume = "# Jane Doe\n\nTailored content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    @generator.generate

    _(File.exist?(@employer.resume_path)).must_equal true
    content = File.read(@employer.resume_path)
    _(content).must_include "Specifically for Acme Corp"
    _(content).must_include expected_resume

    @ai_client.verify
    @config.verify
  end

  it "fails when generic resume is missing" do
    FileUtils.rm_f('inputs/generic_resume.md')

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Generic resume not found"
  end

  it "fails when job description is missing" do
    FileUtils.rm_f(@employer.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  it "continues when research is missing with warning" do
    FileUtils.rm_f(@employer.research_path)

    expected_resume = "# Jane Doe\n\nContent without research..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    # Should not raise error
    result = @generator.generate
    _(result).must_include expected_resume

    @ai_client.verify
    @config.verify
  end

  it "generates correct landing page link" do
    expected_resume = "Resume content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_resume, [String])

    result = @generator.generate

    _(result).must_include "**Specifically for Acme Corp**: https://tracyatteberry.com/resume/acme-corp"

    @ai_client.verify
    @config.verify
  end
end
```

### Step 2: Run test to verify it fails

Run: `./bin/jojo test --unit`
Expected: FAIL with "uninitialized constant Jojo::Generators::ResumeGenerator"

### Step 3: Create ResumeGenerator class

Create `lib/jojo/generators/resume_generator.rb`:

```ruby
require 'yaml'

module Jojo
  module Generators
    class ResumeGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        log "Gathering inputs for resume generation..."
        inputs = gather_inputs

        log "Building resume prompt..."
        prompt = build_resume_prompt(inputs)

        log "Generating tailored resume using AI..."
        resume = call_ai(prompt)

        log "Adding landing page link..."
        resume_with_link = add_landing_page_link(resume, inputs)

        log "Saving resume to #{employer.resume_path}..."
        save_resume(resume_with_link)

        log "Resume generation complete!"
        resume_with_link
      end

      private

      def gather_inputs
        # Read job description (REQUIRED)
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Read generic resume (REQUIRED)
        unless File.exist?('inputs/generic_resume.md')
          raise "Generic resume not found at inputs/generic_resume.md"
        end
        generic_resume = File.read('inputs/generic_resume.md')

        # Read research (OPTIONAL)
        research = read_research

        # Read job details (OPTIONAL)
        job_details = read_job_details

        {
          job_description: job_description,
          generic_resume: generic_resume,
          research: research,
          job_details: job_details,
          company_name: employer.name,
          company_slug: employer.slug
        }
      end

      def read_research
        unless File.exist?(employer.research_path)
          log "Warning: Research not found at #{employer.research_path}, resume will be less targeted"
          return nil
        end

        File.read(employer.research_path)
      end

      def read_job_details
        unless File.exist?(employer.job_details_path)
          return nil
        end

        YAML.load_file(employer.job_details_path)
      rescue => e
        log "Warning: Could not parse job details: #{e.message}"
        nil
      end

      def build_resume_prompt(inputs)
        Prompts::Resume.generate_prompt(
          job_description: inputs[:job_description],
          generic_resume: inputs[:generic_resume],
          research: inputs[:research],
          job_details: inputs[:job_details],
          voice_and_tone: config.voice_and_tone
        )
      end

      def call_ai(prompt)
        ai_client.generate_text(prompt)
      end

      def add_landing_page_link(resume_content, inputs)
        link = "**Specifically for #{inputs[:company_name]}**: #{config.base_url}/resume/#{inputs[:company_slug]}"
        "#{link}\n\n#{resume_content}"
      end

      def save_resume(content)
        File.write(employer.resume_path, content)
      end

      def log(message)
        puts "  [ResumeGenerator] #{message}" if verbose
      end
    end
  end
end
```

### Step 4: Run tests to verify they pass

Run: `./bin/jojo test --unit`
Expected: PASS

### Step 5: Commit resume generator

```bash
git add lib/jojo/generators/resume_generator.rb test/unit/generators/resume_generator_test.rb
git commit -m "feat: add ResumeGenerator class with tests"
```

---

## Task 5: Wire Up Resume Command in CLI

**Files:**
- Modify: `lib/jojo/cli.rb`

### Step 1: Add require for ResumeGenerator

At top of `lib/jojo/cli.rb`, add after research_generator require:

```ruby
require_relative 'generators/resume_generator'
```

### Step 2: Implement resume command

Replace the placeholder `resume` method:

```ruby
desc "resume", "Generate tailored resume only"
def resume
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
  status_logger = Jojo::StatusLogger.new(employer)

  say "Generating resume for #{employer.name}...", :green

  # Ensure employer directory exists
  employer.create_directory! unless Dir.exist?(employer.base_path)

  # Check that job description has been processed
  unless File.exist?(employer.job_description_path)
    say "✗ Job description not found. Run 'generate' first or provide job description.", :red
    exit 1
  end

  # Check that research has been generated
  unless File.exist?(employer.research_path)
    say "⚠ Warning: Research not found. Resume will be less targeted.", :yellow
  end

  # Check that generic resume exists
  unless File.exist?('inputs/generic_resume.md')
    say "✗ Generic resume not found at inputs/generic_resume.md", :red
    say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
    exit 1
  end

  begin
    generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
    resume = generator.generate

    say "✓ Resume generated and saved to #{employer.resume_path}", :green

    status_logger.log_step("Resume Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )

    say "\n✓ Resume complete!", :green
  rescue => e
    say "✗ Error generating resume: #{e.message}", :red
    status_logger.log_step("Resume Generation", status: "failed", error: e.message)
    exit 1
  end
end
```

### Step 3: Manually test resume command

Run: `./bin/jojo resume -e "Test Corp" -j test.txt` (after setting up test data)
Expected: Generates resume with landing page link

### Step 4: Commit CLI resume command

```bash
git add lib/jojo/cli.rb
git commit -m "feat: implement resume command in CLI"
```

---

## Task 6: Integrate Resume into Generate Command

**Files:**
- Modify: `lib/jojo/cli.rb` (generate method)

### Step 1: Add resume generation to generate workflow

In `lib/jojo/cli.rb`, replace the yellow message at end of generate method with:

```ruby
      # Generate resume
      begin
        unless File.exist?('inputs/generic_resume.md')
          say "⚠ Warning: Generic resume not found, skipping resume generation", :yellow
          say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
        else
          generator = Jojo::Generators::ResumeGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
          generator.generate

          say "✓ Resume generated and saved", :green
          status_logger.log_step("Resume Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete"
          )
        end
      rescue => e
        say "✗ Error generating resume: #{e.message}", :red
        status_logger.log_step("Resume Generation", status: "failed", error: e.message)
        exit 1
      end

      say "\n✓ Generation complete through Phase 4. Cover letter coming in Phase 5.", :yellow
    end
```

### Step 2: Manually test generate command

Run: `./bin/jojo generate -e "Test Corp" -j test.txt`
Expected: Runs job description processing, research, then resume generation

### Step 3: Commit generate integration

```bash
git add lib/jojo/cli.rb
git commit -m "feat: integrate resume generation into generate command"
```

---

## Task 7: Add Test Fixture for Generic Resume

**Files:**
- Create: `test/fixtures/generic_resume.md`

### Step 1: Create realistic generic resume fixture

Create `test/fixtures/generic_resume.md`:

```markdown
# Jane Doe

## Contact Information
- Email: jane.doe@example.com
- Phone: (555) 123-4567
- LinkedIn: linkedin.com/in/janedoe
- GitHub: github.com/janedoe

## Professional Summary

Experienced software engineer with 8+ years building scalable web applications. Strong expertise in Ruby, Python, JavaScript, and cloud infrastructure. Proven track record of leading teams and delivering high-impact projects.

## Skills

### Programming Languages
- Ruby (expert)
- Python (proficient)
- JavaScript/TypeScript (proficient)
- Go (intermediate)
- Java (intermediate)
- PHP (beginner)

### Frameworks & Libraries
- Ruby on Rails
- React
- Vue.js
- Django
- Flask
- Node.js
- Express

### Tools & Technologies
- Git, Docker, Kubernetes
- PostgreSQL, MySQL, MongoDB, Redis
- AWS, GCP, Heroku
- CI/CD (GitHub Actions, Jenkins, CircleCI)
- Elasticsearch, RabbitMQ
- GraphQL, REST APIs

### Soft Skills
- Technical leadership
- Mentoring and coaching
- Agile/Scrum methodologies
- Cross-functional collaboration
- Technical writing

## Work Experience

### Senior Software Engineer | Tech Company Inc
*Jan 2020 - Present* | San Francisco, CA

- Led team of 5 engineers building customer-facing SaaS platform serving 10,000+ users
- Architected and implemented microservices migration reducing deployment time by 60%
- Designed and built real-time notification system processing 1M+ events daily [Ruby, Redis, WebSockets]
- Mentored 3 junior engineers, all promoted within 18 months
- Reduced system latency by 40% through database optimization and caching strategies
- Implemented comprehensive test suite increasing code coverage from 45% to 95%

### Software Engineer | StartupCo
*Mar 2017 - Dec 2019* | Remote

- Built MVP for B2B marketplace platform from scratch, acquired 100+ paying customers in first year [Rails, React]
- Developed payment processing integration with Stripe handling $2M+ in transactions
- Implemented OAuth2 authentication and authorization system
- Created automated deployment pipeline reducing release time from 2 hours to 15 minutes
- Collaborated with design team to build responsive UI supporting mobile and desktop
- Wrote technical documentation and API guides for external developers

### Junior Developer | Digital Agency LLC
*Jun 2015 - Feb 2017* | New York, NY

- Developed custom WordPress plugins and themes for 20+ client projects
- Built RESTful APIs for mobile app backends [Node.js, Express]
- Maintained legacy PHP applications and performed security updates
- Participated in code reviews and pair programming sessions
- Managed client communication and gathered technical requirements
- Implemented analytics tracking and reporting dashboards

## Education

### Bachelor of Science in Computer Science | State University
*2011 - 2015* | Boston, MA

- GPA: 3.7/4.0
- Dean's List: 6 semesters
- Relevant coursework: Data Structures, Algorithms, Database Systems, Software Engineering

## Projects

### Open Source Contributions
- Contributor to popular Rails testing gem (200+ stars on GitHub)
- Maintained Ruby static analysis tool with 500+ weekly downloads
- Created command-line productivity tool featured in Ruby Weekly newsletter

### Personal Projects
- Built meal planning SaaS with 1,000+ registered users [Rails, React, PostgreSQL]
- Developed browser extension for productivity tracking (5,000+ installs)
- Created technical blog with 50+ articles on software engineering topics

## Certifications
- AWS Certified Solutions Architect - Associate, 2021
- Certified Scrum Master (CSM), 2019
```

### Step 2: Commit test fixture

```bash
git add test/fixtures/generic_resume.md
git commit -m "test: add generic resume fixture for testing"
```

---

## Task 8: Update Implementation Plan Documentation

**Files:**
- Modify: `docs/plans/implementation_plan.md`

### Step 1: Mark Phase 4 tasks as complete

Update Phase 4 section in `docs/plans/implementation_plan.md`:

```markdown
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
```

### Step 2: Commit documentation updates

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 4 as complete in implementation plan"
```

---

## Testing & Validation

After completing all tasks:

1. **Run full test suite**: `./bin/jojo test --all`
   - All tests should pass

2. **Manual end-to-end test**:
   ```bash
   ./bin/jojo setup  # Set up with base_url
   # Add generic resume to inputs/
   ./bin/jojo generate -e "Acme Corp" -j test_job.txt
   # Verify resume.md contains:
   # - Landing page link with correct URL
   # - Tailored content
   # - Markdown formatting
   ```

3. **Test standalone resume command**:
   ```bash
   ./bin/jojo resume -e "Acme Corp" -j test_job.txt
   # Should generate resume only
   ```

4. **Test error cases**:
   ```bash
   # Missing generic resume
   rm inputs/generic_resume.md
   ./bin/jojo resume -e "Test" -j test.txt
   # Should fail with helpful error

   # Missing research (warning, continues)
   rm employers/test/research.md
   ./bin/jojo resume -e "Test" -j test.txt
   # Should warn but continue
   ```

---

## Success Criteria

- ✅ All unit tests pass
- ✅ `base_url` configuration works in setup and config
- ✅ ResumeGenerator follows established patterns (matches ResearchGenerator)
- ✅ Resume command generates tailored resume with landing page link
- ✅ Generate command includes resume generation step
- ✅ Error handling works for missing inputs
- ✅ Graceful degradation for optional inputs (research)
- ✅ Landing page link uses deterministic URL format
- ✅ Implementation plan documentation updated
- ✅ All changes committed with conventional commit messages

---

## Notes

- Follow DRY principle - reuse patterns from ResearchGenerator
- Follow YAGNI - only implement what's specified, no extras
- Use TDD - write tests first, implement to make them pass
- Commit frequently - after each task completion
- If AI responses are unexpected, adjust prompt in ResumePrompt module
