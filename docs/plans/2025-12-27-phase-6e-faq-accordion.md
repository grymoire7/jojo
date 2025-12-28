# Phase 6e: FAQ Accordion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add AI-generated FAQ accordion to landing page with 5-8 role-specific questions and smooth interactive behavior.

**Architecture:** FaqGenerator calls AI with reasoning model to generate JSON array of Q&A pairs, saved to faq.json. WebsiteGenerator loads and passes FAQs to template which renders accordion with single-expand JavaScript behavior.

**Tech Stack:** Ruby, ERB templates, vanilla JavaScript, CSS animations, ARIA accessibility

---

## Task 1: Add faq_path Method to Employer

**Files:**
- Modify: `lib/jojo/employer.rb`
- Test: `test/unit/employer_test.rb`

**Step 1: Write the failing test**

```ruby
# Add to test/unit/employer_test.rb after existing tests

it "provides faq_path" do
  employer = Jojo::Employer.new('Test Corp')
  _(employer.faq_path).must_equal 'employers/test-corp/faq.json'
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/employer_test.rb`
Expected: FAIL with "undefined method `faq_path'"

**Step 3: Add faq_path method**

Add after `index_html_path` method in `lib/jojo/employer.rb`:

```ruby
def faq_path
  File.join(base_path, 'faq.json')
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/employer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/employer.rb test/unit/employer_test.rb
git commit -m "feat: add faq_path method to Employer class"
```

---

## Task 2: Create FaqPrompt Module (Part 1 - Basic Structure)

**Files:**
- Create: `lib/jojo/prompts/faq_prompt.rb`
- Create: `test/unit/prompts/faq_prompt_test.rb`

**Step 1: Create test file with first test**

Create `test/unit/prompts/faq_prompt_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/prompts/faq_prompt'

describe Jojo::Prompts::Faq do
  it "includes job description in prompt" do
    prompt = Jojo::Prompts::Faq.generate_faq_prompt(
      job_description: "We need a Python developer with 5+ years experience.",
      resume: "# John Doe\nPython developer...",
      research: nil,
      job_details: { 'job_title' => 'Senior Python Developer', 'company_name' => 'Acme Corp' },
      base_url: "https://example.com",
      seeker_name: "John Doe",
      voice_and_tone: "professional and friendly"
    )

    _(prompt).must_include "We need a Python developer with 5+ years experience."
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/prompts/faq_prompt_test.rb`
Expected: FAIL with "uninitialized constant Jojo::Prompts::Faq"

**Step 3: Create minimal FaqPrompt module**

Create `lib/jojo/prompts/faq_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module Faq
      def self.generate_faq_prompt(job_description:, resume:, research:, job_details:, base_url:, seeker_name:, voice_and_tone:)
        <<~PROMPT
          #{job_description}
        PROMPT
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/prompts/faq_prompt_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/prompts/faq_prompt.rb test/unit/prompts/faq_prompt_test.rb
git commit -m "feat: create FaqPrompt module with basic structure"
```

---

## Task 3: Create FaqPrompt Module (Part 2 - Complete Prompt)

**Files:**
- Modify: `lib/jojo/prompts/faq_prompt.rb`
- Modify: `test/unit/prompts/faq_prompt_test.rb`

**Step 1: Add tests for prompt content**

Add to `test/unit/prompts/faq_prompt_test.rb`:

```ruby
it "includes resume in prompt" do
  prompt = Jojo::Prompts::Faq.generate_faq_prompt(
    job_description: "Python developer needed",
    resume: "# John Doe\nSenior developer with expertise...",
    research: nil,
    job_details: {},
    base_url: "https://example.com",
    seeker_name: "John Doe",
    voice_and_tone: "professional"
  )

  _(prompt).must_include "# John Doe"
  _(prompt).must_include "Senior developer with expertise"
end

it "includes research when available" do
  prompt = Jojo::Prompts::Faq.generate_faq_prompt(
    job_description: "Python developer",
    resume: "Resume content",
    research: "Acme Corp is a fintech startup...",
    job_details: {},
    base_url: "https://example.com",
    seeker_name: "John Doe",
    voice_and_tone: "professional"
  )

  _(prompt).must_include "Acme Corp is a fintech startup"
end

it "includes base URL for PDF links" do
  prompt = Jojo::Prompts::Faq.generate_faq_prompt(
    job_description: "Developer needed",
    resume: "Resume",
    research: nil,
    job_details: { 'company_name' => 'Acme' },
    base_url: "https://johndoe.com",
    seeker_name: "John Doe",
    voice_and_tone: "professional"
  )

  _(prompt).must_include "https://johndoe.com"
end

it "specifies required FAQ categories" do
  prompt = Jojo::Prompts::Faq.generate_faq_prompt(
    job_description: "Developer needed",
    resume: "Resume",
    research: nil,
    job_details: {},
    base_url: "https://example.com",
    seeker_name: "John Doe",
    voice_and_tone: "professional"
  )

  _(prompt).must_include "Tech stack"
  _(prompt).must_include "Remote work"
  _(prompt).must_include "AI philosophy"
  _(prompt).must_include "why this company"
end

it "handles missing research gracefully" do
  prompt = Jojo::Prompts::Faq.generate_faq_prompt(
    job_description: "Developer needed",
    resume: "Resume",
    research: nil,
    job_details: {},
    base_url: "https://example.com",
    seeker_name: "John Doe",
    voice_and_tone: "professional"
  )

  _(prompt).wont_be_nil
  _(prompt).must_be_kind_of String
end
```

