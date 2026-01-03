# Resume Curation Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform resume generation from LLM-direct-markdown to a hybrid two-pass curation system (filter + generate) with ERB template rendering to eliminate hallucinations in technical fields.

**Architecture:** Two-pass LLM processing with permission-based field control: Pass 1 curates/filters YAML data (respecting read-only, remove, reorder permissions), Pass 2 generates content for rewrite fields only (like summary), ERB template renders final markdown from curated YAML.

**Tech Stack:** Ruby, ERB templates, YAML data structures, Minitest

---

## Phase 1: Foundation - Resume Data Loader

**Goal:** Create `ResumeDataLoader` to load and validate `resume_data.yml` with permission metadata support.

### Task 1.1: Create ResumeDataLoader with basic validation

**Files:**
- Create: `lib/jojo/resume_data_loader.rb`
- Create: `test/unit/resume_data_loader_test.rb`
- Create: `test/fixtures/resume_data.yml`

**Step 1: Write failing test for missing file**

Create `test/unit/resume_data_loader_test.rb`:

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_loader"

describe Jojo::ResumeDataLoader do
  it "raises error when file does not exist" do
    loader = Jojo::ResumeDataLoader.new("nonexistent.yml")

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    _(error.message).must_include "not found"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/resume_data_loader_test.rb`
Expected: FAIL with "uninitialized constant Jojo::ResumeDataLoader"

**Step 3: Create minimal implementation**

Create `lib/jojo/resume_data_loader.rb`:

```ruby
require "yaml"

module Jojo
  class ResumeDataLoader
    class ValidationError < StandardError; end

    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      unless File.exist?(file_path)
        raise ValidationError, "Resume data file not found at #{file_path}"
      end

      {}
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/resume_data_loader_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/resume_data_loader.rb test/unit/resume_data_loader_test.rb
git commit -m "feat: add ResumeDataLoader with file existence validation"
```

### Task 1.2: Add required fields validation

**Files:**
- Modify: `test/unit/resume_data_loader_test.rb`
- Modify: `lib/jojo/resume_data_loader.rb`
- Create: `test/fixtures/resume_data.yml`

**Step 1: Create test fixture**

Create `test/fixtures/resume_data.yml`:

```yaml
name: "Test User"
email: "test@example.com"
phone: "555-1234"
website: "https://example.com"

summary: |
  Professional summary content here.

skills:
  - Ruby
  - Python

experience:
  - company: "Test Corp"
    role: "Developer"
    start_date: "2020-01"
    end_date: "2023-12"
    description: "Did things"
```

**Step 2: Write failing test for required fields**

Add to `test/unit/resume_data_loader_test.rb`:

```ruby
it "validates required fields" do
  # Create temp file missing required name field
  temp_file = "test/fixtures/invalid_resume_missing_name.yml"
  File.write(temp_file, "email: test@example.com\n")

  loader = Jojo::ResumeDataLoader.new(temp_file)

  error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
    loader.load
  end

  _(error.message).must_include "name"

  FileUtils.rm_f(temp_file)
end

it "loads valid resume data" do
  loader = Jojo::ResumeDataLoader.new("test/fixtures/resume_data.yml")
  data = loader.load

  _(data[:name]).must_equal "Test User"
  _(data[:email]).must_equal "test@example.com"
  _(data[:summary]).must_include "Professional summary"
end
```

**Step 3: Run tests to verify they fail**

Run: `ruby -Ilib:test test/unit/resume_data_loader_test.rb`
Expected: FAIL - validation not implemented

**Step 4: Implement validation**

Update `lib/jojo/resume_data_loader.rb`:

```ruby
require "yaml"

module Jojo
  class ResumeDataLoader
    class ValidationError < StandardError; end

    REQUIRED_FIELDS = %w[name summary]
    CONTACT_FIELDS = %w[email phone website]

    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      unless File.exist?(file_path)
        raise ValidationError, "Resume data file not found at #{file_path}"
      end

      data = YAML.load_file(file_path, permitted_classes: [Date])
      validate!(data)
      symbolize_keys_recursive(data)
    end

    private

    def validate!(data)
      errors = []

      # Check required fields
      REQUIRED_FIELDS.each do |field|
        unless data[field] && !data[field].to_s.strip.empty?
          errors << "missing required field '#{field}'"
        end
      end

      # Check at least one contact field
      has_contact = CONTACT_FIELDS.any? { |field| data[field] && !data[field].to_s.strip.empty? }
      unless has_contact
        errors << "must have at least one contact field (email, phone, or website)"
      end

      # Validate array fields if present
      %w[skills languages databases tools experience projects education endorsements].each do |field|
        if data[field] && !data[field].is_a?(Array)
          errors << "'#{field}' must be an array"
        end
      end

      raise ValidationError, errors.join("; ") unless errors.empty?
    end

    def symbolize_keys_recursive(obj)
      case obj
      when Hash
        obj.transform_keys(&:to_sym).transform_values { |v| symbolize_keys_recursive(v) }
      when Array
        obj.map { |item| symbolize_keys_recursive(item) }
      else
        obj
      end
    end
  end
