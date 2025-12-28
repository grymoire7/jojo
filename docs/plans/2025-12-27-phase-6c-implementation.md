# Phase 6c: Annotated Job Description Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add AI-powered annotations to job descriptions on landing pages, showing hiring managers exactly how candidate experience matches specific requirements with interactive tooltips.

**Architecture:** Fine-grained phrase matching with tiered highlighting (strong/moderate/mention). AI generates JSON annotations, WebsiteGenerator injects HTML spans, browser JavaScript handles tooltips. Graceful degradation when annotations unavailable.

**Tech Stack:** Ruby, ERB templates, vanilla JavaScript, CSS

---

## Task 1: Extend Employer class with annotations path

**Files:**
- Modify: `lib/jojo/employer.rb:38-47`
- Test: `test/unit/employer_test.rb`

**Step 1: Write failing test**

Add to `test/unit/employer_test.rb`:

```ruby
it "provides job_description_annotations_path" do
  employer = Jojo::Employer.new('Acme Corp')
  expected_path = 'employers/acme-corp/job_description_annotations.json'
  _(employer.job_description_annotations_path).must_equal expected_path
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/employer_test.rb`

Expected: FAIL with "undefined method `job_description_annotations_path'"

**Step 3: Add annotations path method**

In `lib/jojo/employer.rb`, add after `job_details_path` method (around line 22):

```ruby
def job_description_annotations_path
  File.join(base_path, 'job_description_annotations.json')
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/employer_test.rb`

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/employer.rb test/unit/employer_test.rb
git commit -m "feat: add job_description_annotations_path to Employer"
```

---

## Task 2: Create AnnotationPrompt module

**Files:**
- Create: `lib/jojo/prompts/annotation_prompt.rb`
- Test: `test/unit/prompts/annotation_prompt_test.rb`

**Step 1: Write failing test**

Create `test/unit/prompts/annotation_prompt_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/prompts/annotation_prompt'