**Step 2: Run tests to verify they fail**

Run: `ruby -Ilib:test test/unit/prompts/faq_prompt_test.rb`
Expected: Multiple FAILs

**Step 3: Implement complete prompt**

Replace content in `lib/jojo/prompts/faq_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module Faq
      def self.generate_faq_prompt(job_description:, resume:, research:, job_details:, base_url:, seeker_name:, voice_and_tone:)
        company_name = job_details ? job_details['company_name'] : 'this company'
        company_slug = company_name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

        <<~PROMPT
          You are an expert at creating engaging FAQ sections for job application landing pages.

          Your task is to generate 5-8 frequently asked questions with comprehensive answers that showcase the candidate's qualifications and fit for this specific role.

          # Context

          ## Job Description

          #{job_description}

          #{research ? "## Company Research\n\n#{research}" : ""}

          ## Candidate's Resume

          #{resume}

          ## Additional Information

          - Candidate Name: #{seeker_name}
          - Company Name: #{company_name}
          - Voice and Tone: #{voice_and_tone}
          - Base URL: #{base_url}

          # Instructions

          Generate 5-8 FAQ questions covering these categories:

          1. **Tech Stack/Tools** - Specific experience with technologies mentioned in job description
          2. **Remote Work** - Setup, preferences, timezone, communication practices
          3. **AI Philosophy** - How candidate uses AI tools, philosophy on AI in development
          4. **Why This Company/Role** - Tailored motivation based on research insights (if available)
          5. **Role-Specific Questions** - 1-2 questions unique to this job
          6. **Resume & Cover Letter Downloads** - Dedicated FAQ with PDF download links

          ## Answer Guidelines

          - Length: 50-150 words per answer
          - Use specific evidence from resume (numbers, companies, projects)
          - Reference research insights when explaining "why this company"
          - Maintain #{voice_and_tone} voice and tone
          - Be honest and accurate (no fabrication)
          - For the documents FAQ, use HTML links: <a href="URL">Link Text</a>

          ## Document URLs

          - Resume: #{base_url}/resume/#{company_slug}
          - Cover Letter: #{base_url}/cover-letter/#{company_slug}

          # Output Format

          Return ONLY a valid JSON array with this structure:

          ```json
          [
            {
              "question": "Question text ending with ?",
              "answer": "Answer text with specific evidence..."
            }
          ]
          ```

          ## Example Output

          ```json
          [
            {
              "question": "What's your experience with Python and distributed systems?",
              "answer": "I have 7 years of Python experience, including building distributed systems at Acme Corp that handled 50,000 requests per second. I designed a fault-tolerant message queue using RabbitMQ and implemented service discovery with Consul."
            },
            {
              "question": "How do you approach remote work?",
              "answer": "I've worked remotely for 5 years across Pacific and Eastern time zones. I maintain strong async communication through detailed PR descriptions and documentation. I use Slack for quick questions, Zoom for pair programming, and have a dedicated home office with fiber internet."
            },
            {
              "question": "Where can I find your resume and cover letter?",
              "answer": "You can download my full resume and cover letter tailored specifically for this role: <a href=\\"#{base_url}/resume/#{company_slug}\\">View Resume</a> | <a href=\\"#{base_url}/cover-letter/#{company_slug}\\">View Cover Letter</a>"
            }
          ]
          ```

          # Important

          - Output ONLY the JSON array (no commentary, no markdown, no extra text)
          - Ensure valid JSON syntax
          - All questions must end with "?"
          - Include the resume/cover letter download FAQ
          - Focus on quality over quantity (5-8 total FAQs)
        PROMPT
      end
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/prompts/faq_prompt_test.rb`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/jojo/prompts/faq_prompt.rb test/unit/prompts/faq_prompt_test.rb
git commit -m "feat: implement complete FAQ generation prompt"
```

---

## Task 4: Create FaqGenerator (Part 1 - Basic Structure)

**Files:**
- Create: `lib/jojo/generators/faq_generator.rb`
- Create: `test/unit/generators/faq_generator_test.rb`

**Step 1: Create test file with first test**

Create `test/unit/generators/faq_generator_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/faq_generator'