end
```

**Step 5: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/resume_data_loader_test.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/resume_data_loader.rb test/unit/resume_data_loader_test.rb test/fixtures/resume_data.yml
git commit -m "feat: add required fields validation to ResumeDataLoader"
```

---

## Phase 2: ERB Template Rendering

**Goal:** Create `ErbRenderer` to render ERB templates with resume data.

### Task 2.1: Create ErbRenderer with basic rendering

**Files:**
- Create: `lib/jojo/renderers/erb_renderer.rb`
- Create: `test/unit/renderers/erb_renderer_test.rb`

**Step 1: Write failing test**

Create `test/unit/renderers/erb_renderer_test.rb`:

```ruby
require_relative "../../test_helper"
require_relative "../../../lib/jojo/renderers/erb_renderer"

describe Jojo::Renderers::ErbRenderer do
  it "renders ERB template with data" do
    template = "<%= data[:name] %>"
    data = { name: "John Doe" }

    renderer = Jojo::Renderers::ErbRenderer.new(template, data)
    result = renderer.render

    _(result).must_equal "John Doe"
  end

  it "handles missing data gracefully" do
    template = "<%= data[:name] %> <%= data[:missing] %>"
    data = { name: "Jane" }

    renderer = Jojo::Renderers::ErbRenderer.new(template, data)
    result = renderer.render

    _(result).must_equal "Jane "
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/renderers/erb_renderer_test.rb`
Expected: FAIL with "uninitialized constant"

**Step 3: Create implementation**

Create `lib/jojo/renderers/erb_renderer.rb`:

```ruby
require "erb"

module Jojo
  module Renderers
    class ErbRenderer
      attr_reader :template, :data

      def initialize(template, data)
        @template = template
        @data = data
      end

      def render
        ERB.new(template, trim_mode: "-").result(binding)
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/renderers/erb_renderer_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/renderers/erb_renderer.rb test/unit/renderers/erb_renderer_test.rb
git commit -m "feat: add ErbRenderer for template rendering"
```

### Task 2.2: Add file-based template loading

**Files:**
- Modify: `lib/jojo/renderers/erb_renderer.rb`
- Modify: `test/unit/renderers/erb_renderer_test.rb`
- Create: `test/fixtures/templates/test_resume.md.erb`

**Step 1: Create test template**

Create `test/fixtures/templates/test_resume.md.erb`:

```erb
# <%= data[:name] %>

<%= data[:email] %>

<%= data[:summary] %>

<% unless data[:skills].nil? || data[:skills].empty? %>
## Skills

<% data[:skills].each do |skill| %>
- <%= skill %>
<% end %>
<% end %>
```

**Step 2: Write failing test**

Add to `test/unit/renderers/erb_renderer_test.rb`:

```ruby
it "renders from template file" do
  template_path = "test/fixtures/templates/test_resume.md.erb"
  data = {
    name: "John Doe",
    email: "john@example.com",
    summary: "Software developer",
    skills: ["Ruby", "Python"]
  }

  renderer = Jojo::Renderers::ErbRenderer.from_file(template_path, data)
  result = renderer.render

  _(result).must_include "# John Doe"
  _(result).must_include "john@example.com"
  _(result).must_include "## Skills"
  _(result).must_include "- Ruby"
  _(result).must_include "- Python"
end

it "handles conditional sections for empty arrays" do
  template_path = "test/fixtures/templates/test_resume.md.erb"
  data = {
    name: "Jane",
    email: "jane@example.com",
    summary: "Developer",
    skills: []
  }

  renderer = Jojo::Renderers::ErbRenderer.from_file(template_path, data)
  result = renderer.render

  _(result).must_include "# Jane"
  _(result).wont_include "## Skills"
end
```

**Step 3: Run tests to verify they fail**

Run: `ruby -Ilib:test test/unit/renderers/erb_renderer_test.rb`
Expected: FAIL - from_file method doesn't exist

**Step 4: Implement from_file**

Update `lib/jojo/renderers/erb_renderer.rb`:

```ruby
require "erb"

module Jojo
  module Renderers
    class ErbRenderer
      class TemplateNotFoundError < StandardError; end

      attr_reader :template, :data

      def initialize(template, data)
        @template = template
        @data = data
      end

      def self.from_file(template_path, data)
        unless File.exist?(template_path)
          raise TemplateNotFoundError, "Template not found at #{template_path}"
        end

        template_content = File.read(template_path)
        new(template_content, data)
      end

      def render
        ERB.new(template, trim_mode: "-").result(binding)
      end
    end
  end
end
```

**Step 5: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/renderers/erb_renderer_test.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/renderers/erb_renderer.rb test/unit/renderers/erb_renderer_test.rb test/fixtures/templates/
git commit -m "feat: add file-based template loading to ErbRenderer"
```

### Task 2.3: Create default resume template

**Files:**
- Create: `templates/default_resume.md.erb`

**Step 1: Create default template**

Create `templates/default_resume.md.erb`:

```erb
---
margin-left: 2cm
margin-right: 2cm
margin-top: 1.5cm
margin-bottom: 2cm
---

###### [<%= data[:website] %>]<% if data[:email] %> . [<%= data[:email] %>]<% end %>

# <%= data[:name] %>

<%= data[:summary] %>

<% unless data[:skills].nil? || data[:skills].empty? %>
## Skills

<% data[:skills].each do |skill| %>
```<%= skill %>```
<% end %>
<% end %>

<% unless data[:languages].nil? || data[:languages].empty? %>
## Languages & Frameworks

<% data[:languages].each do |lang| %>
```<%= lang %>```
<% end %>
<% end %>

<% unless data[:databases].nil? || data[:databases].empty? %>
## Databases

<% data[:databases].each do |db| %>
```<%= db %>```
<% end %>
<% end %>

<% unless data[:tools].nil? || data[:tools].empty? %>
## Tools & Technologies

<% data[:tools].each do |tool| %>
```<%= tool %>```
<% end %>
<% end %>

<% unless data[:experience].nil? || data[:experience].empty? %>
## Experience

<% data[:experience].each do |job| %>
### <%= job[:role] %>, <%= job[:company] %>

<%= job[:location] %> | <%= job[:start_date] %> - <%= job[:end_date] || 'Present' %>

<%= job[:description] %>

<% unless job[:technologies].nil? || job[:technologies].empty? %>
**Technologies used:** <%= job[:technologies].join(', ') %>
<% end %>

<% unless job[:tags].nil? || job[:tags].empty? %>
**Tags:** <%= job[:tags].join(', ') %>
<% end %>

<% end %>
<% end %>

<% unless data[:projects].nil? || data[:projects].empty? %>
## Projects

<% data[:projects].each do |project| %>
### <%= project[:title] %><% if project[:year] %> (<%= project[:year] %>)<% end %>

<%= project[:description] %>

<% if project[:url] %>
**URL:** <%= project[:url] %>
<% end %>

<% unless project[:skills].nil? || project[:skills].empty? %>
**Skills:** <%= project[:skills].join(', ') %>
<% end %>

<% end %>
<% end %>

<% unless data[:education].nil? || data[:education].empty? %>
## Education

<% data[:education].each do |edu| %>
### <%= edu[:degree] %>, <%= edu[:institution] %><% if edu[:year] %> (<%= edu[:year] %>)<% end %>

<% if edu[:description] %>
<%= edu[:description] %>
<% end %>

<% end %>
<% end %>

<% unless data[:endorsements].nil? || data[:endorsements].empty? %>
## Endorsements

<% data[:endorsements].each do |endorsement| %>
> <%= endorsement[:text] %>

— **<%= endorsement[:author] %>**<% if endorsement[:role] %>, <%= endorsement[:role] %><% end %>

<% end %>
<% end %>
```

**Step 2: Test template manually**

Run: `ruby -Ilib -e "require_relative 'lib/jojo/resume_data_loader'; require_relative 'lib/jojo/renderers/erb_renderer'; data = Jojo::ResumeDataLoader.new('test/fixtures/resume_data.yml').load; puts Jojo::Renderers::ErbRenderer.from_file('templates/default_resume.md.erb', data).render"`
Expected: Valid markdown output

**Step 3: Commit**

```bash
git add templates/default_resume.md.erb
git commit -m "feat: create default resume ERB template"
```

---

## Phase 3: Pass 1 - Filtering/Curation Prompt

**Goal:** Create `ResumeFilterPrompt` for Pass 1 (curation without content modification).

### Task 3.1: Create ResumeFilterPrompt

**Files:**
- Create: `lib/jojo/prompts/resume_filter_prompt.rb`
- Create: `test/unit/prompts/resume_filter_prompt_test.rb`

**Step 1: Write failing test**

Create `test/unit/prompts/resume_filter_prompt_test.rb`:

```ruby
require_relative "../../test_helper"
require_relative "../../../lib/jojo/prompts/resume_filter_prompt"