describe Jojo::Prompts::Annotation do
  it "generates prompt with all required context" do
    job_description = "We need 5+ years of Python experience and knowledge of distributed systems."
    resume = "# John Doe\n\nSenior Python developer with 7 years experience..."
    research = "Acme Corp values technical expertise..."

    prompt = Jojo::Prompts::Annotation.generate_annotations_prompt(
      job_description: job_description,
      resume: resume,
      research: research
    )

    _(prompt).must_include job_description
    _(prompt).must_include resume
    _(prompt).must_include research
    _(prompt).must_include "strong"
    _(prompt).must_include "moderate"
    _(prompt).must_include "mention"
    _(prompt).must_include "JSON"
    _(prompt).must_include "EXACTLY as it appears"
  end

  it "generates prompt without research (graceful degradation)" do
    job_description = "We need 5+ years of Python experience."
    resume = "# John Doe\n\nSenior Python developer..."

    prompt = Jojo::Prompts::Annotation.generate_annotations_prompt(
      job_description: job_description,
      resume: resume,
      research: nil
    )

    _(prompt).must_include job_description
    _(prompt).must_include resume
    _(prompt).wont_include "## Company Research"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/prompts/annotation_prompt_test.rb`

Expected: FAIL with "cannot load such file -- jojo/prompts/annotation_prompt"

**Step 3: Create prompt module**

Create `lib/jojo/prompts/annotation_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module Annotation
      def self.generate_annotations_prompt(job_description:, resume:, research: nil)
        <<~PROMPT
          You are an expert at analyzing job descriptions and matching candidate qualifications.

          Your task is to identify specific phrases in the job description that match the candidate's experience, and provide evidence from their resume/research.

          # Context

          ## Job Description

          #{job_description}

          #{research ? "## Company Research\n\n#{research}" : ""}

          ## Candidate's Resume

          #{resume}

          # Instructions

          ## YOUR TASK:
          Extract specific, matchable phrases from the job description and match them to concrete evidence from the candidate's resume.

          ## WHAT TO EXTRACT:
          - Technical skills (e.g., "Python", "distributed systems", "React")
          - Years of experience (e.g., "5+ years of Ruby")
          - Specific tools/frameworks (e.g., "PostgreSQL", "Docker")
          - Domain knowledge (e.g., "fintech experience", "healthcare domain")
          - Measurable achievements (e.g., "scaled to 1M users")
          - Soft skills with context (e.g., "team leadership", "mentoring")

          ## MATCH CLASSIFICATION:

          **strong** - Direct experience with specific numbers/outcomes
          - Example: "5+ years Python" → "Built Python applications for 7 years at Acme Corp"

          **moderate** - Related experience or transferable skills
          - Example: "team leadership" → "Led team of 3 engineers on authentication project"

          **mention** - Tangential connection or potential to learn
          - Example: "GraphQL" → "Familiar with GraphQL concepts, built REST APIs with similar patterns"

          ## CRITICAL REQUIREMENTS:

          1. Extract text EXACTLY as it appears in job description (critical for matching)
          2. Extract phrases, not full sentences (2-8 words typically)
          3. Provide concrete evidence from resume (specific numbers, companies, projects)
          4. Quality over quantity: 5-8 strong, 3-5 moderate, 0-3 mention
          5. Only annotate if you have real evidence (don't fabricate)
          6. Be truthful and accurate (based on actual resume content)

          # Output Format

          Return ONLY a valid JSON array with this structure:

          ```json
          [
            {
              "text": "exact phrase from job description",
              "match": "specific evidence from resume",
              "tier": "strong|moderate|mention"
            }
          ]
          ```

          ## Example Output:

          ```json
          [
            {
              "text": "5+ years of Python",
              "match": "Built Python applications for 7 years at Acme Corp and Beta Inc",
              "tier": "strong"
            },
            {
              "text": "distributed systems",
              "match": "Designed fault-tolerant message queue handling 10K msgs/sec",
              "tier": "strong"
            },
            {
              "text": "team leadership",
              "match": "Led team of 3 engineers on authentication project",
              "tier": "moderate"
            }
          ]
          ```

          # Important:

          - Output ONLY the JSON array (no commentary, no markdown, no extra text)
          - Ensure valid JSON syntax
          - Extract text EXACTLY as it appears in job description
          - Provide specific, truthful evidence from resume
          - Focus on quality matches, not quantity
        PROMPT
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/prompts/annotation_prompt_test.rb`

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/prompts/annotation_prompt.rb test/unit/prompts/annotation_prompt_test.rb
git commit -m "feat: add annotation prompt module"
```

---

## Task 3: Create AnnotationGenerator class (test setup)

**Files:**
- Create: `test/unit/generators/annotation_generator_test.rb`

**Step 1: Create test file structure**

Create `test/unit/generators/annotation_generator_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/annotation_generator'

describe Jojo::Generators::AnnotationGenerator do
  before do
    @employer = Jojo::Employer.new('Acme Corp')
    @ai_client = Minitest::Mock.new
    @generator = Jojo::Generators::AnnotationGenerator.new(
      @employer,
      @ai_client,
      verbose: false
    )

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create required fixtures
    File.write(@employer.job_description_path, "We need 5+ years of Python and distributed systems experience.")
    File.write(@employer.resume_path, "# John Doe\n\nSenior Python developer with 7 years experience...")
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/annotation_generator_test.rb`

Expected: FAIL with "cannot load such file -- jojo/generators/annotation_generator"

**Step 3: Create minimal generator class**

Create `lib/jojo/generators/annotation_generator.rb`:

```ruby
require 'json'
require_relative '../prompts/annotation_prompt'

module Jojo
  module Generators
    class AnnotationGenerator
      attr_reader :employer, :ai_client, :verbose

      def initialize(employer, ai_client, verbose: false)
        @employer = employer
        @ai_client = ai_client
        @verbose = verbose
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/annotation_generator_test.rb`

Expected: PASS (no tests yet, just setup)

**Step 5: Commit**

```bash
git add lib/jojo/generators/annotation_generator.rb test/unit/generators/annotation_generator_test.rb
git commit -m "feat: add annotation generator skeleton"
```

---

## Task 4: Implement AnnotationGenerator.generate method

**Files:**
- Modify: `lib/jojo/generators/annotation_generator.rb`
- Modify: `test/unit/generators/annotation_generator_test.rb`

**Step 1: Write failing test**

Add to `test/unit/generators/annotation_generator_test.rb`:

```ruby
it "generates annotations from job description and resume" do
  ai_response = JSON.generate([
    { text: "5+ years of Python", match: "Built Python apps for 7 years", tier: "strong" },
    { text: "distributed systems", match: "Designed fault-tolerant queue", tier: "strong" }
  ])

  @ai_client.expect(:reason, ai_response, [String])

  result = @generator.generate

  _(result).must_be_kind_of Array
  _(result.length).must_equal 2
  _(result[0][:text]).must_equal "5+ years of Python"
  _(result[0][:tier]).must_equal "strong"

  @ai_client.verify
end

it "saves annotations to JSON file" do
  ai_response = JSON.generate([
    { text: "5+ years of Python", match: "Built Python apps for 7 years", tier: "strong" }
  ])

  @ai_client.expect(:reason, ai_response, [String])

  @generator.generate

  _(File.exist?(@employer.job_description_annotations_path)).must_equal true

  saved_data = JSON.parse(File.read(@employer.job_description_annotations_path), symbolize_names: true)
  _(saved_data.length).must_equal 1
  _(saved_data[0][:text]).must_equal "5+ years of Python"

  @ai_client.verify
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/annotation_generator_test.rb`

Expected: FAIL with "undefined method `generate'"

**Step 3: Implement generate method**

In `lib/jojo/generators/annotation_generator.rb`, add:

```ruby
def generate
  log "Gathering inputs for annotation generation..."
  inputs = gather_inputs

  log "Building annotation prompt..."
  prompt = build_prompt(inputs)

  log "Generating annotations using AI (reasoning model)..."
  annotations_json = ai_client.reason(prompt)

  log "Parsing JSON response..."
  annotations = parse_annotations(annotations_json)

  log "Saving annotations to #{employer.job_description_annotations_path}..."
  save_annotations(annotations)

  log "Annotation generation complete! Generated #{annotations.length} annotations."
  annotations
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

  {
    job_description: job_description,
    resume: resume,
    research: research
  }
end

def read_research
  unless File.exist?(employer.research_path)
    log "Warning: Research not found, annotations will be based on job description only"
    return nil
  end

  File.read(employer.research_path)
end

def build_prompt(inputs)
  Prompts::Annotation.generate_annotations_prompt(
    job_description: inputs[:job_description],
    resume: inputs[:resume],
    research: inputs[:research]
  )
end

def parse_annotations(json_string)
  JSON.parse(json_string, symbolize_names: true)
rescue JSON::ParserError => e
  log "Error: Failed to parse AI response as JSON: #{e.message}"
  raise "AI returned invalid JSON: #{e.message}"
end

def save_annotations(annotations)
  json_output = JSON.pretty_generate(annotations)
  File.write(employer.job_description_annotations_path, json_output)
end

def log(message)
  puts "  [AnnotationGenerator] #{message}" if verbose
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/annotation_generator_test.rb`

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/generators/annotation_generator.rb test/unit/generators/annotation_generator_test.rb
git commit -m "feat: implement annotation generation"
```

---

## Task 5: Add annotation generator error handling tests

**Files:**
- Modify: `test/unit/generators/annotation_generator_test.rb`

**Step 1: Write failing tests**

Add to `test/unit/generators/annotation_generator_test.rb`:

```ruby
it "raises error when job description missing" do
  FileUtils.rm_f(@employer.job_description_path)

  _ { @generator.generate }.must_raise RuntimeError
end

it "raises error when resume missing" do
  FileUtils.rm_f(@employer.resume_path)

  _ { @generator.generate }.must_raise RuntimeError
end

it "handles missing research gracefully" do
  FileUtils.rm_f(@employer.research_path)

  ai_response = JSON.generate([
    { text: "Python", match: "7 years experience", tier: "strong" }
  ])

  @ai_client.expect(:reason, ai_response, [String])

  # Should not raise error
  result = @generator.generate
  _(result).must_be_kind_of Array

  @ai_client.verify
end

it "raises error when AI returns invalid JSON" do
  @ai_client.expect(:reason, "This is not JSON", [String])

  _ { @generator.generate }.must_raise RuntimeError
end
```

**Step 2: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/annotation_generator_test.rb`

Expected: PASS (implementation already handles these cases)

**Step 3: Commit**

```bash
git add test/unit/generators/annotation_generator_test.rb
git commit -m "test: add error handling tests for annotation generator"
```

---

## Task 6: Add WebsiteGenerator annotation support (test)

**Files:**
- Modify: `test/unit/generators/website_generator_test.rb`

**Step 1: Write failing test**

Add to `test/unit/generators/website_generator_test.rb`:

```ruby
it "loads and injects annotations into job description HTML" do
  # Create annotations JSON
  annotations = [
    { text: "Ruby", match: "7 years Ruby experience", tier: "strong" },
    { text: "distributed systems", match: "Built message queue", tier: "moderate" }
  ]
  File.write(@employer.job_description_annotations_path, JSON.generate(annotations))

  expected_branding = "Branding statement..."
  @ai_client.expect(:generate_text, expected_branding, [String])

  result = @generator.generate

  # Should include annotated job description section
  _(result).must_include "Compare Me to the Job Description"
  _(result).must_include '<span class="annotated" data-tier="strong" data-match="7 years Ruby experience">Ruby</span>'
  _(result).must_include '<span class="annotated" data-tier="moderate" data-match="Built message queue">distributed systems</span>'

  @ai_client.verify
end

it "omits annotation section when annotations.json missing" do
  # Don't create annotations file

  expected_branding = "Branding statement..."
  @ai_client.expect(:generate_text, expected_branding, [String])

  result = @generator.generate

  # Should NOT include annotation section
  _(result).wont_include "Compare Me to the Job Description"
  _(result).wont_include "annotation-tooltip"

  @ai_client.verify
end

it "annotates all occurrences of same text" do
  # Job description with duplicate text
  File.write(@employer.job_description_path, "We need Ruby skills. Ruby is our main language. Ruby developers wanted.")

  annotations = [
    { text: "Ruby", match: "7 years Ruby experience", tier: "strong" }
  ]
  File.write(@employer.job_description_annotations_path, JSON.generate(annotations))

  expected_branding = "Branding..."
  @ai_client.expect(:generate_text, expected_branding, [String])

  result = @generator.generate

  # Count occurrences of annotated "Ruby"
  annotation_count = result.scan(/<span class="annotated"[^>]*>Ruby<\/span>/).length
  _(annotation_count).must_equal 3

  @ai_client.verify
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`

Expected: FAIL (annotations not implemented yet)

**Step 3: No implementation yet - just commit tests**

```bash
git add test/unit/generators/website_generator_test.rb
git commit -m "test: add annotation tests for website generator"
```

---

## Task 7: Implement WebsiteGenerator annotation loading

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`

**Step 1: Add annotate_job_description method**

In `lib/jojo/generators/website_generator.rb`, add after `process_project_images` method:

```ruby
def annotate_job_description
  # Load annotations JSON
  unless File.exist?(employer.job_description_annotations_path)
    log "No annotations found at #{employer.job_description_annotations_path}"
    return nil
  end

  annotations = load_annotations
  return nil if annotations.nil? || annotations.empty?

  # Load job description
  unless File.exist?(employer.job_description_path)
    log "Warning: Job description not found, cannot annotate"
    return nil
  end

  job_description_md = File.read(employer.job_description_path)

  # Convert to HTML and inject annotations
  annotated_html = inject_annotations(job_description_md, annotations)
  annotated_html
rescue => e
  log "Error annotating job description: #{e.message}"
  nil
end

def load_annotations
  json_content = File.read(employer.job_description_annotations_path)
  JSON.parse(json_content, symbolize_names: true)
rescue JSON::ParserError => e
  log "Error: Malformed annotations JSON: #{e.message}"
  nil
end

def inject_annotations(markdown_text, annotations)
  require 'cgi'

  # Convert markdown to HTML paragraphs
  html = markdown_to_html(markdown_text)

  # Inject each annotation
  annotations.each do |annotation|
    text = annotation[:text]
    match = CGI.escapeHTML(annotation[:match])
    tier = annotation[:tier]

    # Replace all occurrences
    pattern = Regexp.escape(text)
    replacement = %(<span class="annotated" data-tier="#{tier}" data-match="#{match}">#{text}</span>)

    html.gsub!(pattern, replacement)
  end

  html
end

def markdown_to_html(markdown)
  # Simple markdown to HTML conversion
  paragraphs = markdown.split("\n\n").map(&:strip).reject(&:empty?)

  paragraphs.map do |para|
    # Convert bold
    para = para.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
    # Convert italic
    para = para.gsub(/\*([^*]+)\*/, '<em>\1</em>')
    # Convert links
    para = para.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')

    "<p>#{para}</p>"
  end.join("\n")
end
```

**Step 2: Update generate method to call annotate_job_description**

In `lib/jojo/generators/website_generator.rb`, modify the `generate` method to add annotation handling:

```ruby
def generate
  log "Gathering inputs for website generation..."
  inputs = gather_inputs

  log "Generating personalized branding statement using AI..."
  branding_statement = generate_branding_statement(inputs)

  log "Loading relevant projects..."
  projects = load_projects
  projects = process_project_images(projects)

  log "Loading and annotating job description..."
  annotated_job_description = annotate_job_description

  log "Preparing template variables..."
  template_vars = prepare_template_vars(branding_statement, inputs, projects, annotated_job_description)

  log "Rendering HTML template (#{template_name})..."
  html = render_template(template_vars)

  log "Copying branding image if available..."
  copy_branding_image

  log "Saving website to #{employer.index_html_path}..."
  save_website(html)

  log "Website generation complete!"
  html
end
```

**Step 3: Update prepare_template_vars to include annotation**

In `lib/jojo/generators/website_generator.rb`, update `prepare_template_vars` signature and add to vars hash:

```ruby
def prepare_template_vars(branding_statement, inputs, projects = [], annotated_job_description = nil)
  # ... existing code ...

  {
    seeker_name: config.seeker_name,
    company_name: inputs[:company_name],
    company_slug: inputs[:company_slug],
    job_title: job_title,
    branding_statement: branding_statement,
    cta_text: config.website_cta_text,
    cta_link: cta_link,
    has_branding_image: branding_image_info[:exists],
    branding_image_path: branding_image_info[:relative_path],
    base_url: config.base_url,
    projects: projects,
    annotated_job_description: annotated_job_description
  }
end
```

**Step 4: Update render_template to include new var**

In `lib/jojo/generators/website_generator.rb`, add to the `render_template` method:

```ruby
def render_template(vars)
  template_path = File.join('templates', 'website', "#{template_name}.html.erb")

  unless File.exist?(template_path)
    raise "Template not found: #{template_path}. Available templates: #{available_templates.join(', ')}"
  end

  template_content = File.read(template_path)

  # Create binding with template variables
  seeker_name = vars[:seeker_name]
  company_name = vars[:company_name]
  company_slug = vars[:company_slug]
  job_title = vars[:job_title]
  branding_statement = vars[:branding_statement]
  cta_text = vars[:cta_text]
  cta_link = vars[:cta_link]
  has_branding_image = vars[:has_branding_image]
  branding_image_path = vars[:branding_image_path]
  base_url = vars[:base_url]
  projects = vars[:projects]
  annotated_job_description = vars[:annotated_job_description]

  ERB.new(template_content).result(binding)
end
```

**Step 5: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`

Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/website_generator.rb
git commit -m "feat: add annotation loading and HTML injection to website generator"
```

---

## Task 8: Update template with annotation section, CSS, and JavaScript

**Files:**
- Modify: `templates/website/default.html.erb`

**Step 1: Add annotation CSS**

In `templates/website/default.html.erb`, add CSS after the existing projects section styles (around line 235):

```css
/* Annotated Job Description Section */
.job-description-comparison {
  margin: 3rem 0;
  padding: 2rem;
  background-color: var(--background-alt);
  border-radius: 8px;
}

.job-description-comparison h2 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  color: var(--text-color);
}

.job-description-content {
  background-color: var(--background);
  padding: 1.5rem;
  border-radius: 6px;
  line-height: 1.8;
}

.job-description-content p {
  margin-bottom: 1rem;
}

.job-description-content p:last-child {
  margin-bottom: 0;
}

.annotated {
  background-color: rgba(37, 99, 235, 0.15);
  cursor: pointer;
  border-radius: 2px;
  padding: 1px 2px;
  transition: background-color 0.2s;
  position: relative;
}

.annotated[data-tier="strong"] {
  background-color: rgba(37, 99, 235, 0.25);
}

.annotated[data-tier="moderate"] {
  background-color: rgba(37, 99, 235, 0.15);
}

.annotated[data-tier="mention"] {
  background-color: rgba(37, 99, 235, 0.08);
}

.annotated:hover,
.annotated:focus {
  background-color: rgba(37, 99, 235, 0.3);
  outline: none;
}

.annotation-legend {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid var(--border-color);
  font-size: 0.875rem;
  color: var(--text-light);
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: center;
}

.legend-item {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.legend-item .sample {
  display: inline-block;
  width: 40px;
  height: 16px;
  border-radius: 2px;
}

.legend-item .sample.strong {
  background-color: rgba(37, 99, 235, 0.25);
}

.legend-item .sample.moderate {
  background-color: rgba(37, 99, 235, 0.15);
}

.legend-item .sample.mention {
  background-color: rgba(37, 99, 235, 0.08);
}

.legend-hint {
  font-style: italic;
  margin-left: auto;
}

.annotation-tooltip {
  position: absolute;
  background: white;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  padding: 0.75rem 1rem;
  max-width: 300px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  opacity: 0;
  pointer-events: none;
  transition: opacity 150ms ease;
}

.annotation-tooltip.visible {
  opacity: 1;
  pointer-events: auto;
}

.tooltip-content {
  font-size: 0.875rem;
  line-height: 1.5;
  color: var(--text-color);
}

.tooltip-arrow {
  position: absolute;
  width: 10px;
  height: 10px;
  background: white;
  border: 1px solid var(--border-color);
  transform: rotate(45deg);
  z-index: -1;
}

.annotation-tooltip.above .tooltip-arrow {
  bottom: -6px;
  left: 50%;
  margin-left: -5px;
  border-top: none;
  border-left: none;
}

.annotation-tooltip.below .tooltip-arrow {
  top: -6px;
  left: 50%;
  margin-left: -5px;
  border-bottom: none;
  border-right: none;
}

@media (max-width: 640px) {
  .annotation-legend {
    flex-direction: column;
    align-items: flex-start;
  }

  .legend-hint {
    margin-left: 0;
  }

  .annotation-tooltip {
    max-width: calc(100vw - 2rem);
  }
}
```

**Step 2: Add annotation HTML section**

In `templates/website/default.html.erb`, add after the branding section and before the CTA section (around line 262):

```erb
<!-- Annotated Job Description -->
<% if annotated_job_description %>
<section class="job-description-comparison">
  <h2>Compare Me to the Job Description</h2>
  <div class="job-description-content">
    <%= annotated_job_description %>
  </div>
  <p class="annotation-legend">
    <span class="legend-item"><span class="sample strong"></span> Strong match</span>
    <span class="legend-item"><span class="sample moderate"></span> Moderate match</span>
    <span class="legend-item"><span class="sample mention"></span> Worth a mention</span>
    <span class="legend-hint">Hover or tap highlighted text to see details</span>
  </p>
</section>
<% end %>
```

**Step 3: Add tooltip container before closing body tag**

In `templates/website/default.html.erb`, add before `</body>` tag (around line 303):

```erb
<!-- Annotation tooltip container -->
<% if annotated_job_description %>
<div id="annotation-tooltip" class="annotation-tooltip">
  <div class="tooltip-content"></div>
  <div class="tooltip-arrow"></div>
</div>
<% end %>
```

**Step 4: Add JavaScript for tooltip interactions**

In `templates/website/default.html.erb`, add before `</body>` tag (after tooltip container):

```erb
<% if annotated_job_description %>
<script>
(function() {
  'use strict';

  const tooltip = document.getElementById('annotation-tooltip');
  const tooltipContent = tooltip.querySelector('.tooltip-content');
  const annotations = document.querySelectorAll('.annotated');
  const isTouchDevice = window.matchMedia('(hover: none)').matches;
  let currentAnnotation = null;

  // Show tooltip
  function showTooltip(annotation) {
    const match = annotation.dataset.match;
    if (!match) return;

    currentAnnotation = annotation;
    tooltipContent.textContent = match;

    // Position tooltip
    positionTooltip(annotation);

    // Show with animation
    tooltip.classList.add('visible');
  }

  // Hide tooltip
  function hideTooltip() {
    tooltip.classList.remove('visible');
    currentAnnotation = null;
  }

  // Position tooltip above or below annotation
  function positionTooltip(annotation) {
    const rect = annotation.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const spaceAbove = rect.top;
    const spaceBelow = viewportHeight - rect.bottom;

    // Decide position: above or below
    const showAbove = spaceAbove > tooltipRect.height + 10 && spaceBelow < tooltipRect.height + 10;

    if (showAbove) {
      tooltip.classList.add('above');
      tooltip.classList.remove('below');
      tooltip.style.top = (window.scrollY + rect.top - tooltipRect.height - 10) + 'px';
    } else {
      tooltip.classList.add('below');
      tooltip.classList.remove('above');
      tooltip.style.top = (window.scrollY + rect.bottom + 10) + 'px';
    }

    // Center horizontally
    const left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);
    const maxLeft = window.innerWidth - tooltipRect.width - 10;
    tooltip.style.left = Math.max(10, Math.min(left, maxLeft)) + 'px';
  }

  // Add event listeners to each annotation
  annotations.forEach(function(annotation) {
    // Make focusable for keyboard navigation
    annotation.setAttribute('tabindex', '0');

    if (isTouchDevice) {
      // Touch: tap to show, tap outside to hide
      annotation.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        if (currentAnnotation === annotation) {
          hideTooltip();
        } else {
          showTooltip(annotation);
        }
      });
    } else {
      // Desktop: hover to show
      annotation.addEventListener('mouseenter', function() {
        showTooltip(annotation);
      });

      annotation.addEventListener('mouseleave', function() {
        hideTooltip();
      });
    }

    // Keyboard: Enter to show, Escape to hide
    annotation.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        showTooltip(annotation);
      } else if (e.key === 'Escape') {
        e.preventDefault();
        hideTooltip();
      }
    });
  });

  // Click outside to close (for touch devices)
  if (isTouchDevice) {
    document.addEventListener('click', function(e) {
      if (!tooltip.contains(e.target) && !e.target.classList.contains('annotated')) {
        hideTooltip();
      }
    });
  }
})();
</script>
<% end %>
```

**Step 5: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/website_generator_test.rb`

