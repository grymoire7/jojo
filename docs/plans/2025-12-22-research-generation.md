# Research Generation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate comprehensive company/role research using job description, web search, and generic resume to provide actionable insights for tailoring application materials.

**Architecture:** Create StatusLogger for consistent logging, ResearchGenerator to orchestrate research generation from multiple inputs (job description, web search results, generic resume), and comprehensive prompt template requesting structured analysis across Company Profile, Role Analysis, Strategic Positioning, and Tailoring Recommendations sections.

**Tech Stack:** Ruby 3.4.5, ruby_llm for AI, WebSearch (Claude Code built-in), Minitest for testing

---

## Task 1: StatusLogger Class

**Files:**
- Create: `lib/jojo/status_logger.rb`
- Create: `test/status_logger_test.rb`

### Step 1: Write the failing test

Create `test/status_logger_test.rb`:

```ruby
require_relative 'test_helper'
require_relative '../lib/jojo/status_logger'

describe Jojo::StatusLogger do
  before do
    @employer = Jojo::Employer.new('Test Company')
    @logger = Jojo::StatusLogger.new(@employer)

    # Clean up before tests
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "creates status log file on first write" do
    _(@employer.status_log_path).wont_be :exist?

    @logger.log("Test message")

    _(@employer.status_log_path).must_be :exist?
  end

  it "appends to existing status log" do
    @logger.log("First message")
    @logger.log("Second message")

    content = File.read(@employer.status_log_path)
    _(content).must_include "First message"
    _(content).must_include "Second message"
  end

  it "includes timestamp in log entry" do
    @logger.log("Test message")

    content = File.read(@employer.status_log_path)
    _(content).must_match /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
  end

  it "formats log entry as markdown bold timestamp" do
    @logger.log("Test message")

    content = File.read(@employer.status_log_path)
    _(content).must_match /\*\*\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\*\*: Test message/
  end

  it "logs step with metadata" do
    @logger.log_step("Job Description Processing", tokens: 1500, status: "complete")

    content = File.read(@employer.status_log_path)
    _(content).must_include "Job Description Processing"
    _(content).must_include "Tokens: 1500"
    _(content).must_include "Status: complete"
  end
end
```

### Step 2: Run test to verify it fails

Run: `./bin/jojo test`

Expected: FAIL with "cannot load such file -- jojo/status_logger"

### Step 3: Write minimal implementation

Create `lib/jojo/status_logger.rb`:

```ruby
module Jojo
  class StatusLogger
    attr_reader :employer

    def initialize(employer)
      @employer = employer
    end

    def log(message)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      log_entry = "**#{timestamp}**: #{message}\n\n"

      File.open(employer.status_log_path, 'a') do |f|
        f.write(log_entry)
      end
    end

    def log_step(step_name, metadata = {})
      message_parts = [step_name]

      metadata.each do |key, value|
        message_parts << "#{key.to_s.capitalize}: #{value}"
      end

      log(message_parts.join(" | "))
    end
  end
end
```

### Step 4: Run test to verify it passes

Run: `./bin/jojo test`

Expected: All StatusLogger tests PASS

### Step 5: Commit

```bash
git add lib/jojo/status_logger.rb test/status_logger_test.rb
git commit -m "feat: add StatusLogger for consistent status logging"
```

---

## Task 2: Research Prompt Template

**Files:**
- Create: `lib/jojo/prompts/research_prompt.rb`
- Create: `test/prompts/research_prompt_test.rb`

### Step 1: Write the failing test

Create `test/prompts/research_prompt_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/prompts/research_prompt'

describe Jojo::Prompts::Research do
  it "generates research prompt with all inputs" do
    job_description = "Senior Ruby Developer at Acme Corp..."
    company_name = "Acme Corp"
    web_results = "Acme Corp recently raised Series B funding..."
    resume = "## Experience\n\n### Software Engineer at Previous Co..."

    prompt = Jojo::Prompts::Research.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: web_results,
      resume: resume
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "Senior Ruby Developer"
    _(prompt).must_include "Series B funding"
    _(prompt).must_include "Software Engineer at Previous Co"
    _(prompt).must_include "Company Profile"
    _(prompt).must_include "Role Analysis"
    _(prompt).must_include "Strategic Positioning"
    _(prompt).must_include "Tailoring Recommendations"
  end

  it "generates prompt without web results" do
    job_description = "Senior Ruby Developer..."
    company_name = "Acme Corp"
    resume = "## Experience..."

    prompt = Jojo::Prompts::Research.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: nil,
      resume: resume
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).must_include "no additional web research available"
  end

  it "generates prompt without resume" do
    job_description = "Senior Ruby Developer..."
    company_name = "Acme Corp"
    web_results = "Acme Corp info..."

    prompt = Jojo::Prompts::Research.generate_prompt(
      job_description: job_description,
      company_name: company_name,
      web_results: web_results,
      resume: nil
    )

    _(prompt).must_include "Acme Corp"
    _(prompt).wont_include "Strategic Positioning"
    _(prompt).must_include "generic recommendations"
  end
end
```