describe Jojo::Generators::FaqGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @config = Minitest::Mock.new
    @generator = Jojo::Generators::FaqGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "We need 5+ years of Python experience.")
    File.write(@employer.resume_path, "# John Doe\n\nSenior Python developer with 7 years experience.")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates FAQs from job description and resume" do
    @config.expect(:seeker_name, "John Doe")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:base_url, "https://example.com")

    ai_response = JSON.generate([
      { question: "What's your Python experience?", answer: "I have 7 years of Python experience..." },
      { question: "Where can I find your resume?", answer: "Download here: <a href='...'>Resume</a>" }
    ])

    @ai_client.expect(:reason, ai_response, [String])

    result = @generator.generate

    _(result).must_be_kind_of Array
    _(result.length).must_equal 2
    _(result[0][:question]).must_equal "What's your Python experience?"

    @ai_client.verify
    @config.verify
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/faq_generator_test.rb`
Expected: FAIL with "uninitialized constant Jojo::Generators::FaqGenerator"

**Step 3: Create minimal FaqGenerator**

Create `lib/jojo/generators/faq_generator.rb`:

```ruby
require 'json'
require 'fileutils'
require_relative '../prompts/faq_prompt'

module Jojo
  module Generators
    class FaqGenerator
      attr_reader :employer, :ai_client, :config, :verbose

      def initialize(employer, ai_client, config:, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
      end

      def generate
        []
      end

      private

      def log(message)
        puts "  [FaqGenerator] #{message}" if verbose
      end
    end
  end
end
```

**Step 4: Run test to verify it fails with different error**

Run: `ruby -Ilib:test test/unit/generators/faq_generator_test.rb`
Expected: FAIL with "Expected: 2, Actual: 0" (empty array)

**Step 5: Commit**

```bash
git add lib/jojo/generators/faq_generator.rb test/unit/generators/faq_generator_test.rb
git commit -m "feat: create FaqGenerator with basic structure"
```

---

## Task 5: Create FaqGenerator (Part 2 - Core Generation Logic)

**Files:**
- Modify: `lib/jojo/generators/faq_generator.rb`
- Modify: `test/unit/generators/faq_generator_test.rb`

**Step 1: Implement generate method**

Replace `generate` method in `lib/jojo/generators/faq_generator.rb`:

```ruby
def generate
  log "Gathering inputs for FAQ generation..."
  inputs = gather_inputs

  log "Building FAQ prompt..."
  prompt = build_prompt(inputs)

  log "Generating FAQs using AI (reasoning model)..."
  faqs_json = ai_client.reason(prompt)

  log "Parsing JSON response..."
  faqs = parse_faqs(faqs_json)

  log "Saving FAQs to #{employer.faq_path}..."
  save_faqs(faqs)

  log "FAQ generation complete! Generated #{faqs.length} FAQs."
  faqs
end

private

def gather_inputs
  unless File.exist?(employer.job_description_path)
    raise "Job description not found at #{employer.job_description_path}"
  end
  job_description = File.read(employer.job_description_path)

  unless File.exist?(employer.resume_path)
    raise "Resume not found at #{employer.resume_path}"
  end
  resume = File.read(employer.resume_path)

  research = read_research
  job_details = read_job_details

  {
    job_description: job_description,
    resume: resume,
    research: research,
    job_details: job_details
  }
end

def read_research
  return nil unless File.exist?(employer.research_path)
  File.read(employer.research_path)
rescue => e
  log "Warning: Could not read research: #{e.message}"
  nil
end

def read_job_details
  return nil unless File.exist?(employer.job_details_path)
  YAML.load_file(employer.job_details_path)
rescue => e
  log "Warning: Could not read job details: #{e.message}"
  nil
end

def build_prompt(inputs)
  Prompts::Faq.generate_faq_prompt(
    job_description: inputs[:job_description],
    resume: inputs[:resume],
    research: inputs[:research],
    job_details: inputs[:job_details] || {},
    base_url: config.base_url,
    seeker_name: config.seeker_name,
    voice_and_tone: config.voice_and_tone
  )
end

def parse_faqs(json_string)
  faqs = JSON.parse(json_string, symbolize_names: true)

  # Filter out invalid FAQs (missing question or answer)
  valid_faqs = faqs.select do |faq|
    faq[:question] && faq[:answer] && !faq[:question].empty? && !faq[:answer].empty?
  end

  if valid_faqs.length < faqs.length
    log "Warning: Filtered out #{faqs.length - valid_faqs.length} invalid FAQ(s)"
  end

  valid_faqs
rescue JSON::ParserError => e
  log "Error: Failed to parse AI response as JSON: #{e.message}"
  []
end

def save_faqs(faqs)
  json_output = JSON.pretty_generate(faqs)
  File.write(employer.faq_path, json_output)
end
```

Also add at top of file:

```ruby
require 'yaml'
```

**Step 2: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/faq_generator_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/jojo/generators/faq_generator.rb
git commit -m "feat: implement FAQ generation logic"
```

---

## Task 6: Add FaqGenerator Tests (Error Handling)

**Files:**
- Modify: `test/unit/generators/faq_generator_test.rb`

**Step 1: Add error handling tests**

Add to `test/unit/generators/faq_generator_test.rb`:

```ruby
it "saves FAQs to JSON file" do
  @config.expect(:seeker_name, "John Doe")
  @config.expect(:voice_and_tone, "professional")
  @config.expect(:base_url, "https://example.com")

  ai_response = JSON.generate([
    { question: "What's your experience?", answer: "I have experience..." }
  ])

  @ai_client.expect(:reason, ai_response, [String])

  @generator.generate

  _(File.exist?(@employer.faq_path)).must_equal true

  saved_data = JSON.parse(File.read(@employer.faq_path), symbolize_names: true)
  _(saved_data.length).must_equal 1
  _(saved_data[0][:question]).must_equal "What's your experience?"

  @ai_client.verify
  @config.verify
end

it "handles malformed JSON from AI" do
  @config.expect(:seeker_name, "John Doe")
  @config.expect(:voice_and_tone, "professional")
  @config.expect(:base_url, "https://example.com")

  @ai_client.expect(:reason, "This is not valid JSON", [String])

  result = @generator.generate

  _(result).must_equal []

  @ai_client.verify
  @config.verify
end

it "filters out invalid FAQ items" do
  @config.expect(:seeker_name, "John Doe")
  @config.expect(:voice_and_tone, "professional")
  @config.expect(:base_url, "https://example.com")

  ai_response = JSON.generate([
    { question: "Valid question?", answer: "Valid answer" },
    { question: "", answer: "Missing question" },
    { question: "Missing answer?", answer: "" },
    { answer: "Missing question field" }
  ])

  @ai_client.expect(:reason, ai_response, [String])

  result = @generator.generate

  _(result.length).must_equal 1
  _(result[0][:question]).must_equal "Valid question?"

  @ai_client.verify
  @config.verify
end

it "handles missing research gracefully" do
  FileUtils.rm_f(@employer.research_path)

  @config.expect(:seeker_name, "John Doe")
  @config.expect(:voice_and_tone, "professional")
  @config.expect(:base_url, "https://example.com")

  ai_response = JSON.generate([
    { question: "Question?", answer: "Answer" }
  ])

  @ai_client.expect(:reason, ai_response, [String])

  result = @generator.generate

  _(result.length).must_equal 1

  @ai_client.verify
  @config.verify
end

it "raises error when job description missing" do
  FileUtils.rm_f(@employer.job_description_path)

  _ { @generator.generate }.must_raise RuntimeError
end

it "raises error when resume missing" do
  FileUtils.rm_f(@employer.resume_path)

  _ { @generator.generate }.must_raise RuntimeError
end
```

**Step 2: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/faq_generator_test.rb`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add test/unit/generators/faq_generator_test.rb
git commit -m "test: add error handling tests for FaqGenerator"
```

---

## Task 7: Update WebsiteGenerator (Part 1 - Load FAQs)

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`
- Modify: `test/unit/generators/website_generator_test.rb`

**Step 1: Add test for FAQ loading**

Add to `test/unit/generators/website_generator_test.rb`:

```ruby
it "loads and passes FAQs to template" do
  # Create mock FAQs file
  faqs_data = [
    { question: "What's your experience?", answer: "I have 7 years..." },
    { question: "Why this company?", answer: "I'm excited about..." }
  ]
  File.write(@employer.faq_path, JSON.generate(faqs_data))

  # Mock AI for branding statement
  @ai_client.expect(:generate_text, "Branding statement", [String])

  html = @generator.generate

  _(html).must_include "What's your experience?"
  _(html).must_include "Why this company?"
  _(html).must_include "Your Questions, Answered"

  @ai_client.verify
end

it "handles missing FAQ file gracefully" do
  FileUtils.rm_f(@employer.faq_path) if File.exist?(@employer.faq_path)

  @ai_client.expect(:generate_text, "Branding statement", [String])

  html = @generator.generate

  _(html).wont_include "Your Questions, Answered"
  _(html).wont_include "faq-accordion"

  @ai_client.verify
end
```

**Step 2: Run tests to verify they fail**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`
Expected: FAIL (FAQs not loaded/rendered)

**Step 3: Add require and load_faqs method**

Add to top of `lib/jojo/generators/website_generator.rb` (with other requires):

```ruby
require 'json'
```

Add method after `load_recommendations` method:

```ruby
def load_faqs
  return nil unless File.exist?(employer.faq_path)

  faq_data = File.read(employer.faq_path)
  JSON.parse(faq_data, symbolize_names: true)
rescue JSON::ParserError => e
  log "Error: Could not parse FAQ file: #{e.message}"
  nil
rescue => e
  log "Error loading FAQs: #{e.message}"
  nil
end
```

**Step 4: Update generate method to load FAQs**

In the `generate` method, after `load_recommendations`, add:

```ruby
log "Loading FAQs..."
faqs = load_faqs
```

**Step 5: Update prepare_template_vars call**

Change the `prepare_template_vars` call to include faqs:

```ruby
template_vars = prepare_template_vars(branding_statement, inputs, projects, annotated_job_description, recommendations, faqs)
```

**Step 6: Update prepare_template_vars method signature and body**

Update method signature:

```ruby
def prepare_template_vars(branding_statement, inputs, projects = [], annotated_job_description = nil, recommendations = nil, faqs = nil)
```

Add to the hash being returned:

```ruby
faqs: faqs
```

**Step 7: Update render_template to include faqs**

In `render_template` method, add after `recommendations` variable:

```ruby
faqs = vars[:faqs]
```

**Step 8: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`
Expected: Tests should get further but still fail (template doesn't have FAQ section yet)

**Step 9: Commit**

```bash
git add lib/jojo/generators/website_generator.rb test/unit/generators/website_generator_test.rb
git commit -m "feat: add FAQ loading to WebsiteGenerator"
```

---

## Task 8: Update Template (Part 1 - HTML Structure)

**Files:**
- Modify: `templates/website/default.html.erb`

**Step 1: Add FAQ section HTML**

Insert after the projects section (before the CTA section), around line 697:

```erb
    <!-- FAQ Section -->
    <% if faqs && !faqs.empty? %>
    <section class="faq">
      <h2>Your Questions, Answered</h2>
      <div class="faq-accordion" role="region" aria-label="Frequently asked questions">
        <% faqs.each_with_index do |faq, index| %>
        <div class="faq-item">
          <button class="faq-question" aria-expanded="false" aria-controls="answer-<%= index %>">
            <%= faq[:question] %>
            <span class="faq-chevron" aria-hidden="true">›</span>
          </button>
          <div class="faq-answer" id="answer-<%= index %>">
            <p><%= faq[:answer] %></p>
          </div>
        </div>
        <% end %>
      </div>
    </section>
    <% end %>
```

**Step 2: Run tests to verify HTML structure**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`
Expected: Tests should pass (FAQ section rendered)

**Step 3: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add FAQ section HTML to template"
```

---

## Task 9: Update Template (Part 2 - CSS Styling)

**Files:**
- Modify: `templates/website/default.html.erb`

**Step 1: Add FAQ CSS**

Add before the closing `</style>` tag (after recommendations carousel styles):

```css
    /* FAQ Section */
    .faq {
      margin: 3rem 0;
      padding: 2rem;
      background-color: var(--background-alt);
      border-radius: 8px;
    }

    .faq h2 {
      text-align: center;
      margin-top: 0;
      margin-bottom: 2rem;
      color: var(--text-color);
    }

    .faq-accordion {
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
    }

    .faq-item {
      background: var(--background);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      overflow: hidden;
      transition: border-color 200ms;
    }

    .faq-question {
      width: 100%;
      text-align: left;
      font-size: 1.125rem;
      font-weight: 600;
      color: var(--text-color);
      padding: 1rem 3rem 1rem 1rem;
      background: transparent;
      border: none;
      cursor: pointer;
      position: relative;
      transition: background-color 200ms;
      display: block;
    }

    .faq-question:hover {
      background-color: rgba(0, 0, 0, 0.02);
    }

    .faq-question:focus {
      outline: 2px solid var(--primary-color);
      outline-offset: 2px;
    }

    .faq-question.active {
      border-left: 3px solid var(--primary-color);
      padding-left: calc(1rem - 3px);
    }

    .faq-chevron {
      position: absolute;
      right: 1rem;
      top: 50%;
      transform: translateY(-50%);
      font-size: 1.5rem;
      color: var(--text-light);
      transition: transform 200ms ease;
      pointer-events: none;
    }

    .faq-question.active .faq-chevron {
      transform: translateY(-50%) rotate(90deg);
    }

    .faq-answer {
      max-height: 0;
      overflow: hidden;
      transition: max-height 300ms ease-in-out;
    }

    .faq-answer p {
      padding: 0 1rem 1rem 1rem;
      margin: 0;
      font-size: 1rem;
      line-height: 1.7;
      color: var(--text-color);
    }

    .faq-answer a {
      color: var(--primary-color);
      font-weight: 500;
      text-decoration: none;
      margin: 0 0.5rem;
    }

    .faq-answer a:hover {
      text-decoration: underline;
    }

    /* Reduced motion support */
    @media (prefers-reduced-motion: reduce) {
      .faq-answer,
      .faq-chevron {
        transition: none;
      }
    }

    /* Responsive FAQ */
    @media (max-width: 640px) {
      .faq {
        padding: 1.5rem 1rem;
      }

      .faq h2 {
        font-size: 1.5rem;
      }

      .faq-question {
        font-size: 1rem;
        padding: 0.875rem 2.5rem 0.875rem 0.875rem;
      }

      .faq-question.active {
        padding-left: calc(0.875rem - 3px);
      }

      .faq-answer p {
        font-size: 0.9rem;
        padding: 0 0.875rem 0.875rem 0.875rem;
      }

      .faq-chevron {
        font-size: 1.25rem;
        right: 0.75rem;
      }
    }
```

**Step 2: Visually test the styling**

Run: `./bin/jojo generate -e "TestCo" -j inputs/test_job.txt` (if you have test data)
Or manually verify CSS is valid

**Step 3: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "style: add CSS styling for FAQ accordion"
```

---

## Task 10: Update Template (Part 3 - JavaScript Behavior)

**Files:**
- Modify: `templates/website/default.html.erb`

**Step 1: Add FAQ JavaScript**

Add before the closing `</body>` tag (after carousel JavaScript):

```erb
  <% if faqs && !faqs.empty? %>
  <!-- FAQ Accordion JavaScript -->
  <script>
  (function() {
    'use strict';

    // FAQ state
    const faq = {
      items: document.querySelectorAll('.faq .faq-item'),
      currentlyOpenIndex: null,
      isAnimating: false
    };

    if (faq.items.length === 0) return;

    // Toggle FAQ
    function toggleFaq(index) {
      if (faq.isAnimating) return;

      if (faq.currentlyOpenIndex === index) {
        // Clicking currently open FAQ - close it
        closeFaq(index);
        faq.currentlyOpenIndex = null;
      } else {
        // Opening a new FAQ
        if (faq.currentlyOpenIndex !== null) {
          closeFaq(faq.currentlyOpenIndex);
        }
        openFaq(index);
        faq.currentlyOpenIndex = index;
      }
    }

    // Open FAQ
    function openFaq(index) {
      const item = faq.items[index];
      const button = item.querySelector('.faq-question');
      const answer = item.querySelector('.faq-answer');

      faq.isAnimating = true;

      // Set max-height to scrollHeight for smooth animation
      answer.style.maxHeight = answer.scrollHeight + 'px';

      // Update visual state
      button.classList.add('active');
      button.setAttribute('aria-expanded', 'true');

      // Clear animation lock after transition
      setTimeout(() => { faq.isAnimating = false; }, 300);
    }

    // Close FAQ
    function closeFaq(index) {
      const item = faq.items[index];
      const button = item.querySelector('.faq-question');
      const answer = item.querySelector('.faq-answer');

      faq.isAnimating = true;

      // Collapse to 0 height
      answer.style.maxHeight = '0';

      // Update visual state
      button.classList.remove('active');
      button.setAttribute('aria-expanded', 'false');

      setTimeout(() => { faq.isAnimating = false; }, 300);
    }

    // Click event listeners
    faq.items.forEach((item, index) => {
      const button = item.querySelector('.faq-question');

      button.addEventListener('click', (e) => {
        e.preventDefault();
        toggleFaq(index);
      });
    });

    // Keyboard event listeners
    document.addEventListener('keydown', (e) => {
      if (e.target.classList.contains('faq-question')) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          const index = Array.from(faq.items).indexOf(e.target.closest('.faq-item'));
          toggleFaq(index);
        } else if (e.key === 'Escape' && faq.currentlyOpenIndex !== null) {
          e.preventDefault();
          closeFaq(faq.currentlyOpenIndex);
          faq.currentlyOpenIndex = null;
        }
      }
    });
  })();
  </script>
  <% end %>
```

**Step 2: Test JavaScript renders**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add JavaScript accordion behavior to FAQ section"
```

---

## Task 11: Integration Test (Part 1 - Basic Workflow)

**Files:**
- Create: `test/integration/faq_workflow_test.rb`

**Step 1: Create integration test file**

Create `test/integration/faq_workflow_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/generators/faq_generator'
require_relative '../../lib/jojo/generators/website_generator'
require_relative '../../lib/jojo/config'
require 'yaml'
require 'json'

describe "FAQ Workflow Integration" do
  before do
    @employer = Jojo::Employer.new('Integration Test Corp')
    @ai_client = Minitest::Mock.new

    # Create minimal config
    config_data = {
      'seeker_name' => 'John Doe',
      'voice_and_tone' => 'professional and friendly',
      'base_url' => 'https://johndoe.com',
      'reasoning_ai' => { 'service' => 'anthropic', 'model' => 'sonnet' },
      'text_generation_ai' => { 'service' => 'anthropic', 'model' => 'haiku' }
    }
    File.write('config.yml', YAML.dump(config_data))
    @config = Jojo::Config.new('config.yml')

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "We need a senior Ruby developer with 5+ years experience.")
    File.write(@employer.resume_path, "# John Doe\n\nSenior Ruby developer with 7 years of experience.")
    File.write(@employer.research_path, "Integration Test Corp is a fast-growing startup.")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    FileUtils.rm_f('config.yml') if File.exist?('config.yml')
  end

  it "generates FAQs and includes them in website" do
    # Generate FAQs
    faq_generator = Jojo::Generators::FaqGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    faq_response = JSON.generate([
      { question: "What's your Ruby experience?", answer: "I have 7 years of Ruby experience..." },
      { question: "Why this company?", answer: "Integration Test Corp's mission resonates..." },
      { question: "Where can I find your resume?", answer: "<a href='...'>Resume</a>" }
    ])

    @ai_client.expect(:reason, faq_response, [String])

    faqs = faq_generator.generate

    _(faqs.length).must_equal 3
    _(File.exist?(@employer.faq_path)).must_equal true

    @ai_client.verify

    # Generate website with FAQs
    website_generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      verbose: false
    )

    @ai_client.expect(:generate_text, "I am excited to apply...", [String])

    html = website_generator.generate

    _(html).must_include "Your Questions, Answered"
    _(html).must_include "What's your Ruby experience?"
    _(html).must_include "Why this company?"
    _(html).must_include "faq-accordion"
    _(html).must_include "toggleFaq" # JavaScript function

    @ai_client.verify
  end