Expected: PASS

**Step 6: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add annotation section, CSS, and JavaScript to template"
```

---

## Task 9: Create integration test

**Files:**
- Create: `test/integration/annotated_job_description_test.rb`

**Step 1: Create integration test**

Create `test/integration/annotated_job_description_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/generators/annotation_generator'
require_relative '../../lib/jojo/generators/website_generator'

describe "Annotated Job Description Integration" do
  before do
    @employer = Jojo::Employer.new('TechCorp')
    @ai_client = Minitest::Mock.new

    # Clean up and create directories
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
    @employer.create_directory!

    # Create fixtures
    @job_description = "We need 5+ years of Ruby experience and knowledge of distributed systems. PostgreSQL expertise required."
    @resume = "# John Doe\n\nSenior Ruby developer with 7 years building web applications.\nExperience with PostgreSQL and Redis.\nBuilt distributed message queue system."

    File.write(@employer.job_description_path, @job_description)
    File.write(@employer.resume_path, @resume)
  end

  after do
    FileUtils.rm_rf(@employer.base_path) if Dir.exist?(@employer.base_path)
  end

  it "generates annotated website from job description and resume" do
    # Generate annotations
    annotation_generator = Jojo::Generators::AnnotationGenerator.new(@employer, @ai_client, verbose: false)

    annotations_json = JSON.generate([
      { text: "5+ years of Ruby", match: "Built Ruby apps for 7 years", tier: "strong" },
      { text: "distributed systems", match: "Built distributed message queue system", tier: "strong" },
      { text: "PostgreSQL", match: "Experience with PostgreSQL and Redis", tier: "moderate" }
    ])

    @ai_client.expect(:reason, annotations_json, [String])
    annotation_generator.generate
    @ai_client.verify

    # Generate website with annotations
    config = Minitest::Mock.new
    config.expect(:seeker_name, "John Doe")
    config.expect(:voice_and_tone, "professional")
    config.expect(:website_cta_text, "Contact Me")
    config.expect(:website_cta_link, "mailto:john@example.com")
    config.expect(:base_url, "https://john.example.com")

    website_generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: config,
      verbose: false,
      inputs_path: 'test/fixtures'
    )

    @ai_client.expect(:generate_text, "I'm a great fit for TechCorp...", [String])

    html = website_generator.generate

    # Verify annotation section exists
    _(html).must_include "Compare Me to the Job Description"
    _(html).must_include "annotation-tooltip"

    # Verify annotations are injected
    _(html).must_include '<span class="annotated" data-tier="strong" data-match="Built Ruby apps for 7 years">5+ years of Ruby</span>'
    _(html).must_include '<span class="annotated" data-tier="strong" data-match="Built distributed message queue system">distributed systems</span>'
    _(html).must_include '<span class="annotated" data-tier="moderate" data-match="Experience with PostgreSQL and Redis">PostgreSQL</span>'

    # Verify legend
    _(html).must_include "Strong match"
    _(html).must_include "Moderate match"
    _(html).must_include "Worth a mention"

    # Verify JavaScript present
    _(html).must_include "function showTooltip"
    _(html).must_include "annotation.dataset.match"

    @ai_client.verify
    config.verify
  end

  it "website works without annotations (graceful degradation)" do
    # Don't generate annotations

    config = Minitest::Mock.new
    config.expect(:seeker_name, "John Doe")
    config.expect(:voice_and_tone, "professional")
    config.expect(:website_cta_text, "Contact Me")
    config.expect(:website_cta_link, "mailto:john@example.com")
    config.expect(:base_url, "https://john.example.com")

    website_generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: config,
      verbose: false,
      inputs_path: 'test/fixtures'
    )

    @ai_client.expect(:generate_text, "I'm a great fit for TechCorp...", [String])

    html = website_generator.generate

    # Verify annotation section NOT present
    _(html).wont_include "Compare Me to the Job Description"
    _(html).wont_include "annotation-tooltip"

    # But website still works
    _(html).must_include "Am I a good match for TechCorp?"
    _(html).must_include "I'm a great fit for TechCorp..."

    @ai_client.verify
    config.verify
  end
