# Improved Setup Process Design

**Date**: 2025-12-29
**Status**: Approved

## Problem Statement

The current setup process is multi-step, verbose, and requires manual copying of templates. Users must:
1. Manually copy `.env.example` to `.env` and edit it
2. Run `jojo setup` to create `config.yml`
3. Manually copy templates from `templates/` to `inputs/`
4. Edit multiple files before they can start using jojo

This creates friction and increases the likelihood users will skip important setup steps.

## Goals

1. **Single command setup** - `jojo setup` handles everything
2. **Context-aware** - Detect existing configuration and only prompt for missing pieces
3. **Conversational** - Natural question flow, not a rigid form
4. **Safe** - Never overwrite existing files without explicit permission
5. **Clear next steps** - Users know exactly what to do after setup completes

## Design Overview

### Overall Architecture

**Detection Phase (Silent)**
- Check for existing `.env`, `config.yml`, and input files
- Determine what needs to be created vs. what can be skipped

**Conversational Setup Phase**
- Ask questions one at a time, only for missing configuration
- Clear feedback: "✓ .env already exists (skipped)" vs "Let's set up your API key..."
- Group related prompts naturally without explicit "Step X/Y" labels

**File Creation Phase**
- Create missing files from templates
- Never overwrite existing files (safe and predictable)
- Copy templates to `inputs/` with example content intact

**Summary Phase**
- Report what was created vs. skipped
- Show clear next steps with file paths
- Remind users which files need customization

**Key Principles:**
- **Idempotent**: Running `jojo setup` multiple times is safe - it only fills gaps
- **Transparent**: Always tell users what's happening and why
- **Non-destructive**: Never modifies existing files without explicit `--force` flag
- **Helpful**: Guide users to completion with clear actionable next steps

## Template Validation Mechanism

### The Marker System

Each template file includes a special marker comment that users should delete when customizing:

**Markdown files:**
```markdown
<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line after customizing -->
```

**YAML files:**
```yaml
# JOJO_TEMPLATE_PLACEHOLDER - Delete this line after customizing
```

### Validation Behavior

When users run `jojo new` or `jojo generate`, the system checks if required input files:
1. **Exist** (hard requirement - exit with error if missing)
2. **Still contain the marker** (soft warning - allow to proceed but warn)

**Examples:**

```
# Missing file - BLOCK execution
✗ Error: inputs/generic_resume.md not found
  Run 'jojo setup' to create input files.

# Has marker - WARN but continue
⚠ Warning: inputs/generic_resume.md appears to be an unmodified template
  Generated materials may be poor quality until you customize it.

Continue anyway? (y/n)
```

### Files That Need Markers

- `inputs/generic_resume.md` (required, blocks if missing)
- `inputs/recommendations.md` (optional, warn if exists with marker)
- `inputs/projects.yml` (optional, warn if exists with marker)

## Conversational Flow

### Question Sequence

Setup asks questions in this order, skipping any where the file/config already exists:

#### 1. API Configuration (creates `.env`)

**If exists:**
```
Setting up Jojo...

✓ .env already exists (skipped)
```

**If missing:**
```
Setting up Jojo...

Let's configure your API access.
Anthropic API key: ████████████
✓ Created .env
```

#### 2. Personal Configuration (creates `config.yml`)

**If exists:**
```
✓ config.yml already exists (skipped)
```

**If missing:**
```
Your name: Tracy Atteberry
Your website base URL (e.g., https://yourname.com): https://tracyatteberry.com
✓ Created config.yml
```

#### 3. Input Files (creates `inputs/` directory and template files)

**Creating files:**
```
✓ inputs/ directory ready

Setting up your profile templates...
✓ Created inputs/generic_resume.md (customize this file)
✓ Created inputs/recommendations.md (optional - customize or delete)
✓ Created inputs/projects.yml (optional - customize or delete)
```

**If files already exist:**
```
✓ inputs/generic_resume.md already exists (skipped)
✓ inputs/recommendations.md already exists (skipped)
✓ inputs/projects.yml already exists (skipped)
```