end
```

**Step 2: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/faq_workflow_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add test/integration/faq_workflow_test.rb
git commit -m "test: add FAQ workflow integration test"
```

---

## Task 12: Integration Test (Part 2 - Graceful Degradation)

**Files:**
- Modify: `test/integration/faq_workflow_test.rb`

**Step 1: Add graceful degradation tests**

Add to `test/integration/faq_workflow_test.rb`:

```ruby
it "handles missing FAQ file gracefully in website generation" do
  website_generator = Jojo::Generators::WebsiteGenerator.new(
    @employer,
    @ai_client,
    config: @config,
    verbose: false
  )

  # Don't create FAQ file
  FileUtils.rm_f(@employer.faq_path) if File.exist?(@employer.faq_path)

  @ai_client.expect(:generate_text, "Branding statement", [String])

  html = website_generator.generate

  _(html).wont_include "Your Questions, Answered"
  _(html).wont_include "faq-accordion"

  @ai_client.verify
end

it "handles malformed FAQ JSON gracefully" do
  # Write malformed JSON
  File.write(@employer.faq_path, "This is not valid JSON")

  website_generator = Jojo::Generators::WebsiteGenerator.new(
    @employer,
    @ai_client,
    config: @config,
    verbose: false
  )

  @ai_client.expect(:generate_text, "Branding statement", [String])

  html = website_generator.generate

  _(html).wont_include "Your Questions, Answered"

  @ai_client.verify
end

it "renders FAQ section in correct position" do
  # Create FAQ file
  faqs = [{ question: "Test?", answer: "Answer" }]
  File.write(@employer.faq_path, JSON.generate(faqs))

  website_generator = Jojo::Generators::WebsiteGenerator.new(
    @employer,
    @ai_client,
    config: @config,
    verbose: false
  )

  @ai_client.expect(:generate_text, "Branding statement", [String])

  html = website_generator.generate

  # FAQ should come after projects section and before CTA
  faq_position = html.index('Your Questions, Answered')
  cta_position = html.index('cta-section')

  _(faq_position).wont_be_nil
  _(cta_position).wont_be_nil
  _(faq_position).must_be :<, cta_position

  @ai_client.verify
end
```