end
```

**Step 2: Run test to verify it passes**

Run: `ruby -Ilib:test test/integration/annotated_job_description_test.rb`

Expected: PASS

**Step 3: Commit**

```bash
git add test/integration/annotated_job_description_test.rb
git commit -m "test: add integration tests for annotated job description"
```

---

## Task 10: Add CLI command for generating annotations

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Add require statement**

In `lib/jojo/cli.rb`, add after existing requires (around line 7):

```ruby
require_relative 'generators/annotation_generator'
```

**Step 2: Add annotate command**

In `lib/jojo/cli.rb`, add before the `generate` command (around line 35):

```ruby
desc "annotate", "Generate job description annotations"
def annotate
  validate_employer_option!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])
  ai_client = Jojo::AIClient.new(config, verbose: options[:verbose])

  say "Generating annotations for #{employer.name}...", :green

  begin
    generator = Jojo::Generators::AnnotationGenerator.new(employer, ai_client, verbose: options[:verbose])
    annotations = generator.generate

    say "✓ Generated #{annotations.length} annotations", :green
    say "  Saved to: #{employer.job_description_annotations_path}", :green
  rescue => e
    say "✗ Error generating annotations: #{e.message}", :red
    exit 1
  end
end
```

**Step 3: Add validate_employer_option! helper**

In `lib/jojo/cli.rb`, add in the private section (around line 200):

```ruby
def validate_employer_option!
  unless options[:employer]
    say "Error: --employer option is required", :red
    say "Usage: jojo annotate -e \"Company Name\"", :yellow
    exit 1
  end