describe Jojo::Prompts::ResumeFilterPrompt do
  it "generates curation prompt with job description" do
    resume_yaml = "name: John\nskills:\n  - Ruby"
    job_description = "Senior Ruby Developer needed"

    prompt = Jojo::Prompts::ResumeFilterPrompt.generate(
      resume_yaml: resume_yaml,
      job_description: job_description
    )

    _(prompt).must_include "curating resume data"
    _(prompt).must_include job_description
    _(prompt).must_include "permission"
    _(prompt).must_include "remove"
    _(prompt).must_include "reorder"
  end

  it "includes research when provided" do
    resume_yaml = "name: John"
    job_description = "Developer role"
    research = "Company values innovation"

    prompt = Jojo::Prompts::ResumeFilterPrompt.generate(
      resume_yaml: resume_yaml,
      job_description: job_description,
      research: research
    )

    _(prompt).must_include research
  end

  it "works without research" do
    resume_yaml = "name: John"
    job_description = "Developer role"

    prompt = Jojo::Prompts::ResumeFilterPrompt.generate(
      resume_yaml: resume_yaml,
      job_description: job_description
    )

    _(prompt).must_include "curating resume data"
    _(prompt).wont_include "Research Insights"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/prompts/resume_filter_prompt_test.rb`
Expected: FAIL with "uninitialized constant"

**Step 3: Create implementation**

Create `lib/jojo/prompts/resume_filter_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module ResumeFilterPrompt
      def self.generate(resume_yaml:, job_description:, research: nil, retention_target: 70)
        <<~PROMPT
          You are curating resume data for a specific job opportunity.

          Your task: Filter and reorder resume_data.yml to include ~#{retention_target}% most relevant content.

          # Job Description

          #{job_description}

          #{research_section(research)}

          # Resume Data (YAML)

          ```yaml
          #{resume_yaml}
          ```

          # Field Permissions (STRICTLY ENFORCED)

          You can ONLY perform these operations based on permission metadata in comments:

          - **read-only** (default): DO NOT modify, delete, add, or reorder items
          - **remove**: You MAY include/exclude items (no modifications or reordering)
          - **reorder**: You MAY reorder items within section, most relevant first (no modifications or deletions)
          - **rewrite**: SKIP in this pass (handled in Pass 2)

          **Permission examples:**
          - `# permission: remove` → can filter items
          - `# permission: reorder` → can reorder items
          - `# permission: remove, reorder` → can filter AND reorder
          - No comment → read-only, preserve exactly

          # Curation Rules

          1. **Respect permission metadata** - Only perform allowed operations
          2. **Remove irrelevant items** - For fields with "remove" permission, filter to #{retention_target}% most relevant
          3. **Reorder by relevance** - For fields with "reorder" permission, put most relevant first
          4. **Never modify content** - This is a filtering pass only
          5. **Never add new items** - Only include items from source
          6. **Preserve YAML structure** - Maintain exact formatting and comments
          7. **Empty sections OK** - If nothing is relevant, use empty array: `skills: []`

          # Output Format

          **CRITICAL: Output ONLY the filtered YAML - no code blocks, no commentary**

          - Start immediately with the YAML content
          - DO NOT wrap in ```yaml...``` code blocks
          - DO NOT add explanations or preamble
          - Preserve all permission comments
          - The output should be ready to save as .yml file

          Begin filtering now:
        PROMPT
      end

      def self.research_section(research)
        return "" unless research

        <<~SECTION
          # Research Insights

          #{research}
        SECTION
      end

      private_class_method :research_section
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/prompts/resume_filter_prompt_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/prompts/resume_filter_prompt.rb test/unit/prompts/resume_filter_prompt_test.rb
git commit -m "feat: add ResumeFilterPrompt for Pass 1 curation"
```

---

## Phase 4: Pass 2 - Content Generation Prompt

**Goal:** Create `ResumeCuratePrompt` for Pass 2 (generate content for rewrite fields).

### Task 4.1: Create ResumeCuratePrompt

**Files:**
- Create: `lib/jojo/prompts/resume_curate_prompt.rb`
- Create: `test/unit/prompts/resume_curate_prompt_test.rb`

**Step 1: Write failing test**

Create `test/unit/prompts/resume_curate_prompt_test.rb`:

```ruby
require_relative "../../test_helper"
require_relative "../../../lib/jojo/prompts/resume_curate_prompt"