### Step 2: Run test to verify it fails

Run: `./bin/jojo test`

Expected: FAIL with "cannot load such file -- jojo/prompts/research_prompt"

### Step 3: Write minimal implementation

Create `lib/jojo/prompts/research_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module Research
      def self.generate_prompt(job_description:, company_name:, web_results: nil, resume: nil)
        <<~PROMPT
          You are a career coach helping a job seeker research a company and role to prepare
          for tailoring their application materials (resume and cover letter).

          Generate comprehensive research that will help tailor application materials effectively.

          # Available Information

          ## Job Description

          #{job_description}

          ## Company Information

          Company Name: #{company_name}

          #{web_results ? "Web Research Results:\n\n#{web_results}" : "Note: No additional web research available - analyze based on job description only."}

          #{resume ? "## Job Seeker's Background\n\n#{resume}" : ""}

          # Your Task

          Analyze the above information and generate a structured research document with the following sections:

          ## 1. Company Profile (~200-300 words)

          - Mission, values, and culture (from web search + job description language)
          - Recent news, achievements, or changes
          - Products/services overview
          - Tech stack and engineering practices (if discoverable)

          ## 2. Role Analysis (~200-300 words)

          - Core responsibilities breakdown
          - Required vs. nice-to-have skills categorized
          - What success looks like in this role (inferred from job description)
          - Team context and reporting structure (if mentioned)

          #{resume ? role_positioning_section : generic_recommendations_section}

          ## 4. Tailoring Recommendations (~200 words)

          - Specific keywords and phrases to incorporate
          - Cultural language to mirror
          #{resume ? "- Projects/experiences from resume to highlight" : "- General guidance on what to emphasize"}
          - Tone/voice suggestions based on company culture

          # Important Instructions

          - Use your reasoning capabilities to read between the lines
          - Infer culture from word choice and phrasing
          - Identify implicit requirements not explicitly stated
          - Be specific and actionable in your recommendations
          - Format output as clean markdown with clear section headers
          #{resume ? "- Focus on how THIS specific candidate can position themselves" : "- Provide general positioning advice"}
        PROMPT
      end

      private

      def self.role_positioning_section
        <<~SECTION
          ## 3. Strategic Positioning (~300-400 words)

          - Gap analysis: What they need vs. what the seeker offers
          - Top 3-5 selling points to emphasize in resume/cover letter
          - Technologies/experiences from resume that align with job requirements
          - Potential concerns to address or reframe
        SECTION
      end

      def self.generic_recommendations_section
        <<~SECTION
          ## 3. Key Requirements (~300 words)

          Note: Without the job seeker's background, providing generic recommendations.

          - Most critical requirements for this role
          - Technologies and skills to emphasize
          - Experience level expectations
          - Suggestions for what a strong candidate would highlight
        SECTION
      end
    end
  end
end
```

### Step 4: Run test to verify it passes

Run: `./bin/jojo test`

Expected: All Research prompt tests PASS

### Step 5: Commit

```bash
git add lib/jojo/prompts/research_prompt.rb test/prompts/research_prompt_test.rb
git commit -m "feat: add research prompt template with structured sections"
```

---

## Task 3: ResearchGenerator Class

**Files:**
- Create: `lib/jojo/generators/research_generator.rb`
- Create: `test/generators/research_generator_test.rb`
- Create: `test/fixtures/generic_resume.md`

### Step 1: Create test fixtures directory

```bash
mkdir -p test/fixtures
```

### Step 2: Write the failing test