end
```

**Step 4: Integrate into generate workflow**

In `lib/jojo/cli.rb`, add annotation generation step in the `generate` command after resume generation (around line 110):

```ruby
# Generate annotations
begin
  generator = Jojo::Generators::AnnotationGenerator.new(employer, ai_client, verbose: options[:verbose])
  annotations = generator.generate

  say "✓ Generated #{annotations.length} job description annotations", :green
  status_logger.log_step("Annotation Generation",
    tokens: ai_client.total_tokens_used,
    status: "complete",
    annotations_count: annotations.length
  )
rescue => e
  say "✗ Error generating annotations: #{e.message}", :red
  status_logger.log_step("Annotation Generation", status: "failed", error: e.message)
  # Don't exit - annotations are optional, continue with website generation
end
```

**Step 5: Manual test**

Run: `./bin/jojo help`

Expected: Should show "annotate" command in list

**Step 6: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add annotate CLI command and integrate into generate workflow"
```

---

## Task 11: Update implementation plan status

**Files:**
- Modify: `docs/plans/implementation_plan.md`

**Step 1: Mark Phase 6c tasks complete**

In `docs/plans/implementation_plan.md`, update Phase 6c section (around line 457):

```markdown
### Phase 6c: Interactive Job Description ✅

**Goal**: Annotated job description with hover tooltips

**Status**: COMPLETED

#### Tasks:

- [x] AI annotates job description
  - [x] Identify key requirements
  - [x] Match to candidate experience
  - [x] Generate hover tooltip content with tiered matching (strong/moderate/mention)

- [x] Add JavaScript for hover interactions
  - [x] Tooltip positioning
  - [x] Highlighting system
  - [x] Mobile-friendly tap interactions
  - [x] Keyboard navigation support

- [x] Update template with annotated job description section
  - [x] "Compare me to the Job Description" heading
  - [x] Highlighted terms with data attributes
  - [x] All occurrences of matched text annotated
  - [x] Legend showing tier meanings

- [x] Create tests for annotation generation
  - [x] Unit tests for AnnotationGenerator
  - [x] Unit tests for AnnotationPrompt
  - [x] Unit tests for WebsiteGenerator annotation integration
  - [x] Integration tests for full workflow

**Validation**: ✅ Job description terms have hover tooltips showing relevant experience. Mobile tap interactions work. Graceful degradation when annotations unavailable.
```