describe Jojo::Prompts::ResumeCuratePrompt do
  it "generates generation prompt for rewrite fields" do
    filtered_yaml = "name: John\nsummary: Developer"
    job_description = "Senior Ruby Developer"

    prompt = Jojo::Prompts::ResumeCuratePrompt.generate(
      filtered_yaml: filtered_yaml,
      job_description: job_description
    )

    _(prompt).must_include "tailoring content"
    _(prompt).must_include "rewrite permission"
    _(prompt).must_include job_description
  end

  it "includes voice and tone when provided" do
    filtered_yaml = "name: John"
    job_description = "Developer"
    voice_and_tone = "Professional and friendly"

    prompt = Jojo::Prompts::ResumeCuratePrompt.generate(
      filtered_yaml: filtered_yaml,
      job_description: job_description,
      voice_and_tone: voice_and_tone
    )

    _(prompt).must_include voice_and_tone
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/prompts/resume_curate_prompt_test.rb`
Expected: FAIL

**Step 3: Create implementation**

Create `lib/jojo/prompts/resume_curate_prompt.rb`:

```ruby
module Jojo
  module Prompts
    module ResumeCuratePrompt
      def self.generate(filtered_yaml:, job_description:, research: nil, voice_and_tone: nil)
        <<~PROMPT
          You are tailoring content for specific fields in a resume.

          Your task: Generate tailored content ONLY for fields with "rewrite" permission.

          # Job Description

          #{job_description}

          #{research_section(research)}

          # Filtered Resume Data (YAML)

          This data has already been curated (Pass 1). Now tailor fields marked with `rewrite` permission.

          ```yaml
          #{filtered_yaml}
          ```

          # Generation Rules

          1. **Only modify fields with `# permission: rewrite`** (typically: summary, job descriptions, education descriptions)
          2. **Use original content as factual baseline** - no new claims
          3. **Tailor to job requirements** - emphasize relevant aspects
          4. **Remain truthful** - can rephrase but not fabricate
          5. **All other fields are read-only** - preserve exactly as-is

          # Writing Guidelines

          #{voice_and_tone_section(voice_and_tone)}

          - Use strong action verbs (led, built, designed, implemented)
          - Emphasize achievements relevant to target role
          - Match company culture and language from research
          - Be concise and impactful
          - Professional summary should be 2-4 sentences

          # Output Format

          **CRITICAL: Output ONLY the complete YAML with tailored content - no code blocks, no commentary**

          - Start immediately with the YAML content
          - DO NOT wrap in ```yaml...``` code blocks
          - DO NOT add explanations
          - Include ALL fields from input (modify only rewrite fields)
          - Preserve all permission comments
          - The output should be ready to save as .yml file

          Begin tailoring now:
        PROMPT
      end

      def self.research_section(research)
        return "" unless research

        <<~SECTION
          # Research Insights

          #{research}
        SECTION
      end

      def self.voice_and_tone_section(voice_and_tone)
        return "**Voice and Tone:** Professional, clear, and achievement-focused" unless voice_and_tone

        "**Voice and Tone:** #{voice_and_tone}"
      end

      private_class_method :research_section, :voice_and_tone_section
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/prompts/resume_curate_prompt_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/prompts/resume_curate_prompt.rb test/unit/prompts/resume_curate_prompt_test.rb
git commit -m "feat: add ResumeCuratePrompt for Pass 2 content generation"
```

---

## Phase 5: Integration - Update ResumeGenerator

**Goal:** Refactor `ResumeGenerator` to orchestrate two-pass LLM + ERB rendering.

### Task 5.1: Update ResumeGenerator for two-pass workflow

**Files:**
- Modify: `lib/jojo/generators/resume_generator.rb`
- Modify: `test/unit/generators/resume_generator_test.rb`
- Create: `test/fixtures/resume_data_filtered.yml`
- Create: `test/fixtures/resume_data_curated.yml`

**Step 1: Write failing integration test**

Add to `test/unit/generators/resume_generator_test.rb`:

```ruby
it "generates resume using two-pass workflow" do
  # Setup: Create resume_data.yml in fixtures
  resume_data_path = File.join("test/fixtures", "resume_data.yml")

  # Mock AI client for two passes
  filter_output = File.read("test/fixtures/resume_data_filtered.yml")
  curate_output = File.read("test/fixtures/resume_data_curated.yml")

  @ai_client.expect(:generate_text, filter_output, [String])
  @ai_client.expect(:generate_text, curate_output, [String])

  @config.expect(:voice_and_tone, "professional")
  @config.expect(:base_url, "https://example.com")
  @config.expect(:resume_template, "templates/default_resume.md.erb")

  result = @generator.generate

  # Verify two AI calls were made
  @ai_client.verify

  # Verify output is markdown (not YAML)
  _(result).must_include "# Test User"
  _(result).wont_include "name: Test User"

  # Verify intermediate files were created
  filtered_path = File.join(@employer.base_path, "resume_data_filtered.yml")
  curated_path = File.join(@employer.base_path, "resume_data_curated.yml")

  _(File.exist?(filtered_path)).must_equal true
  _(File.exist?(curated_path)).must_equal true