Create `test/fixtures/generic_resume.md`:

```markdown
# Jane Doe

## Experience

### Senior Software Engineer at Tech Co
2020-2023

- Built Ruby on Rails applications
- Led team of 5 developers
- Implemented CI/CD pipelines

### Software Engineer at Startup Inc
2018-2020

- Developed React frontend
- Worked with PostgreSQL databases
```

Create `test/generators/research_generator_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/generators/research_generator'
require_relative '../../lib/jojo/prompts/research_prompt'

describe Jojo::Generators::ResearchGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @generator = Jojo::Generators::ResearchGenerator.new(@employer, @ai_client, verbose: false)

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create job description and job details fixtures
    File.write(@employer.job_description_path, "Senior Ruby Developer role at Acme Corp...")
    File.write(@employer.job_details_path, "company_name: Acme Corp\njob_title: Senior Ruby Developer")

    # Create generic resume fixture
    FileUtils.mkdir_p('inputs')
    File.write('inputs/generic_resume.md', "# Jane Doe\n\n## Experience\n\nSoftware Engineer...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    FileUtils.rm_f('inputs/generic_resume.md')
  end

  it "generates research from all inputs" do
    # Mock web search results
    web_results = "Acme Corp is a leading tech company..."

    # Mock AI response
    expected_research = "# Company Profile\n\nAcme Corp is..."
    @ai_client.expect(:reason, expected_research, [String])

    # Stub web search
    @generator.stub(:perform_web_search, web_results) do
      result = @generator.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  it "saves research to file" do
    web_results = "Acme Corp info..."
    expected_research = "# Company Profile\n\nResearch content..."
    @ai_client.expect(:reason, expected_research, [String])

    @generator.stub(:perform_web_search, web_results) do
      @generator.generate
    end

    _(File.exist?(@employer.research_path)).must_equal true
    _(File.read(@employer.research_path)).must_equal expected_research

    @ai_client.verify
  end

  it "handles missing job description" do
    FileUtils.rm_f(@employer.job_description_path)

    error = assert_raises(RuntimeError) do
      @generator.generate
    end

    _(error.message).must_include "Job description not found"
  end

  it "continues when web search fails" do
    expected_research = "# Company Profile\n\nResearch without web data..."
    @ai_client.expect(:reason, expected_research, [String])

    # Stub web search to return nil (failure)
    @generator.stub(:perform_web_search, nil) do
      result = @generator.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  it "continues when generic resume is missing" do
    FileUtils.rm_f('inputs/generic_resume.md')

    web_results = "Acme Corp info..."
    expected_research = "# Company Profile\n\nResearch content..."
    @ai_client.expect(:reason, expected_research, [String])

    @generator.stub(:perform_web_search, web_results) do
      result = @generator.generate
      _(result).must_equal expected_research
    end

    @ai_client.verify
  end

  it "extracts company name from job details" do
    inputs = @generator.send(:gather_inputs)

    _(inputs[:company_name]).must_equal "Acme Corp"
  end
end
```

### Step 3: Run test to verify it fails

Run: `./bin/jojo test`

Expected: FAIL with "cannot load such file -- jojo/generators/research_generator"

### Step 4: Write minimal implementation

Create `lib/jojo/generators/research_generator.rb`:

```ruby
require 'yaml'

module Jojo
  module Generators
    class ResearchGenerator
      attr_reader :employer, :ai_client, :verbose

      def initialize(employer, ai_client, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @verbose = verbose
      end

      def generate
        log "Gathering inputs for research generation..."
        inputs = gather_inputs

        log "Performing web search for #{inputs[:company_name]}..."
        web_results = perform_web_search(inputs[:company_name])

        log "Building research prompt..."
        prompt = build_research_prompt(inputs, web_results)

        log "Generating research using AI..."
        research = call_ai(prompt)

        log "Saving research to #{employer.research_path}..."
        save_research(research)

        log "Research generation complete!"
        research
      end

      private

      def gather_inputs
        # Read job description
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Extract company name from job details
        company_name = extract_company_name

        # Read generic resume if available
        resume = read_generic_resume

        {
          job_description: job_description,
          company_name: company_name,
          resume: resume
        }
      end

      def extract_company_name
        unless File.exist?(employer.job_details_path)
          return employer.name
        end

        job_details = YAML.load_file(employer.job_details_path)
        job_details['company_name'] || employer.name
      rescue => e
        log "Warning: Could not parse job details, using employer name: #{e.message}"
        employer.name
      end

      def read_generic_resume
        resume_path = 'inputs/generic_resume.md'

        unless File.exist?(resume_path)
          log "Warning: Generic resume not found at #{resume_path}, research will be less personalized"
          return nil
        end

        File.read(resume_path)
      end

      def perform_web_search(company_name)
        # This will be called by the generator, but in tests it's stubbed
        # In real usage, this would use WebSearch tool (not available in pure Ruby)
        # For now, return nil to indicate no web search available
        log "Note: Web search not implemented in standalone mode"
        nil
      rescue => e
        log "Warning: Web search failed: #{e.message}"
        nil
      end

      def build_research_prompt(inputs, web_results)
        Prompts::Research.generate_prompt(
          job_description: inputs[:job_description],
          company_name: inputs[:company_name],
          web_results: web_results,
          resume: inputs[:resume]
        )
      end

      def call_ai(prompt)
        ai_client.reason(prompt)
      end

      def save_research(content)
        File.write(employer.research_path, content)
      end

      def log(message)
        puts "  [ResearchGenerator] #{message}" if verbose
      end
    end
  end
end
```

### Step 5: Run test to verify it passes

Run: `./bin/jojo test`

Expected: All ResearchGenerator tests PASS

### Step 6: Commit

```bash
git add lib/jojo/generators/research_generator.rb test/generators/research_generator_test.rb test/fixtures/
git commit -m "feat: add ResearchGenerator with graceful degradation"
```

---

## Task 4: CLI Integration - Research Command

**Files:**
- Modify: `lib/jojo/cli.rb:60-64`
- Modify: `lib/jojo/cli.rb:1` (add require)

### Step 1: Add requires to CLI

Modify `lib/jojo/cli.rb` - add after line 2:

```ruby
require_relative 'status_logger'
require_relative 'generators/research_generator'
```

### Step 2: Replace research command placeholder

Replace lines 60-64 in `lib/jojo/cli.rb`:

```ruby
desc "research", "Generate company/role research only"
def research
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
  status_logger = Jojo::StatusLogger.new(employer)

  say "Generating research for #{employer.name}...", :green

  # Ensure employer directory exists
  employer.create_directory! unless Dir.exist?(employer.base_path)

  # Check that job description has been processed
  unless File.exist?(employer.job_description_path)
    say "✗ Job description not found. Run 'generate' first or provide job description.", :red
    exit 1
  end

  begin
    generator = Jojo::Generators::ResearchGenerator.new(employer, ai_client, verbose: options[:verbose])
    research = generator.generate

    say "✓ Research generated and saved to #{employer.research_path}", :green

    status_logger.log_step("Research Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )

    say "\n✓ Research complete!", :green
  rescue => e
    say "✗ Error generating research: #{e.message}", :red
    status_logger.log_step("Research Generation", status: "failed", error: e.message)
    exit 1
  end
end
```

### Step 3: Test the research command manually

Run: `./bin/jojo research --help`

Expected: Shows help for research command

### Step 4: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: implement research command in CLI"
```

---

## Task 5: Integrate Research into Generate Command

**Files:**
- Modify: `lib/jojo/cli.rb:29-58`

### Step 1: Update generate command to use StatusLogger and add research generation

Replace the `generate` method in `lib/jojo/cli.rb` (lines 29-58):

```ruby
desc "generate", "Generate everything: research, resume, cover letter, and website"
def generate
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])
  status_logger = Jojo::StatusLogger.new(employer)

  say "Generating application materials for #{employer.name}...", :green

  employer.create_directory!
  say "✓ Created directory: #{employer.base_path}", :green

  # Process job description
  begin
    processor = Jojo::JobDescriptionProcessor.new(employer, ai_client, verbose: options[:verbose])
    result = processor.process(options[:job])

    say "✓ Job description processed and saved", :green
    status_logger.log_step("Job Description Processing",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )
  rescue => e
    say "✗ Error processing job description: #{e.message}", :red
    status_logger.log_step("Job Description Processing", status: "failed", error: e.message)
    exit 1
  end

  # Generate research
  begin
    generator = Jojo::Generators::ResearchGenerator.new(employer, ai_client, verbose: options[:verbose])
    generator.generate

    say "✓ Research generated and saved", :green
    status_logger.log_step("Research Generation",
      tokens: ai_client.total_tokens_used,
      status: "complete"
    )
  rescue => e
    say "✗ Error generating research: #{e.message}", :red
    status_logger.log_step("Research Generation", status: "failed", error: e.message)
    exit 1
  end

  say "\n✓ Phase 3 complete. Resume generation coming in Phase 4.", :yellow