#### 4. Summary

```
Setup complete!

Created:
  • .env - API configuration
  • config.yml - Personal preferences
  • inputs/generic_resume.md - Your work history template
  • inputs/recommendations.md - Optional recommendations
  • inputs/projects.yml - Optional portfolio projects

Next steps:
  1. Customize inputs/generic_resume.md with your actual experience
  2. Edit or delete inputs/recommendations.md and inputs/projects.yml if not needed
  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application

💡 Tip: Delete the first comment line in each file after customizing.
```

## Template File Content

### inputs/generic_resume.md

```markdown
<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line after customizing -->
# Generic Resume

This is your "master resume" containing ALL your experience, skills, and achievements.
Include everything - the tailoring process will select what's most relevant for each job.
It's better to have too much here than too little.

## Experience

### Senior Software Engineer | Acme Corporation | 2020-2023
- Led team of 5 engineers building cloud infrastructure platform
- Reduced deployment time by 70% through automation pipeline improvements
- Mentored junior developers and conducted code reviews
- Technologies: Python, AWS, Docker, Kubernetes

### Software Engineer | Tech Startup Inc | 2018-2020
- Built RESTful APIs serving 1M+ requests/day
- Implemented CI/CD pipeline reducing release cycle from weeks to days
- Technologies: Ruby on Rails, PostgreSQL, Redis

## Education

### B.S. Computer Science | State University | 2018
- GPA: 3.8/4.0
- Relevant coursework: Algorithms, Distributed Systems, Machine Learning

## Skills

**Languages**: Python, Ruby, JavaScript, Go, Java, C++, TypeScript
**Frameworks**: Rails, Django, React, Node.js, Express
**Technologies**: AWS, Docker, Kubernetes, PostgreSQL, Redis, MongoDB
**Practices**: Agile, TDD, CI/CD, Code Review, Pair Programming

## Projects

### Open Source Contributions
- Contributed to Kubernetes: implemented feature X
- Maintainer of popular Ruby gem with 10k downloads

**Tip: Include ALL skills and experience - the more complete this is, the better the tailored resumes.**
```

### inputs/recommendations.md

```markdown
<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line after customizing -->
# Recommendations

LinkedIn recommendations that will appear in a carousel on your website.
Delete this file if you don't want to include recommendations.

---

**John Smith, CTO at Acme Corp**

"Tracy is an exceptional engineer who consistently delivers high-quality work. Their ability to architect scalable systems while mentoring junior team members made them invaluable to our organization. I highly recommend Tracy for any senior engineering role."

---

**Jane Doe, Engineering Manager at Tech Startup**

"I had the pleasure of working with Tracy for two years. They have a rare combination of technical depth and communication skills. Tracy's work on our API infrastructure reduced latency by 50% and their documentation made it accessible to the entire team."

---

**Bob Johnson, Senior Engineer at BigCo**

"Tracy is one of the most skilled engineers I've worked with. Their code reviews were always thorough and educational, and they were always willing to help teammates solve difficult problems."
```

### inputs/projects.yml

```yaml
# JOJO_TEMPLATE_PLACEHOLDER - Delete this line after customizing
# Portfolio projects that can be highlighted on your website.
# Delete this file if you don't have projects to showcase.

projects:
  - name: CloudDeploy
    description: Open-source deployment automation tool
    url: https://github.com/yourname/clouddeploy
    technologies:
      - Go
      - Docker
      - Kubernetes
    highlights:
      - 5k+ GitHub stars
      - Used by 100+ companies in production
      - Featured in DevOps Weekly

  - name: DataPipeline
    description: Real-time data processing framework
    url: https://github.com/yourname/datapipeline
    technologies:
      - Python
      - Apache Kafka
      - Redis
    highlights:
      - Processes 1M+ events per second
      - 99.9% uptime over 2 years
      - Published paper at data engineering conference
```

## Error Handling & Edge Cases

### Handling Setup Failures

**Missing template files:**
```
✗ Error: Template file templates/generic_resume.md not found
  This may indicate a corrupted installation.
  Try: git pull or reinstall jojo
```