end
```

**Step 2: Create test fixtures for filtered/curated data**

Create `test/fixtures/resume_data_filtered.yml`:

```yaml
name: "Test User"
email: "test@example.com"
summary: |
  Professional summary here.
skills:
  - Ruby
  - Python
```

Create `test/fixtures/resume_data_curated.yml`:

```yaml
name: "Test User"
email: "test@example.com"
summary: |
  Tailored professional summary for this specific role.
skills:
  - Ruby
  - Python
```

**Step 3: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb`
Expected: FAIL - ResumeGenerator still uses old single-pass approach

**Step 4: Refactor ResumeGenerator**

Update `lib/jojo/generators/resume_generator.rb`:

```ruby
require "yaml"
require_relative "../resume_data_loader"
require_relative "../prompts/resume_filter_prompt"
require_relative "../prompts/resume_curate_prompt"
require_relative "../renderers/erb_renderer"

module Jojo
  module Generators
    class ResumeGenerator
      attr_reader :employer, :ai_client, :config, :verbose, :inputs_path, :overwrite_flag, :cli_instance

      def initialize(employer, ai_client, config:, verbose: false, inputs_path: "inputs", overwrite_flag: nil, cli_instance: nil)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @verbose = verbose
        @inputs_path = inputs_path
        @overwrite_flag = overwrite_flag
        @cli_instance = cli_instance
      end

      def generate
        log "Loading resume data..."
        resume_data = load_resume_data

        log "Gathering job context..."
        job_context = gather_job_context

        log "Pass 1: Filtering/curating resume data..."
        filtered_yaml = pass1_filter(resume_data, job_context)
        save_intermediate_yaml(filtered_yaml, "resume_data_filtered.yml")

        log "Pass 2: Tailoring rewrite fields..."
        curated_yaml = pass2_curate(filtered_yaml, job_context)
        save_intermediate_yaml(curated_yaml, "resume_data_curated.yml")

        log "Rendering resume from template..."
        resume_markdown = render_template(curated_yaml)

        log "Adding landing page link..."
        resume_with_link = add_landing_page_link(resume_markdown, job_context)

        log "Saving resume to #{employer.resume_path}..."
        save_resume(resume_with_link)

        log "Resume generation complete!"
        resume_with_link
      end

      private

      def load_resume_data
        resume_data_path = File.join(inputs_path, "resume_data.yml")
        loader = ResumeDataLoader.new(resume_data_path)
        loader.load
      end

      def gather_job_context
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end

        {
          job_description: File.read(employer.job_description_path),
          research: read_research,
          company_name: employer.company_name,
          company_slug: employer.slug
        }
      end

      def read_research
        return nil unless File.exist?(employer.research_path)
        File.read(employer.research_path)
      end

      def pass1_filter(resume_data, job_context)
        # Convert resume data back to YAML for LLM processing
        resume_yaml = resume_data.to_yaml

        prompt = Prompts::ResumeFilterPrompt.generate(
          resume_yaml: resume_yaml,
          job_description: job_context[:job_description],
          research: job_context[:research]
        )

        ai_client.generate_text(prompt)
      end

      def pass2_curate(filtered_yaml, job_context)
        prompt = Prompts::ResumeCuratePrompt.generate(
          filtered_yaml: filtered_yaml,
          job_description: job_context[:job_description],
          research: job_context[:research],
          voice_and_tone: config.voice_and_tone
        )

        ai_client.generate_text(prompt)
      end

      def render_template(curated_yaml)
        curated_data = YAML.load(curated_yaml, permitted_classes: [Date])
        curated_data = symbolize_keys_recursive(curated_data)

        template_path = config.resume_template || "templates/default_resume.md.erb"
        renderer = Renderers::ErbRenderer.from_file(template_path, curated_data)
        renderer.render
      end

      def save_intermediate_yaml(yaml_content, filename)
        path = File.join(employer.base_path, filename)
        File.write(path, yaml_content)
      end

      def add_landing_page_link(resume_content, job_context)
        link = "**Specifically for #{job_context[:company_name]}**: #{config.base_url}/resume/#{job_context[:company_slug]}"
        "#{link}\n\n#{resume_content}"
      end

      def save_resume(content)
        if cli_instance
          cli_instance.with_overwrite_check(employer.resume_path, overwrite_flag) do
            File.write(employer.resume_path, content)
          end
        else
          File.write(employer.resume_path, content)
        end
      end

      def log(message)
        puts "  [ResumeGenerator] #{message}" if verbose
      end

      def symbolize_keys_recursive(obj)
        case obj
        when Hash
          obj.transform_keys(&:to_sym).transform_values { |v| symbolize_keys_recursive(v) }
        when Array
          obj.map { |item| symbolize_keys_recursive(item) }
        else
          obj
        end
      end
    end
  end
end
```