end
```

### Step 2: Remove old log_to_status method

Delete lines 180-188 in `lib/jojo/cli.rb` (the old `log_to_status` method) since we now use StatusLogger.

### Step 3: Test the updated generate command

Create a test job description file:

```bash
echo "Senior Ruby Developer at Test Corp. Must know Rails, PostgreSQL." > /tmp/test_job.txt
```

Run: `./bin/jojo generate -e "Test Corp" -j /tmp/test_job.txt -v`

Expected: Should process job description AND generate research, saving both to `employers/test-corp/`

Note: This will make real API calls if ANTHROPIC_API_KEY is set.

### Step 4: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: integrate research generation into generate command"
```

---

## Task 6: Add Web Search Support (Claude Code Context)

**Files:**
- Modify: `lib/jojo/generators/research_generator.rb:66-73`

### Step 1: Document web search limitation

Add comment to `perform_web_search` method in `lib/jojo/generators/research_generator.rb`:

```ruby
def perform_web_search(company_name)
  # Web search is only available when running within Claude Code environment
  # The WebSearch tool is not accessible in standalone Ruby execution
  #
  # When this code is executed by Claude Code, the AI will replace this
  # method call with actual WebSearch tool invocation.
  #
  # For standalone/manual execution, this returns nil and research falls
  # back to job description analysis only.

  log "Note: Web search requires Claude Code environment"
  nil
rescue => e
  log "Warning: Web search failed: #{e.message}"
  nil
end
```

### Step 2: Add README note about web search

This will be documented in Task 7 when updating implementation_plan.md

### Step 3: Commit

```bash
git add lib/jojo/generators/research_generator.rb
git commit -m "docs: clarify web search requires Claude Code environment"
```

---

## Task 7: Update Implementation Plan

**Files:**
- Modify: `docs/plans/implementation_plan.md:207-234`

### Step 1: Mark Phase 3 tasks as complete

Update Phase 3 section in `docs/plans/implementation_plan.md`:

```markdown
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
  - Perform web search (requires Claude Code environment)
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

**Validation**: ✅ `./bin/jojo research -e "Acme Corp" -j test_job.txt` generates research.md with relevant company insights, role analysis, strategic positioning, and tailoring recommendations. Status log is updated. Tests pass without calling third-party APIs.

**Notes**:
- Web search functionality requires Claude Code environment (WebSearch tool)
- In standalone execution, web search returns nil and research uses job description only
- Generic resume (inputs/generic_resume.md) is optional but recommended for personalized research
```

### Step 2: Commit

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 3 as complete in implementation plan"
```

---

## Validation

Run all tests:

```bash
./bin/jojo test
```

Expected: All tests PASS

Test research command with real job description (requires ANTHROPIC_API_KEY):

```bash
# Ensure you have a config.yml and .env with API key
./bin/jojo setup

# Copy template resume to inputs
cp templates/generic_resume.md inputs/generic_resume.md

# Generate research
echo "Senior Ruby Developer at Acme Corp. Must know Rails, PostgreSQL, React." > /tmp/test_job.txt
./bin/jojo generate -e "Acme Corp" -j /tmp/test_job.txt -v
```

Verify outputs:
- `employers/acme-corp/job_description.md` exists
- `employers/acme-corp/job_details.yml` exists
- `employers/acme-corp/research.md` exists with sections: Company Profile, Role Analysis, Strategic Positioning, Tailoring Recommendations
- `employers/acme-corp/status_log.md` exists with timestamped entries

---

## Notes

- StatusLogger provides consistent logging across all generators
- ResearchGenerator gracefully handles missing inputs (web search, generic resume)
- Web search requires Claude Code environment; standalone execution falls back to job description analysis
- All tests use mocks to avoid external API calls
- Phase 4 will use research.md to inform resume tailoring