**Step 2: Run tests to verify they pass**

Run: `ruby -Ilib:test test/integration/faq_workflow_test.rb`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add test/integration/faq_workflow_test.rb
git commit -m "test: add graceful degradation tests for FAQ workflow"
```

---

## Task 13: Run All Tests and Verify

**Files:**
- None (verification step)

**Step 1: Run all unit tests**

Run: `./bin/jojo test --unit`
Expected: All unit tests PASS

**Step 2: Run all integration tests**

Run: `./bin/jojo test --integration`
Expected: All integration tests PASS

**Step 3: Check test count**

Run: `./bin/jojo test --unit --integration | grep "tests,"`
Expected: Should show increase of ~20 tests from before

**Step 4: Commit if any fixes needed**

If any tests failed and you made fixes:

```bash
git add <fixed-files>
git commit -m "fix: resolve test failures"
```

---

## Task 14: Update Implementation Plan Status

**Files:**
- Modify: `docs/plans/implementation_plan.md`

**Step 1: Mark Phase 6e tasks as completed**

Update Phase 6e section in `docs/plans/implementation_plan.md`:

Change task checkboxes from `[ ]` to `[x]`:

```markdown
### Phase 6e: FAQ Accordion

**Goal**: Interactive FAQ with accordion UI

**Status**: COMPLETED

