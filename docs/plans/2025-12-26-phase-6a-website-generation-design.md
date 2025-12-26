# Phase 6a: Website Generation - Foundation & Core Content

## Date
2025-12-26

## Overview

Phase 6a implements the foundation of website generation for Jojo, creating a template-based system that generates personalized landing pages for job applications. This is the first of multiple sub-phases that will progressively add interactive features to the landing page.

## Scope

### In Scope for Phase 6a
- Template system with support for multiple templates
- Default responsive HTML template with inline CSS
- AI-generated personalized branding statement
- Masthead section (H1, H4, optional branding image)
- Call-to-action section (contact/Calendly link)
- CLI integration with `--template` option
- Branding image support (optional)
- Comprehensive tests

### Out of Scope (Future Phases)
- Phase 6b: Portfolio highlights and project cards
- Phase 6c: Interactive annotated job description with hover tooltips
- Phase 6d: Recommendations carousel
- Phase 6e: FAQ accordion

## Architecture

### Component Structure

Following the existing generator pattern:

```
lib/jojo/generators/website_generator.rb   # Main generator class
lib/jojo/prompts/website_prompt.rb         # AI prompts for content generation
templates/website/default.html.erb         # Default HTML template
templates/website/                         # Directory for multiple templates
```

### Data Flow

1. WebsiteGenerator gathers inputs:
   - Job description (required)
   - Tailored resume (required)
   - Research (optional)
   - Job details YAML (optional)
   - Config settings
2. Calls AI to generate personalized branding statement
3. Loads selected template (default or specified via `--template`)
4. Renders template with AI-generated content + config data
5. Copies branding image from inputs/ if exists
6. Saves to `employers/#{slug}/website/index.html`
7. Logs to status_log.md

### Template Selection

Templates are stored in `templates/website/#{template_name}.html.erb`

**CLI Usage:**
```bash
./bin/jojo website -e "Acme Corp" -j job.txt --template modern
./bin/jojo generate -e "Acme Corp" -j job.txt --template professional
```

**Default Behavior:**
- Uses `default` template if no `--template` flag provided
- Raises error with helpful message if template doesn't exist

### Dependencies

No new gems required:
- ERB for template rendering
- Existing AI client (ruby_llm via ai_client.rb)
- FileUtils for file operations

## Template Design

### Default Template Structure

The `templates/website/default.html.erb` template will be a complete HTML5 document:

**Template Variables Available:**
```ruby
seeker_name           # from config
company_name          # from employer
job_title             # from job_details.yml (optional)
branding_statement    # AI-generated
cta_text              # from config (e.g., "Schedule a call")
cta_link              # from config (Calendly URL or mailto:)
has_branding_image    # boolean
branding_image_path   # relative path if exists
base_url              # from config
company_slug          # for links back to resume/cover letter
```

**Sections:**
1. **HTML head** - meta tags, viewport, title, inline CSS
2. **Masthead** - H1 "Am I a good match for [Company]?", H4 subtitle, optional image
3. **Branding Statement** - AI-generated personalized pitch (2-3 paragraphs)
4. **CTA Section** - Prominent call-to-action button/link
5. **Footer** - Links to download resume.md, cover_letter.md

**Styling Approach:**
- Inline CSS (no external stylesheets for simplicity)
- CSS custom properties for future theming support
- Mobile-responsive design using media queries
- Flexbox/Grid for layout
- Clean, professional aesthetic
- High contrast for accessibility
- No JavaScript dependencies (Phase 6a is static)

## AI Prompt Design

### Branding Statement Generation

**Purpose:** Generate a personalized 2-3 paragraph statement positioning the candidate as ideal for this specific role.

**Input Parameters:**
```ruby
Prompts::Website.generate_branding_statement(
  job_description: job_description,
  research: research,           # optional
  resume: resume,               # tailored resume
  job_details: job_details,     # optional
  company_name: company_name,
  seeker_name: seeker_name,
  voice_and_tone: voice_and_tone
)
```