**Step 5: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb`
Expected: PASS

**Step 6: Update old tests or mark as pending**

Review remaining tests in `resume_generator_test.rb` and update them to work with new two-pass approach, or remove tests that are no longer relevant (like project selection tests).

**Step 7: Commit**

```bash
git add lib/jojo/generators/resume_generator.rb test/unit/generators/resume_generator_test.rb test/fixtures/resume_data_*.yml
git commit -m "refactor: update ResumeGenerator to two-pass workflow with ERB rendering"
```

### Task 5.2: Add caching for regeneration

**Files:**
- Modify: `lib/jojo/generators/resume_generator.rb`
- Modify: `test/unit/generators/resume_generator_test.rb`

**Step 1: Write test for cache usage**

Add to `test/unit/generators/resume_generator_test.rb`:

```ruby
it "skips AI calls when curated data exists" do
  # Pre-create curated data file
  curated_path = File.join(@employer.base_path, "resume_data_curated.yml")
  curated_data = {
    name: "Cached User",
    email: "cached@example.com",
    summary: "From cache"
  }
  File.write(curated_path, curated_data.to_yaml)

  # Mock config to return template path (no AI calls expected)
  @config.expect(:resume_template, "templates/default_resume.md.erb")
  @config.expect(:base_url, "https://example.com")

  # Should not call AI
  result = @generator.generate

  _(result).must_include "# Cached User"
  _(result).must_include "From cache"
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb -n "/cache/"`
Expected: FAIL - AI calls still made

**Step 3: Add cache checking logic**

Update `lib/jojo/generators/resume_generator.rb` `generate` method:

```ruby
def generate
  curated_path = File.join(employer.base_path, "resume_data_curated.yml")

  if File.exist?(curated_path)
    log "Using cached curated data from #{curated_path}"
    curated_yaml = File.read(curated_path)
  else
    log "Loading resume data..."
    resume_data = load_resume_data

    log "Gathering job context..."
    job_context = gather_job_context

    log "Pass 1: Filtering/curating resume data..."
    filtered_yaml = pass1_filter(resume_data, job_context)
    save_intermediate_yaml(filtered_yaml, "resume_data_filtered.yml")

    log "Pass 2: Tailoring rewrite fields..."
    curated_yaml = pass2_curate(filtered_yaml, job_context)
    save_intermediate_yaml(curated_yaml, "resume_data_curated.yml")
  end

  log "Rendering resume from template..."
  resume_markdown = render_template(curated_yaml)

  # For cached path, we need minimal job context
  job_context ||= {
    company_name: employer.company_name,
    company_slug: employer.slug
  }

  log "Adding landing page link..."
  resume_with_link = add_landing_page_link(resume_markdown, job_context)

  log "Saving resume to #{employer.resume_path}..."
  save_resume(resume_with_link)

  log "Resume generation complete!"
  resume_with_link
end
```

**Step 4: Run tests to verify they pass**

Run: `ruby -Ilib:test test/unit/generators/resume_generator_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/generators/resume_generator.rb test/unit/generators/resume_generator_test.rb
git commit -m "feat: add caching to skip AI calls when curated data exists"
```

---

## Phase 6: Migration and Documentation

**Goal:** Create migration path from old structure to new structure.

### Task 6.1: Add resume_template to config

**Files:**
- Modify: `lib/jojo/config.rb`
- Modify: `test/fixtures/valid_config.yml`

**Step 1: Update test fixture**

Add to `test/fixtures/valid_config.yml`:

```yaml
resume_template: templates/default_resume.md.erb
```

**Step 2: Update Config class**

Add `resume_template` attribute to config loader (check existing implementation and add the new field).

**Step 3: Test**

Run: `ruby -Ilib:test test/unit/config_test.rb` (if exists)
Expected: PASS

**Step 4: Commit**

```bash
git add lib/jojo/config.rb test/fixtures/valid_config.yml
git commit -m "feat: add resume_template config option"
```

### Task 6.2: Create example resume_data.yml

**Files:**
- Create: `templates/resume_data.yml.example`

**Step 1: Create example file**

Create `templates/resume_data.yml.example`:

```yaml
# Resume Data Structure
# Permission metadata controls what the LLM can do with each field:
#   - read-only (default): LLM cannot modify
#   - remove: LLM can filter items
#   - reorder: LLM can reorder by relevance
#   - rewrite: LLM can generate tailored content