#### Tasks:

- [x] AI generates role-specific FAQs
  - [x] Standard questions (tech stack, remote work, AI philosophy)
  - [x] Custom questions based on job description
  - [x] Answers based on resume, research, inputs

- [x] Create accordion JavaScript component
  - [x] Expand/collapse interactions
  - [x] Keyboard accessible

- [x] Update template with FAQ section
  - [x] "Your Questions, Answered" heading
  - [x] Accordion container
  - [x] Links to resume.pdf, cover_letter.pdf in answers

- [x] Create tests for FAQ generation

**Validation**: ✅ FAQ accordion displays with standard + custom questions. Resume/cover letter download links work.
```

**Step 2: Commit the update**

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 6e as completed in implementation plan"
```

---

## Task 15: Manual Testing and Verification

**Files:**
- None (manual testing)

**Step 1: Generate FAQs for a test employer**

If you have test data:

```bash
./bin/jojo generate -e "Test Company" -j inputs/test_job.txt
```

Or create minimal test data and run.

**Step 2: Open generated website**

```bash
open employers/test-company/website/index.html
```

**Step 3: Verify FAQ section**

Check:
- [ ] FAQ section appears between projects and CTA
- [ ] Questions display correctly
- [ ] Clicking question expands answer
- [ ] Clicking another question closes first and opens new one
- [ ] Chevron icon rotates on expand
- [ ] Smooth animations (300ms)
- [ ] Resume/cover letter links work
- [ ] Keyboard navigation (Tab, Enter, Escape)
- [ ] Mobile responsive (test browser resize)

