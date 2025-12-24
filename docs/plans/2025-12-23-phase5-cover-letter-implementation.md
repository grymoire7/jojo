# Phase 5: Cover Letter Generation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement cover letter generation that creates compelling "why this company" narratives complementing the tailored resume.

**Architecture:** Follow existing generator pattern (ResumeGenerator, ResearchGenerator). Create CoverLetterPrompt module for AI instructions, CoverLetterGenerator class with TDD approach, integrate into CLI standalone command and generate workflow.

**Tech Stack:** Ruby 3.4.5, Thor (CLI), Minitest (testing), ruby-llm (AI client)

**Design Reference:** `docs/plans/2025-12-23-cover-letter-design.md`

---

## Task 1: Create Cover Letter Prompt Module

**Files:**
- Create: `lib/jojo/prompts/cover_letter_prompt.rb`
- Reference: `lib/jojo/prompts/resume_prompt.rb` (pattern)

**Step 1: Create prompt module with generate_prompt method**

```ruby
module Jojo
  module Prompts
    module CoverLetter
      def self.generate_prompt(job_description:, tailored_resume:, generic_resume:, research: nil, job_details: nil, voice_and_tone:, company_name:)
        <<~PROMPT
          You are an expert cover letter writer helping craft a compelling narrative that complements a tailored resume.

          Your task is to create a cover letter that tells the "WHY THIS COMPANY/ROLE" story, not a resume summary.

          # Job Information

          ## Job Description

          #{job_description}

          #{job_details ? format_job_details(job_details) : ""}

          #{research ? "## Company Research\n\n#{research}" : "Note: No company research available - analyze based on job description only."}

          # Candidate Information

          ## Tailored Resume (What They're Submitting)

          #{tailored_resume}

          ## Full Background (For Additional Context)

          #{generic_resume}

          # Cover Letter Instructions

          ## FOCUS (The "Why" Story):
          - Express genuine enthusiasm for THIS specific company
          - Explain why this role aligns with career goals/journey
          - Connect personal values to company mission/culture
          - Share what excites you about the opportunity
          - Reference specific company insights from research when available

          ## STRUCTURE (Flexible, Adapt to Company Culture):
          - Typical range: 200-400 words, 2-4 paragraphs
          - Adapt length/formality based on company culture signals
          - Modern startups: brief, direct, authentic
          - Traditional corporations: professional, structured, polished
          - Job level matters: senior roles allow more strategic narrative

          ## CONTENT STRATEGY:
          - DO NOT duplicate resume bullet points
          - DO reference 1-2 key experiences briefly with "why" context
          - DO connect career narrative dots between experiences
          - DO show understanding of company mission/values/culture
          - DO make it personal and authentic
          - DO NOT fabricate experiences or achievements

          ## VOICE AND TONE:
          #{voice_and_tone}

          Match company culture from research:
          - Mirror their language style
          - Reflect their values authentically
          - Adapt formality level appropriately

          # Constraints

          ## PRESERVE (Truthfulness):
          - All experiences must be from the resumes
          - No fabrication of skills, achievements, or qualifications
          - Maintain factual accuracy in all claims
          - Reference only real experiences from candidate's background

          ## AVOID:
          - Generic openings ("I am excited to apply...")
          - Resume repetition (listing bullet points)
          - Overly formal corporate-speak (unless company culture demands it)
          - Fabricated enthusiasm or false connections

          # Output Requirements

          ## Format:
          - Clean markdown
          - Professional but warm structure
          - Natural paragraph breaks
          - ATS-friendly (no special formatting)

          ## Quality Standards:
          - Authentic voice (not templated)
          - Specific to THIS company and role
          - Complements resume (doesn't duplicate)
          - Demonstrates research/understanding
          - Clear connection between candidate and opportunity

          # Important:
          - Output ONLY the cover letter text, no commentary
          - DO NOT include date, address header, or signature block (just the letter body)
          - Focus on authentic storytelling, not generic templates
          - Use research insights to show genuine interest in the company
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

**Step 2: Commit prompt module**

```bash
git add lib/jojo/prompts/cover_letter_prompt.rb
git commit -m "feat: add cover letter prompt module"
```

---

## Task 2: Create Cover Letter Generator Tests

**Files:**
- Create: `test/unit/generators/cover_letter_generator_test.rb`
- Reference: `test/unit/generators/resume_generator_test.rb` (pattern)

**Step 1: Create test file with setup/teardown**

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/cover_letter_generator'
require_relative '../../../lib/jojo/prompts/cover_letter_prompt'

describe Jojo::Generators::CoverLetterGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::CoverLetterGenerator.new(@employer, @ai_client, config: @config, verbose: false)

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.resume_path, "# Jane Doe\n\n## Professional Summary\n\nSenior Ruby developer...") # REQUIRED for cover letter
    File.write(@employer.research_path, "# Company Profile\n\nAcme Corp is a leading tech company...")
    FileUtils.mkdir_p('inputs')
    File.write('inputs/generic_resume.md', "# Jane Doe\n\n## Professional Summary\n\nExperienced developer with 10 years...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    FileUtils.rm_f('inputs/generic_resume.md')
    @config.verify if @config
  end

  it "generates cover letter from all inputs" do
    expected_cover_letter = "Dear Hiring Manager,\n\nI am genuinely excited about the opportunity..."
    @config.expect(:voice_and_tone, "professional and friendly")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    result = @generator.generate

    _(result).must_include "Specifically for Acme Corp"
    _(result).must_include "https://tracyatteberry.com/resume/acme-corp"
    _(result).must_include expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  it "saves cover letter to file" do
    expected_cover_letter = "Dear Hiring Manager,\n\nTailored content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    @generator.generate

    _(File.exist?(@employer.cover_letter_path)).must_equal true
    content = File.read(@employer.cover_letter_path)
    _(content).must_include "Specifically for Acme Corp"
    _(content).must_include expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  it "fails when tailored resume is missing" do
    FileUtils.rm_f(@employer.resume_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Tailored resume not found"
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

    expected_cover_letter = "Cover letter without research insights..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    # Should not raise error
    result = @generator.generate
    _(result).must_include expected_cover_letter

    @ai_client.verify
    @config.verify
  end

  it "generates correct landing page link" do
    expected_cover_letter = "Cover letter content..."
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://tracyatteberry.com")
    @ai_client.expect(:generate_text, expected_cover_letter, [String])

    result = @generator.generate

    _(result).must_include "**Specifically for Acme Corp**: https://tracyatteberry.com/resume/acme-corp"

    @ai_client.verify
    @config.verify
  end
end
```