# Contact Information (read-only by default)
name: "Your Name"
email: "your.email@example.com"
phone: "555-1234"
website: "https://yourwebsite.com"
linkedin: "https://linkedin.com/in/yourprofile"
github: "https://github.com/yourusername"

# Professional Summary (LLM tailors for each job)
summary: | # permission: rewrite
  Your professional summary here. This will be tailored for each role.
  Include your key strengths, experience level, and what you're passionate about.

# Skills (LLM can filter and reorder)
skills: # permission: remove, reorder
  - Your primary skill
  - Another key skill
  - Additional skills

# Languages & Frameworks (LLM can reorder by relevance)
languages: # permission: reorder
  - Python
  - JavaScript
  - Ruby

# Databases (LLM can filter and reorder)
databases: # permission: remove, reorder
  - PostgreSQL
  - MongoDB

# Tools (LLM can filter and reorder)
tools: # permission: remove, reorder
  - Git
  - Docker
  - CI/CD

# Work Experience (LLM can reorder jobs by relevance)
experience: # permission: reorder
  - company: "Company Name"
    role: "Your Role"
    location: "City, State"
    start_date: "2020-01"
    end_date: "2023-12"  # or null for current position
    description: | # permission: rewrite
      Your job description here. This will be tailored.
      Use bullet points or paragraphs to describe your work.
    technologies: # permission: remove, reorder
      - Tech 1
      - Tech 2
    tags: # permission: remove, reorder
      - relevant tag
      - another tag

# Projects (LLM can reorder by relevance)
projects: # permission: reorder
  - title: "Project Name"
    description: "Brief description of the project"
    url: "https://github.com/you/project"
    year: 2024
    context: "open source"  # or "personal", "freelance", etc.
    skills: # permission: reorder
      - Skill 1
      - Skill 2

# Education (read-only by default, descriptions can be tailored)
education:
  - institution: "University Name"
    degree: "Degree Name"
    year: "2020"
    description: | # permission: rewrite
      Optional description of your studies, research, or achievements.

# Endorsements (LLM can filter)
endorsements: # permission: remove
  - author: "Colleague Name"
    role: "Their Title, Company"
    text: | # permission: read-only
      The endorsement text. This is always preserved exactly as written.
    linkedin: "https://linkedin.com/in/colleague"
```

**Step 2: Commit**

```bash
git add templates/resume_data.yml.example
git commit -m "docs: add example resume_data.yml template"
```

### Task 6.3: Update README/documentation

**Files:**
- Modify: `README.md` or create `docs/resume_generation.md`

**Step 1: Document new workflow**

Add section explaining:
- Two-pass LLM workflow
- Permission metadata system
- How to create resume_data.yml
- How to customize templates
- Caching behavior

**Step 2: Commit**

```bash
git add README.md  # or docs/resume_generation.md
git commit -m "docs: document two-pass resume generation workflow"
```

### Task 6.4: Remove deprecated code

**Files:**
- Delete: `test/unit/resume_generator_projects_test.rb` (project selection tests)
- Modify: Remove project-related code from `resume_generator.rb` if still present

**Step 1: Remove project selection logic**

Since projects are now part of resume_data.yml and handled by LLM curation, remove the old `ProjectSelector` and `load_projects` method.

**Step 2: Run full test suite**

Run: `./bin/jojo test`
Expected: All tests pass

**Step 3: Commit**

```bash
git add lib/jojo/generators/resume_generator.rb
git rm test/unit/resume_generator_projects_test.rb
git commit -m "refactor: remove deprecated project selection code"
```

---

## Validation Checklist

After completing all phases, verify:

- [ ] `./bin/jojo resume -e "test-employer"` generates resume using two-pass workflow
- [ ] `resume_data_filtered.yml` persists with filtered content
- [ ] `resume_data_curated.yml` persists with tailored summary
- [ ] Re-running resume generation uses cached curated data (no API calls)
- [ ] Template renders consistent markdown structure
- [ ] Read-only fields are never modified
- [ ] Reorder fields have same items in different order
- [ ] Remove fields contain subset of original items
- [ ] Rewrite fields are tailored to job description
- [ ] All tests pass: `./bin/jojo test`

---

## Success Criteria

✅ Resume generation uses two-pass LLM workflow (filter → curate)
✅ Permission metadata controls LLM operations per field
✅ ERB template renders final markdown
✅ Intermediate YAML files persist for debugging/regeneration
✅ Caching avoids redundant API calls
✅ No hallucinations in technical fields (read-only enforcement)
✅ Tailored content in appropriate fields (summaries, descriptions)
✅ All tests pass
✅ Documentation updated