**Strategy:**
- Use text_generation_ai (Haiku) for speed and cost efficiency
- Provide clear output format (plain text, no markdown headers)
- Include examples of good vs bad branding statements
- Graceful degradation if research is missing
- Focus on "why me for this company" not generic pitch
- Reference key insights from research
- Highlight 2-3 most relevant qualifications from resume
- Target length: 150-250 words

**Output Format:**
Plain text paragraphs that can be dropped directly into `<div class="branding">` in the template. Template handles all styling.

## Generator Implementation

### WebsiteGenerator Class

```ruby
module Jojo
  module Generators
    class WebsiteGenerator
      attr_reader :employer, :ai_client, :config, :verbose, :template_name

      def initialize(employer, ai_client, config:, template: 'default', verbose: false)
        @employer = employer
        @ai_client = ai_client
        @config = config
        @template_name = template
        @verbose = verbose
      end

      def generate
        # Main workflow
      end

      private

      def gather_inputs
        # Read job description, research, resume, job_details
        # Graceful fallbacks for optional inputs
      end

      def generate_branding_statement(inputs)
        # Build prompt and call AI
      end

      def prepare_template_vars(branding_statement, inputs)
        # Build hash of all ERB variables
      end

      def render_template(template_vars)
        # Load template file, render with ERB
      end

      def copy_branding_image
        # Check inputs/ for image files, copy to website/
      end

      def save_website(html)
        # Write HTML to index.html
      end

      def log(message)
        # Verbose logging
      end
    end
  end
end
```

### Key Methods

**gather_inputs:**
- Required: job_description, resume, config (raise if missing)
- Optional: research, job_details, branding_image (log warning, continue)
- Returns hash with all available inputs

**generate_branding_statement:**
- Builds prompt using Prompts::Website
- Calls ai_client.generate_text
- Returns plain text branding statement

**prepare_template_vars:**
- Builds hash with all ERB variables
- Handles optional fields gracefully
- Processes branding image path if exists

**render_template:**
- Loads template from `templates/website/#{template_name}.html.erb`
- Raises helpful error if template doesn't exist
- Renders with ERB.new(template).result(binding)

**copy_branding_image:**
- Checks for `inputs/branding_image.{jpg,jpeg,png,gif}` (first match wins)
- Copies to `employers/#{slug}/website/branding_image.{ext}`
- Returns true if copied, false if no image found

**save_website:**
- Ensures website directory exists
- Writes HTML to index.html
- Returns path to generated file

## CLI Integration

### Class Option Addition

Add to `lib/jojo/cli.rb`:

```ruby
class_option :template,
  type: :string,
  aliases: '-t',
  desc: 'Website template name (default: default)',
  default: 'default'
```

### Website Command

```ruby
desc "website", "Generate website only"
def website
  validate_options!
  employer = create_employer
  employer.create_directory!

  website_generator = WebsiteGenerator.new(
    employer,
    ai_client,
    config: config,
    template: options[:template],
    verbose: options[:verbose]
  )

  website = website_generator.generate
  logger.log("Website generated", metadata: {template: options[:template]})

  puts "Website generated at #{employer.index_html_path}"
end
```

### Generate Command Update

Add website generation step after cover_letter:

```ruby
desc "generate", "Generate everything"
def generate
  # ... existing steps (research, resume, cover_letter)

  # Add website generation
  puts "\nGenerating website..." if options[:verbose]
  website_generator = WebsiteGenerator.new(
    employer,
    ai_client,
    config: config,
    template: options[:template],
    verbose: options[:verbose]
  )
  website = website_generator.generate
  logger.log("Website generated", metadata: {template: options[:template]})
end
```

### Usage Examples

```bash
# Generate website only with default template
./bin/jojo website -e "Acme Corp" -j job.txt

# Generate website with custom template
./bin/jojo website -e "Acme Corp" -j job.txt --template modern

# Generate everything with custom template
./bin/jojo generate -e "Acme Corp" -j job.txt -t professional
```

## Configuration Changes

### Config.yml Updates

Add website section to `templates/config.yml.erb`:

```yaml
seeker_name: <%= seeker_name %>
base_url: https://yoursite.com
reasoning_ai:
  service: anthropic
  model: sonnet
text_generation_ai:
  service: anthropic
  model: haiku
voice_and_tone: professional and friendly

# Website configuration
website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

### Config Class Methods

Add to `lib/jojo/config.rb`:

```ruby
def website_cta_text
  config.dig('website', 'cta_text') || 'Get in Touch'
end

def website_cta_link
  config.dig('website', 'cta_link') || "mailto:#{seeker_name.downcase.gsub(' ', '.')}@example.com"
end
```

**Graceful Defaults:**
- If `website` section missing: use sensible defaults
- If `cta_text` missing: "Get in Touch"
- If `cta_link` missing: construct mailto from seeker_name
- No hard requirements - website generation always works

## Testing Strategy

### Unit Tests

**test/unit/website_generator_test.rb:**
```ruby
- test_generate_creates_index_html
- test_generate_with_all_inputs
- test_generate_with_minimal_inputs (no research, no job_details)
- test_generate_with_custom_template
- test_generate_raises_when_template_missing
- test_generate_raises_when_resume_missing
- test_generate_raises_when_job_description_missing
- test_copy_branding_image_when_exists
- test_skip_branding_image_when_missing
- test_render_template_with_all_variables
- test_graceful_degradation_without_optional_inputs
```

**test/unit/website_prompt_test.rb:**
```ruby
- test_branding_statement_prompt_includes_company_name
- test_branding_statement_prompt_includes_job_description
- test_branding_statement_prompt_includes_research_when_available
- test_branding_statement_prompt_without_research
- test_branding_statement_prompt_includes_voice_and_tone
- test_output_format_specification
```

### Integration Tests

**test/integration/website_workflow_test.rb:**
```ruby
- test_website_command_end_to_end
- test_generate_command_includes_website
- test_multiple_template_selection
```

### Test Fixtures

```
test/fixtures/templates/test_template.html.erb  # Simplified test template
test/fixtures/branding_image.jpg                # Small test image
```

### Mocking Strategy

- Mock `ai_client.generate_text` to return canned branding statements
- Mock file system operations where needed for isolation
- Use real ERB rendering to catch template syntax bugs
- Follow existing test patterns from ResumeGenerator, CoverLetterGenerator

## File Organization

### New Files

```
lib/jojo/generators/website_generator.rb
lib/jojo/prompts/website_prompt.rb
templates/website/default.html.erb
test/unit/website_generator_test.rb
test/unit/website_prompt_test.rb
test/integration/website_workflow_test.rb
test/fixtures/templates/test_template.html.erb
test/fixtures/branding_image.jpg
```

### Modified Files

```
lib/jojo/cli.rb                    # Add --template option, wire up website command
lib/jojo/config.rb                 # Add website_cta_text, website_cta_link methods
templates/config.yml.erb           # Add website section
```

### Generated Output

```
employers/acme-corp/
  website/
    index.html              # Generated landing page
    branding_image.jpg      # Copied from inputs/ if exists
```

## Success Criteria

Phase 6a is complete when:

✅ Template system supports multiple templates via `--template` flag
✅ Default template is responsive and accessible
✅ AI generates personalized branding statements
✅ Masthead, branding, and CTA sections render correctly
✅ Branding images are copied when present
✅ `./bin/jojo website` command works standalone
✅ `./bin/jojo generate` includes website generation
✅ All unit tests pass
✅ All integration tests pass
✅ Documentation is updated

## Future Phases

**Phase 6b - Portfolio Highlights:**
- AI extracts relevant projects from resume
- Static project cards with descriptions
- External portfolio links

**Phase 6c - Interactive Job Description:**
- AI annotates job requirements with matching experience
- Hover tooltip interactions (JavaScript)
- Highlighting system

**Phase 6d - Recommendations Carousel:**
- Parse inputs/recommendations.md
- JavaScript carousel component
- Quote formatting

**Phase 6e - FAQ Accordion:**
- AI generates role-specific FAQs
- JavaScript accordion component
- Standard + custom questions

## Notes

- Focus on simplicity and working software over perfect design
- Static content only (no JavaScript) for Phase 6a
- Template customization (colors, fonts) deferred to later phases
- Multiple template support enables future experimentation
- All optional features degrade gracefully