**Permission errors:**
```
✗ Error: Cannot create inputs/ directory (permission denied)
  Check directory permissions and try again
```

**Incomplete user input:**
```
Your name: [user presses enter with empty input]
✗ Name is required for config.yml
Your name: Tracy Atteberry
✓ Created config.yml
```

**Invalid API key format:**
```
Anthropic API key: invalid-key
⚠ Warning: This doesn't look like a valid Anthropic API key (should start with 'sk-ant-')
Continue anyway? (y/n)
```

### Partial Setup Recovery

If setup fails partway through:
- Running `jojo setup` again picks up where it left off
- Already-created files are detected and skipped
- No need to manually clean up or start over

### Force Flag Behavior

Add `--force` flag for complete reset:

```bash
jojo setup --force
```

```
⚠ WARNING: --force will overwrite existing configuration files!
  This will replace: .env, config.yml, and all inputs/ files
Continue? (y/n)
```

## Implementation Structure

### Code Organization

**lib/jojo/cli.rb**
```ruby
desc "setup", "Setup configuration"
method_option :force, type: :boolean, desc: 'Overwrite existing files'
def setup
  Jojo::SetupService.new(
    cli_instance: self,
    force: options[:force]
  ).run
end
```

**lib/jojo/setup_service.rb** (NEW)
```ruby
module Jojo
  class SetupService
    def initialize(cli_instance:, force: false)
      @cli = cli_instance
      @force = force
      @created_files = []
      @skipped_files = []
    end

    def run
      warn_if_force_mode
      setup_api_configuration
      setup_personal_configuration
      setup_input_files
      show_summary
    end

    private

    def setup_api_configuration
      # Create .env if missing or force mode
    end

    def setup_personal_configuration
      # Create config.yml if missing or force mode
    end

    def setup_input_files
      # Create inputs/ directory and template files
    end

    def show_summary
      # Display what was created/skipped and next steps
    end
  end
end
```

### Template File Updates

Update existing templates to add markers:
- `templates/generic_resume.md` - Add marker, expand examples
- `templates/recommendations.md` - Add marker
- `templates/projects.yml` - Add marker
- `templates/config.yml.erb` - Keep as-is (already templated)

### Validation Helper

**lib/jojo/template_validator.rb** (NEW)
```ruby
module Jojo
  class TemplateValidator
    MARKER = "JOJO_TEMPLATE_PLACEHOLDER"

    def self.appears_unchanged?(file_path)
      return false unless File.exist?(file_path)
      File.read(file_path).include?(MARKER)
    end

    def self.validate_inputs!(employer)
      # Check generic_resume.md exists (hard requirement)
      # Warn if any files have markers
    end
  end
end
```

## Integration Points

### Update Existing Commands

**jojo new** - Add validation before processing:
```ruby
def new
  Jojo::TemplateValidator.validate_inputs!(nil) # Check before creating employer
  # ... rest of command
end
```

**jojo generate** - Add validation before generation:
```ruby
def generate
  employer = Jojo::Employer.new(slug)
  Jojo::TemplateValidator.validate_inputs!(employer)
  # ... rest of command
end
```

### Update Documentation

- README.md - Update installation section to emphasize single `jojo setup` command
- Remove manual template copying instructions
- Add note about the marker line in templates

## Success Metrics

The improved setup is successful if:

1. **First-time users can complete setup in < 2 minutes** (down from ~5-10 minutes)
2. **Zero manual file copying required**
3. **Running setup multiple times is safe** (idempotent)
4. **Clear validation errors** guide users to fix issues
5. **Users understand what to do next** after setup completes

## Future Enhancements

Possible improvements for later:

1. **Setup wizard** - `jojo setup --interactive` with more guidance
2. **Import from LinkedIn** - Parse LinkedIn profile to pre-fill resume
3. **Example employer** - Create a sample application for learning
4. **Setup validation** - `jojo setup --verify` to check readiness
5. **Config migration** - Automatically update old config formats