**Step 2: Run tests to verify they fail (generator doesn't exist yet)**

Run: `./bin/jojo test --unit`

Expected output: Error about CoverLetterGenerator constant not defined

**Step 3: Commit test file**

```bash
git add test/unit/generators/cover_letter_generator_test.rb
git commit -m "test: add cover letter generator tests (failing)"
```

---

## Task 3: Create Cover Letter Generator Class

**Files:**
- Create: `lib/jojo/generators/cover_letter_generator.rb`
- Reference: `lib/jojo/generators/resume_generator.rb` (pattern)

**Step 1: Create generator class implementation**

```ruby
require 'yaml'

module Jojo
  module Generators
    class CoverLetterGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        log "Gathering inputs for cover letter generation..."
        inputs = gather_inputs

        log "Building cover letter prompt..."
        prompt = build_cover_letter_prompt(inputs)

        log "Generating cover letter using AI..."
        cover_letter = call_ai(prompt)

        log "Adding landing page link..."
        cover_letter_with_link = add_landing_page_link(cover_letter, inputs)

        log "Saving cover letter to #{employer.cover_letter_path}..."
        save_cover_letter(cover_letter_with_link)

        log "Cover letter generation complete!"
        cover_letter_with_link
      end

      private

      def gather_inputs
        # Read job description (REQUIRED)
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Read tailored resume (REQUIRED - key difference from resume generator)
        unless File.exist?(employer.resume_path)
          raise "Tailored resume not found at #{employer.resume_path}. Run 'jojo resume' or 'jojo generate' first."
        end
        tailored_resume = File.read(employer.resume_path)

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
          tailored_resume: tailored_resume,
          generic_resume: generic_resume,
          research: research,
          job_details: job_details,
          company_name: employer.name,
          company_slug: employer.slug
        }
      end

      def read_research
        unless File.exist?(employer.research_path)
          log "Warning: Research not found at #{employer.research_path}, cover letter will be less targeted"
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

      def build_cover_letter_prompt(inputs)
        Prompts::CoverLetter.generate_prompt(
          job_description: inputs[:job_description],
          tailored_resume: inputs[:tailored_resume],
          generic_resume: inputs[:generic_resume],
          research: inputs[:research],
          job_details: inputs[:job_details],
          voice_and_tone: config.voice_and_tone,
          company_name: inputs[:company_name]
        )
      end

      def call_ai(prompt)
        ai_client.generate_text(prompt)
      end

      def add_landing_page_link(cover_letter_content, inputs)
        link = "**Specifically for #{inputs[:company_name]}**: #{config.base_url}/resume/#{inputs[:company_slug]}"
        "#{link}\n\n#{cover_letter_content}"
      end

      def save_cover_letter(content)
        File.write(employer.cover_letter_path, content)
      end

      def log(message)
        puts "  [CoverLetterGenerator] #{message}" if verbose
      end
    end
  end
end
```

**Step 2: Run tests to verify they pass**

Run: `./bin/jojo test --unit`

Expected output: All tests pass (6 tests for cover_letter_generator_test.rb)

**Step 3: Commit generator implementation**

```bash
git add lib/jojo/generators/cover_letter_generator.rb
git commit -m "feat: add cover letter generator class"
```

---

## Task 4: Integrate Cover Letter Command into CLI

**Files:**
- Modify: `lib/jojo/cli.rb:193-197` (replace placeholder)

**Step 1: Add require statement for cover letter generator**

Add at top of `lib/jojo/cli.rb` after other generator requires (around line 5):

```ruby
require_relative 'generators/cover_letter_generator'
```

**Step 2: Replace cover_letter command placeholder**

Replace lines 193-197 in `lib/jojo/cli.rb` with:

```ruby
desc "cover_letter", "Generate cover letter only"
def cover_letter
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
  status_logger = Jojo::StatusLogger.new(employer)

  say "Generating cover letter for #{employer.name}...", :green

  # Ensure employer directory exists
  employer.create_directory! unless Dir.exist?(employer.base_path)

  # Check job description exists
  unless File.exist?(employer.job_description_path)
    say "✗ Job description not found. Run 'generate' first.", :red
    exit 1
  end

  # Check tailored resume exists (REQUIRED)
  unless File.exist?(employer.resume_path)
    say "✗ Tailored resume not found. Run 'jojo resume' or 'jojo generate' first.", :red
    exit 1
  end

  # Check generic resume exists (REQUIRED)
  unless File.exist?('inputs/generic_resume.md')
    say "✗ Generic resume not found at inputs/generic_resume.md", :red
    say "  Copy templates/generic_resume.md to inputs/ and customize it.", :yellow
    exit 1
  end

  # Warn if research missing (optional)
  unless File.exist?(employer.research_path)
    say "⚠ Warning: Research not found. Cover letter will be less targeted.", :yellow
  end

  begin
    generator = Jojo::Generators::CoverLetterGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
    cover_letter = generator.generate

    say "✓ Cover letter generated and saved to #{employer.cover_letter_path}", :green

    status_logger.log_step("Cover Letter Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )

    say "\n✓ Cover letter complete!", :green
  rescue => e
    say "✗ Error generating cover letter: #{e.message}", :red
    status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
    exit 1
  end
end
```

**Step 3: Test cover_letter command help**

Run: `./bin/jojo help cover_letter`

Expected output: Shows description "Generate cover letter only"

**Step 4: Commit CLI cover_letter command**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: implement cover_letter CLI command"
```

---

## Task 5: Integrate Cover Letter into Generate Workflow

**Files:**
- Modify: `lib/jojo/cli.rb:99-101` (add cover letter step, update completion message)

**Step 1: Add cover letter generation step**

Replace line 100 in `lib/jojo/cli.rb` (the yellow message) with the cover letter generation block:

```ruby
      # Generate cover letter
      begin
        unless File.exist?(employer.resume_path)
          say "⚠ Warning: Resume not found, skipping cover letter generation", :yellow
        else
          generator = Jojo::Generators::CoverLetterGenerator.new(employer, ai_client, config: config, verbose: options[:verbose])
          generator.generate

          say "✓ Cover letter generated and saved", :green
          status_logger.log_step("Cover Letter Generation",
            tokens: ai_client.total_tokens_used,
            status: "complete"
          )
        end
      rescue => e
        say "✗ Error generating cover letter: #{e.message}", :red
        status_logger.log_step("Cover Letter Generation", status: "failed", error: e.message)
        exit 1
      end

      say "\n✓ Generation complete!", :green
```

**Step 2: Verify workflow order**

Check that `lib/jojo/cli.rb` generate command now has this order:
1. Job description processing
2. Research generation
3. Resume generation
4. Cover letter generation (new!)
5. Final completion message

**Step 3: Test help shows updated description**

Run: `./bin/jojo help`

Expected output: Shows all commands including fully implemented cover_letter

**Step 4: Commit generate workflow integration**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: integrate cover letter into generate workflow"
```

---

## Task 6: Run Full Test Suite

**Files:**
- Test: All unit tests

**Step 1: Run all unit tests**

Run: `./bin/jojo test --unit`

Expected output: All tests pass, including 6 new cover_letter_generator tests

**Step 2: Verify test count**

Expected test count should include:
- Config tests
- Employer tests
- StatusLogger tests
- JobDescriptionProcessor tests
- ResearchGenerator tests (if any)
- ResumeGenerator tests (5 tests)
- CoverLetterGenerator tests (6 tests)

**Step 3: If any failures, fix and re-run**

Debug any test failures and fix issues before proceeding.

---

## Task 7: Update Implementation Plan Documentation

**Files:**
- Modify: `docs/plans/implementation_plan.md:311-333` (mark Phase 5 complete)

**Step 1: Mark all Phase 5 tasks as complete**

In `docs/plans/implementation_plan.md`, update Phase 5 section:

Change line 272 from:
```markdown
## Phase 5: Cover Letter Generation
```

To:
```markdown
## Phase 5: Cover Letter Generation ✅
```

Add status line after "**Goal:**":
```markdown
**Status**: COMPLETED
```

**Step 2: Mark all individual tasks complete**

Change all `- [ ]` to `- [x]` in Phase 5 tasks (lines 311-332):

```markdown
- [x] Create `lib/jojo/generators/cover_letter_generator.rb`
- [x] Create `lib/jojo/prompts/cover_letter_prompt.rb`
- [x] Implement `cover_letter` command in CLI
- [x] Add to `generate` command workflow (after resume)
- [x] Create tests for CoverLetterGenerator
```

**Step 3: Update validation section**

Update line 334 validation to:
```markdown
**Validation**: ✅ `./bin/jojo cover_letter -e "Acme Corp" -j test_job.txt` generates cover_letter.md with landing page link. Tests passing.
```

**Step 4: Commit documentation updates**

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 5 as complete in implementation plan"
```

---

## Task 8: Manual Integration Test (Optional but Recommended)

**Files:**
- Test: End-to-end workflow

**Step 1: Create test fixtures if not already present**

Ensure these files exist:
- `test/fixtures/test_job.txt` - sample job description
- `inputs/generic_resume.md` - sample resume
- `config.yml` - with valid base_url
- `.env` - with ANTHROPIC_API_KEY (for real test)

**Step 2: Test standalone cover_letter command**

Run: `./bin/jojo cover_letter -e "Test Company" -j test/fixtures/test_job.txt -v`

Expected:
- Should fail with "Tailored resume not found" (expected - need to run resume first)

**Step 3: Test full generate workflow**

Run: `./bin/jojo generate -e "Test Company" -j test/fixtures/test_job.txt -v`

Expected:
1. ✓ Job description processed
2. ✓ Research generated
3. ✓ Resume generated
4. ✓ Cover letter generated (NEW!)
5. ✓ Generation complete!

**Step 4: Verify outputs**

Check that these files exist:
- `employers/test-company/job_description.md`
- `employers/test-company/research.md`
- `employers/test-company/resume.md`
- `employers/test-company/cover_letter.md` (NEW!)
- `employers/test-company/status_log.md`

**Step 5: Verify cover letter content**

Open `employers/test-company/cover_letter.md` and verify:
- [ ] Landing page link at top
- [ ] "Why this company" narrative (not resume duplication)
- [ ] References to company culture/values from research
- [ ] Professional formatting
- [ ] 200-400 words roughly

---

## Success Criteria Checklist

After completing all tasks, verify:

- [x] `lib/jojo/prompts/cover_letter_prompt.rb` created with comprehensive AI instructions
- [x] `lib/jojo/generators/cover_letter_generator.rb` created following established pattern
- [x] `test/unit/generators/cover_letter_generator_test.rb` created with 6 tests
- [x] All unit tests pass (`./bin/jojo test --unit`)
- [x] `cover_letter` CLI command implemented (standalone)
- [x] Cover letter step added to `generate` workflow
- [x] Landing page link included at top of cover letter
- [x] Cover letter reads tailored resume (not generic)
- [x] Graceful handling of missing optional inputs (research)
- [x] Clear error messages for missing required inputs
- [x] Status logging tracks cover letter generation
- [x] Documentation updated (implementation_plan.md)
- [x] Conventional commits used throughout

---

## Common Issues & Solutions

**Issue**: Tests fail with "method not found" on config mock
**Solution**: Ensure `@config.expect(:voice_and_tone, ...)` and `@config.expect(:base_url, ...)` are called before `@generator.generate`

**Issue**: Cover letter duplicates resume content
**Solution**: Review prompt instructions - should emphasize "why this company" story, not bullet point repetition

**Issue**: Landing page link format incorrect
**Solution**: Check `add_landing_page_link` method - should match resume pattern exactly

**Issue**: Generator doesn't fail when tailored resume missing
**Solution**: Verify `gather_inputs` raises error for missing `employer.resume_path`

**Issue**: Tests pass but CLI command fails
**Solution**: Verify `require_relative 'generators/cover_letter_generator'` at top of cli.rb

---

## Next Steps After Phase 5

After completing Phase 5:
1. Review generated cover letters for quality
2. Adjust prompt if tone/content needs refinement
3. Consider adding more test fixtures for different company types
4. Proceed to Phase 6: Website Generation
5. Eventually: PDF generation in Phase 7

---

## Estimated Completion Time

- Task 1: 5 minutes (prompt module)
- Task 2: 10 minutes (tests)
- Task 3: 10 minutes (generator implementation)
- Task 4: 5 minutes (CLI command)
- Task 5: 5 minutes (workflow integration)
- Task 6: 3 minutes (test suite)
- Task 7: 3 minutes (documentation)
- Task 8: 5-10 minutes (optional manual test)

**Total: ~45-50 minutes**