**Step 2: Commit**

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 6c complete in implementation plan"
```

---

## Task 12: Run all tests

**Files:**
- N/A (testing only)

**Step 1: Run unit tests**

Run: `./bin/jojo test`

Expected: All tests PASS

**Step 2: Run integration tests**

Run: `./bin/jojo test --integration`

Expected: All tests PASS

**Step 3: Run all tests together**

Run: `./bin/jojo test --all`

Expected: All tests PASS

**Step 4: If tests pass, commit confirmation**

```bash
git add -A
git commit -m "test: verify all tests pass for Phase 6c"
```

---

## Manual Testing Checklist

After implementation, test these scenarios manually:

1. **Generate annotations standalone**
   - Run: `./bin/jojo annotate -e "Test Company" -j inputs/test_job.txt`
   - Verify: `employers/test-company/job_description_annotations.json` created
   - Verify: JSON contains array with text, match, tier fields

2. **Generate full website with annotations**
   - Run: `./bin/jojo generate -e "Test Company" -j inputs/test_job.txt`
   - Open: `employers/test-company/website/index.html` in browser
   - Verify: "Compare Me to the Job Description" section appears
   - Verify: Highlighted text visible with different opacity levels

3. **Desktop tooltip interactions**
   - Hover over highlighted text
   - Verify: Tooltip appears above or below
   - Verify: Tooltip shows match text
   - Verify: Tooltip disappears on mouse leave

4. **Mobile tooltip interactions** (use Chrome DevTools mobile emulation)
   - Tap highlighted text
   - Verify: Tooltip appears
   - Tap same text again
   - Verify: Tooltip disappears
   - Tap different highlighted text
   - Verify: First tooltip closes, new one opens

5. **Keyboard navigation**
   - Tab to highlighted text
   - Press Enter
   - Verify: Tooltip appears
   - Press Escape
   - Verify: Tooltip disappears

6. **Graceful degradation**
   - Delete `job_description_annotations.json`
   - Regenerate website: `./bin/jojo website -e "Test Company"`
   - Verify: Website still works, annotation section absent

7. **Multiple occurrences**
   - Create job description with repeated terms (e.g., "Python" appears 3 times)
   - Generate annotations
   - Verify: All 3 occurrences highlighted

8. **Edge cases**
   - Very long tooltip text (>200 characters)
   - Verify: Tooltip doesn't overflow viewport
   - Annotation near bottom of page
   - Verify: Tooltip appears above (not below viewport)

---

## Success Criteria

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Annotations generate successfully from job description + resume
- [ ] All occurrences of annotated text are highlighted
- [ ] Tooltips work on hover (desktop) and tap (mobile)
- [ ] Three visual tiers clearly distinguishable
- [ ] Section omitted gracefully when annotations unavailable
- [ ] Landing page feels polished and professional
- [ ] CLI commands work (`annotate` and `generate`)
- [ ] Manual testing checklist completed

---

## Implementation Notes

### Code Quality

- Follow existing code patterns in the codebase
- Use simple markdown-to-HTML conversion (don't add dependencies)
- Ensure proper HTML escaping for XSS prevention
- Add verbose logging for debugging
- Handle errors gracefully with helpful messages

### Testing Strategy

- Mock AI responses in unit tests
- Test error cases (missing files, invalid JSON)
- Test graceful degradation
- Integration test covers full workflow
- No service tests (all AI calls mocked)

### Performance

- Single tooltip element (reused)
- CSS transitions for smooth UX
- Minimal JavaScript (vanilla, no frameworks)
- Efficient text matching (Regexp.escape)

### Accessibility

- Keyboard navigation (tabindex, Enter, Escape)
- Screen reader support (data attributes)
- High contrast highlights
- Focus states on annotated text