**Step 4: Verify faq.json**

```bash
cat employers/test-company/faq.json
```

Check:
- [ ] Valid JSON
- [ ] 5-8 questions
- [ ] Questions end with "?"
- [ ] Answers are 50-150 words
- [ ] Includes resume/cover letter download FAQ

**Step 5: Document any issues**

If issues found, create GitHub issue or fix immediately.

---

## Success Criteria Checklist

Verify all criteria are met:

- [x] AI generates 5-8 relevant FAQs based on job description and resume
- [x] FAQ covers all required categories (tech, remote, AI, why company, documents)
- [x] Answers reference specific resume evidence and research insights
- [x] Single-expand accordion behavior works smoothly
- [x] Keyboard navigation fully functional (Tab, Enter, Space, Escape)
- [x] Smooth expand/collapse animations (300ms)
- [x] Resume and cover letter download links work
- [x] FAQ positioned between projects and CTA
- [x] Graceful degradation (no FAQs → section not rendered)
- [x] All tests passing (~20 new tests)
- [x] Responsive design works on mobile and desktop
- [x] Screen reader accessible (ARIA attributes correct)
- [x] Reduced motion preference respected

---

## Completion

Phase 6e implementation complete! The FAQ accordion:

1. ✅ Generates AI-powered FAQs tailored to each role
2. ✅ Covers tech stack, remote work, AI philosophy, why company, role-specific questions, and document downloads
3. ✅ Features smooth single-expand accordion with keyboard accessibility
4. ✅ Positioned strategically before CTA to address final questions
5. ✅ Fully tested with ~20 new tests
6. ✅ Responsive and accessible

Next steps:
- Test with real job applications
- Gather user feedback on FAQ quality
- Consider future enhancements (custom topics, search, analytics)
