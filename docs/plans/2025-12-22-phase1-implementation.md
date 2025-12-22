# Phase 1: CLI Framework and Configuration - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build working CLI framework with setup command and configuration management

**Architecture:** Thor-based CLI with lazy-validated config, employer directory management, and rerunnable setup command that accumulates errors

**Tech Stack:** Ruby 3.4.5, Thor 1.3, ERB templates, Minitest

---

## Task 1: Employer Class - Slugification

**Files:**
- Create: `lib/jojo/employer.rb`
- Test: `test/employer_test.rb`

### Step 1: Write failing test for basic slugification

Create `test/employer_test.rb`:

```ruby
require_relative 'test_helper'
require_relative '../lib/jojo/employer'

class EmployerTest < Minitest::Test
  def test_slugifies_company_name_with_spaces
    employer = Jojo::Employer.new('Acme Corp')
    assert_equal 'acme-corp', employer.slug
  end
end
```

### Step 2: Run test to verify it fails

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: FAIL with "uninitialized constant Jojo::Employer"

### Step 3: Write minimal Employer class

Create `lib/jojo/employer.rb`:

```ruby
module Jojo
  class Employer
    attr_reader :name, :slug, :base_path

    def initialize(name)
      @name = name
      @slug = slugify(name)
      @base_path = File.join('employers', @slug)
    end

    private

    def slugify(text)
      text
        .downcase
        .gsub(/[^a-z0-9]+/, '-')
        .gsub(/^-|-$/, '')
    end
  end
end
```

### Step 4: Run test to verify it passes

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: PASS (1 test, 1 assertion, 0 failures)

### Step 5: Commit

```bash
git add lib/jojo/employer.rb test/employer_test.rb
git commit -m "feat: add Employer class with basic slugification"
```

---

## Task 2: Employer Class - Edge Case Slugification

**Files:**
- Modify: `lib/jojo/employer.rb`
- Modify: `test/employer_test.rb`

### Step 1: Write tests for edge cases

Add to `test/employer_test.rb`:

```ruby
def test_slugifies_special_characters
  employer = Jojo::Employer.new('AT&T Inc.')
  assert_equal 'at-t-inc', employer.slug
end

def test_slugifies_multiple_spaces
  employer = Jojo::Employer.new('Example  Company   LLC')
  assert_equal 'example-company-llc', employer.slug
end

def test_slugifies_leading_trailing_special_chars
  employer = Jojo::Employer.new('!Company!')
  assert_equal 'company', employer.slug
end
```

### Step 2: Run tests to verify they pass

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: PASS (4 tests, 4 assertions, 0 failures) - slugify implementation already handles these

### Step 3: Commit

```bash
git add test/employer_test.rb
git commit -m "test: add edge cases for employer slugification"
```

---

## Task 3: Employer Class - Path Accessors

**Files:**
- Modify: `lib/jojo/employer.rb`
- Modify: `test/employer_test.rb`

### Step 1: Write test for path accessors

Add to `test/employer_test.rb`:

```ruby
def test_provides_correct_file_paths
  employer = Jojo::Employer.new('Acme Corp')

  assert_equal 'employers/acme-corp', employer.base_path
  assert_equal 'employers/acme-corp/job_description.md', employer.job_description_path
  assert_equal 'employers/acme-corp/research.md', employer.research_path
  assert_equal 'employers/acme-corp/resume.md', employer.resume_path
  assert_equal 'employers/acme-corp/cover_letter.md', employer.cover_letter_path
  assert_equal 'employers/acme-corp/status_log.md', employer.status_log_path
  assert_equal 'employers/acme-corp/website', employer.website_path
  assert_equal 'employers/acme-corp/website/index.html', employer.index_html_path
end
```

### Step 2: Run test to verify it fails

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: FAIL with "undefined method `job_description_path'"

### Step 3: Add path accessor methods

Add to `lib/jojo/employer.rb` (after initialize):

```ruby
def job_description_path
  File.join(base_path, 'job_description.md')
end

def research_path
  File.join(base_path, 'research.md')
end

def resume_path
  File.join(base_path, 'resume.md')
end

def cover_letter_path
  File.join(base_path, 'cover_letter.md')
end

def status_log_path
  File.join(base_path, 'status_log.md')
end

def website_path
  File.join(base_path, 'website')
end

def index_html_path
  File.join(website_path, 'index.html')
end
```

### Step 4: Run test to verify it passes

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: PASS (5 tests, 12 assertions, 0 failures)

### Step 5: Commit

```bash
git add lib/jojo/employer.rb test/employer_test.rb
git commit -m "feat: add path accessor methods to Employer"
```

---

## Task 4: Employer Class - Directory Creation

**Files:**
- Modify: `lib/jojo/employer.rb`
- Modify: `test/employer_test.rb`

### Step 1: Write test for directory creation

Add to `test/employer_test.rb`:

```ruby
def test_creates_directory_structure
  employer = Jojo::Employer.new('Test Company')

  # Clean up before test
  FileUtils.rm_rf('employers/test-company') if Dir.exist?('employers/test-company')

  refute Dir.exist?('employers/test-company')
  refute Dir.exist?('employers/test-company/website')

  employer.create_directory!

  assert Dir.exist?('employers/test-company')
  assert Dir.exist?('employers/test-company/website')

  # Clean up after test
  FileUtils.rm_rf('employers/test-company')
end
```

### Step 2: Run test to verify it fails

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: FAIL with "undefined method `create_directory!'"

### Step 3: Add create_directory! method

Add to `lib/jojo/employer.rb` (after initialize):

```ruby
def create_directory!
  FileUtils.mkdir_p(base_path)
  FileUtils.mkdir_p(website_path)
end
```

### Step 4: Run test to verify it passes

Run: `ruby -Ilib:test test/employer_test.rb`

Expected: PASS (6 tests, 16 assertions, 0 failures)

### Step 5: Commit

```bash
git add lib/jojo/employer.rb test/employer_test.rb
git commit -m "feat: add directory creation to Employer"
```

---

## Task 5: Config Class - Basic Structure

**Files:**
- Create: `lib/jojo/config.rb`
- Create: `test/config_test.rb`
- Create: `test/fixtures/valid_config.yml`

### Step 1: Create test fixture

Create `test/fixtures/valid_config.yml`:

```yaml
seeker_name: Test User
reasoning_ai:
  service: anthropic
  model: sonnet
text_generation_ai:
  service: anthropic
  model: haiku
voice_and_tone: professional and friendly
```

### Step 2: Write failing test for loading config

Create `test/config_test.rb`:

```ruby
require_relative 'test_helper'
require_relative '../lib/jojo/config'

class ConfigTest < Minitest::Test
  def test_loads_seeker_name
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    assert_equal 'Test User', config.seeker_name
  end
end
```

### Step 3: Run test to verify it fails

Run: `ruby -Ilib:test test/config_test.rb`

Expected: FAIL with "uninitialized constant Jojo::Config"

### Step 4: Write minimal Config class

Create `lib/jojo/config.rb`:

```ruby
require 'yaml'

module Jojo
  class Config
    def initialize(config_path = 'config.yml')
      @config_path = config_path
      @config = nil
    end

    def seeker_name
      config['seeker_name']
    end

    private

    def config
      @config ||= load_config
    end

    def load_config
      unless File.exist?(@config_path)
        abort "Error: #{@config_path} not found. Run 'jojo setup' first."
      end

      YAML.load_file(@config_path)
    rescue => e
      abort "Error loading config: #{e.message}"
    end
  end
end
```

### Step 5: Run test to verify it passes

Run: `ruby -Ilib:test test/config_test.rb`

Expected: PASS (1 test, 1 assertion, 0 failures)

### Step 6: Commit

```bash
git add lib/jojo/config.rb test/config_test.rb test/fixtures/valid_config.yml
git commit -m "feat: add Config class with basic loading"
```

---

## Task 6: Config Class - AI Configuration Accessors

**Files:**
- Modify: `lib/jojo/config.rb`
- Modify: `test/config_test.rb`

### Step 1: Write tests for AI config accessors

Add to `test/config_test.rb`:

```ruby
def test_loads_reasoning_ai_config
  config = Jojo::Config.new('test/fixtures/valid_config.yml')
  assert_equal 'anthropic', config.reasoning_ai_service
  assert_equal 'sonnet', config.reasoning_ai_model
end

def test_loads_text_generation_ai_config
  config = Jojo::Config.new('test/fixtures/valid_config.yml')
  assert_equal 'anthropic', config.text_generation_ai_service
  assert_equal 'haiku', config.text_generation_ai_model
end

def test_loads_voice_and_tone
  config = Jojo::Config.new('test/fixtures/valid_config.yml')
  assert_equal 'professional and friendly', config.voice_and_tone
end
```

### Step 2: Run tests to verify they fail

Run: `ruby -Ilib:test test/config_test.rb`

Expected: FAIL with "undefined method `reasoning_ai_service'"

### Step 3: Add accessor methods with validation

Add to `lib/jojo/config.rb` (after seeker_name):

```ruby
def reasoning_ai_service
  validate_ai_config!('reasoning_ai')
  config['reasoning_ai']['service']
end

def reasoning_ai_model
  validate_ai_config!('reasoning_ai')
  config['reasoning_ai']['model']
end

def text_generation_ai_service
  validate_ai_config!('text_generation_ai')
  config['text_generation_ai']['service']
end

def text_generation_ai_model
  validate_ai_config!('text_generation_ai')
  config['text_generation_ai']['model']
end

def voice_and_tone
  config['voice_and_tone'] || 'professional and friendly'
end
```

Add to private section:

```ruby
def validate_ai_config!(key)
  unless config[key] && config[key]['service'] && config[key]['model']
    abort "Error: Invalid AI configuration for #{key} in config.yml"
  end
end
```

### Step 4: Run tests to verify they pass

Run: `ruby -Ilib:test test/config_test.rb`

Expected: PASS (4 tests, 6 assertions, 0 failures)

### Step 5: Commit

```bash
git add lib/jojo/config.rb test/config_test.rb
git commit -m "feat: add AI config accessors with validation"
```

---

## Task 7: Config Class - Error Handling

**Files:**
- Modify: `test/config_test.rb`
- Create: `test/fixtures/invalid_config.yml`

### Step 1: Create invalid config fixture

Create `test/fixtures/invalid_config.yml`:

```yaml
seeker_name: Test User
reasoning_ai:
  service: anthropic
  # missing model
```

### Step 2: Write test for missing config file

Add to `test/config_test.rb`:

```ruby
def test_aborts_when_config_file_missing
  assert_raises(SystemExit) do
    config = Jojo::Config.new('nonexistent.yml')
    config.seeker_name # trigger lazy load
  end
end
```

### Step 3: Write test for invalid AI config

Add to `test/config_test.rb`:

```ruby
def test_aborts_when_ai_config_invalid
  assert_raises(SystemExit) do
    config = Jojo::Config.new('test/fixtures/invalid_config.yml')
    config.reasoning_ai_model # trigger validation
  end
end
```

### Step 4: Run tests to verify they pass

Run: `ruby -Ilib:test test/config_test.rb`

Expected: PASS (6 tests, 8 assertions, 0 failures) - validation already implemented

### Step 5: Commit

```bash
git add test/config_test.rb test/fixtures/invalid_config.yml
git commit -m "test: add error handling tests for Config"
```

---

## Task 8: Template Files

**Files:**
- Create: `templates/config.yml.erb`
- Create: `templates/generic_resume.md`
- Create: `templates/recommendations.md`

### Step 1: Create config template

Create `templates/config.yml.erb`:

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

### Step 2: Create generic resume template

Create `templates/generic_resume.md`:

```markdown
# Your Name

## Contact Information
- Email: your.email@example.com
- Phone: (555) 123-4567
- LinkedIn: linkedin.com/in/yourprofile
- GitHub: github.com/yourprofile

## Professional Summary

[2-3 sentences describing your professional background and key strengths]

## Skills

### Technical Skills
- Programming Languages: Ruby, Python, JavaScript
- Frameworks: Rails, React, etc.
- Tools: Git, Docker, etc.

### Soft Skills
- Leadership
- Communication
- Problem-solving

## Work Experience

### Job Title | Company Name
*Start Date - End Date* | Location

- Achievement or responsibility (use action verbs)
- Quantifiable result when possible
- Technologies used in [brackets]

### Previous Job Title | Previous Company
*Start Date - End Date* | Location

- Achievement or responsibility
- Focus on impact and results
- Include relevant technologies

## Education

### Degree Name | University Name
*Graduation Year* | Location

- Relevant coursework or honors
- GPA if impressive (3.5+)

## Projects (Optional)

### Project Name
- Brief description of the project
- Technologies used
- Link to GitHub/demo if available

## Certifications (Optional)
- Certification Name, Issuing Organization, Year

---

**Instructions for use:**
1. Copy this file to `inputs/generic_resume.md`
2. Replace all placeholder text with your actual information
3. Remove sections that don't apply to you
4. Add sections as needed (Publications, Speaking, etc.)
5. Keep formatting consistent (markdown)
```

### Step 3: Create recommendations template

Create `templates/recommendations.md`:

```markdown
# LinkedIn Recommendations

These recommendations can be used to tailor your resume and cover letter with specific examples and endorsements.

---

## Recommendation from [Recommender Name]
**Their Title:** [Their Job Title]
**Your Role:** [Your Job Title when working together]
**Relationship:** [Manager, Colleague, Direct Report, Client, etc.]

> [Full text of their LinkedIn recommendation]

**Key Phrases to Use:**
- "[Notable skill or quality they mentioned]"
- "[Specific achievement they highlighted]"

---

## Recommendation from [Another Recommender]
**Their Title:** [Their Job Title]
**Your Role:** [Your Job Title]
**Relationship:** [Your relationship]

> [Full text of recommendation]

**Key Phrases to Use:**
- "[Skill or quality]"
- "[Achievement]"

---

**Instructions for use:**
1. Copy this file to `inputs/recommendations.md` (optional)
2. Go to your LinkedIn profile
3. Copy each recommendation verbatim
4. Note key phrases that would be good to reference
5. Use these when AI tailors your materials
```

### Step 4: Verify templates exist

Run: `ls -la templates/`

Expected: See config.yml.erb, generic_resume.md, recommendations.md

### Step 5: Commit

```bash
git add templates/
git commit -m "feat: add template files for config and examples"
```

---

## Task 9: CLI Class - Basic Structure

**Files:**
- Create: `lib/jojo/cli.rb`
- Modify: `lib/jojo.rb`

### Step 1: Update main jojo.rb to require CLI

Modify `lib/jojo.rb`:

```ruby
require 'thor'
require 'dotenv/load'

module Jojo
  VERSION = '0.1.0'
end

require_relative 'jojo/config'
require_relative 'jojo/employer'
require_relative 'jojo/cli'
```

### Step 2: Create basic CLI class

Create `lib/jojo/cli.rb`:

```ruby
require 'erb'
require 'fileutils'

module Jojo
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Run verbosely'
    class_option :employer, type: :string, aliases: '-e', desc: 'Employer name'
    class_option :job, type: :string, aliases: '-j', desc: 'Job description (file path or URL)'

    desc "version", "Show version"
    def version
      say "Jojo #{Jojo::VERSION}", :green
    end
  end
end
```

### Step 3: Test basic CLI

Run: `ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['version'])"`

Expected: "Jojo 0.1.0" in green

### Step 4: Commit

```bash
git add lib/jojo.rb lib/jojo/cli.rb
git commit -m "feat: add basic CLI class structure"
```

---

## Task 10: CLI - Setup Command (Part 1: Structure)

**Files:**
- Modify: `lib/jojo/cli.rb`

### Step 1: Add setup command skeleton

Add to `lib/jojo/cli.rb`:

```ruby
desc "setup", "Setup configuration"
def setup
  errors = []

  say "Setting up Jojo...", :green

  # Steps will be added in next tasks
  handle_config_yml(errors)
  handle_env_file(errors)
  ensure_inputs_directory

  report_results(errors)
end

private

def handle_config_yml(errors)
  # TODO: implement
end

def handle_env_file(errors)
  # TODO: implement
end

def ensure_inputs_directory
  # TODO: implement
end

def report_results(errors)
  if errors.any?
    say "\nSetup completed with errors:", :red
    errors.each { |e| say "  - #{e}", :red }
  end

  display_next_steps

  exit 1 if errors.any?
end

def display_next_steps
  say "\nNext steps:", :cyan
  say "1. Copy templates/generic_resume.md to inputs/generic_resume.md"
  say "2. Edit inputs/generic_resume.md with your actual work history"
  say "3. (Optional) Copy templates/recommendations.md to inputs/recommendations.md"
  say "4. Run 'jojo generate -e \"Company Name\" -j job_description.txt' to generate materials"
end
```

### Step 2: Test setup skeleton

Run: `ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['setup'])"`

Expected: Should run without errors, show "Setting up Jojo..." and next steps

### Step 3: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add setup command skeleton"
```

---

## Task 11: CLI - Setup Command (Part 2: Config YAML)

**Files:**
- Modify: `lib/jojo/cli.rb`

### Step 1: Implement handle_config_yml

Replace `handle_config_yml` in `lib/jojo/cli.rb`:

```ruby
def handle_config_yml(errors)
  if File.exist?('config.yml')
    if yes?("config.yml already exists. Overwrite?")
      create_config_yml(errors)
    else
      say "⊘ Skipped config.yml", :yellow
    end
  else
    create_config_yml(errors)
  end
end

def create_config_yml(errors)
  seeker_name = ask("Your name:")

  if seeker_name.strip.empty?
    errors << "Name is required for config.yml"
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

### Step 2: Test config.yml creation manually

Run: `rm -f config.yml && ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['setup'])"`

Enter name when prompted, then:

Run: `cat config.yml`

Expected: Should show config with your entered name

### Step 3: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: implement config.yml creation in setup"
```

---

## Task 12: CLI - Setup Command (Part 3: ENV File)

**Files:**
- Modify: `lib/jojo/cli.rb`

### Step 1: Implement handle_env_file

Replace `handle_env_file` in `lib/jojo/cli.rb`:

```ruby
def handle_env_file(errors)
  if File.exist?('.env')
    say "✓ .env already exists", :green
  else
    create_env_file(errors)
  end
end

def create_env_file(errors)
  api_key = ask("Anthropic API key:")

  if api_key.strip.empty?
    errors << "API key is required for .env"
    return
  end

  begin
    File.write('.env', "ANTHROPIC_API_KEY=#{api_key}\n")
    say "✓ Created .env", :green
  rescue => e
    errors << "Failed to create .env: #{e.message}"
  end
end
```

### Step 2: Implement ensure_inputs_directory

Replace `ensure_inputs_directory` in `lib/jojo/cli.rb`:

```ruby
def ensure_inputs_directory
  FileUtils.mkdir_p('inputs') unless Dir.exist?('inputs')
  say "✓ inputs/ directory ready", :green
end
```

### Step 3: Test full setup command manually

Run: `rm -f config.yml .env && ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['setup'])"`

Follow prompts, then verify:

Run: `ls -la config.yml .env inputs/`

Expected: All files/directories created

### Step 4: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: implement .env and inputs/ creation in setup"
```

---

## Task 13: CLI - Generate Command

**Files:**
- Modify: `lib/jojo/cli.rb`

### Step 1: Add generate command and validation

Add to `lib/jojo/cli.rb` (after setup method):

```ruby
desc "generate", "Generate everything: research, resume, cover letter, and website"
def generate
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])

  say "Generating application materials for #{employer.name}...", :green

  employer.create_directory!
  say "✓ Created directory: #{employer.base_path}", :green

  say "✓ Setup complete. Additional generation steps coming in future phases.", :yellow
end
```

Add to private section:

```ruby
def validate_generate_options!
  errors = []
  errors << "--employer is required" unless options[:employer]
  errors << "--job is required" unless options[:job]

  if errors.any?
    say "Error:", :red
    errors.each { |e| say "  #{e}", :red }
    exit 1
  end
end
```

### Step 2: Test generate command

Run: `ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['generate', '-e', 'Acme Corp', '-j', 'test.txt'])"`

Expected: Creates `employers/acme-corp/` directory and shows success messages

### Step 3: Test validation

Run: `ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['generate'])"`

Expected: Shows error messages about missing --employer and --job

### Step 4: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: implement generate command with validation"
```

---

## Task 14: CLI - Command Stubs

**Files:**
- Modify: `lib/jojo/cli.rb`

### Step 1: Add remaining command stubs

Add to `lib/jojo/cli.rb` (after generate method):

```ruby
desc "research", "Generate company/role research only"
def research
  validate_generate_options!
  say "Research generation coming in Phase 3", :yellow
end

desc "resume", "Generate tailored resume only"
def resume
  validate_generate_options!
  say "Resume generation coming in Phase 4", :yellow
end

desc "cover_letter", "Generate cover letter only"
def cover_letter
  validate_generate_options!
  say "Cover letter generation coming in Phase 5", :yellow
end

desc "website", "Generate website only"
def website
  validate_generate_options!
  say "Website generation coming in Phase 6", :yellow
end

desc "test", "Run tests"
def test
  exec "ruby -Ilib:test test/**/*_test.rb"
end
```

### Step 2: Test each command stub

Run: `ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['research', '-e', 'Acme', '-j', 'test.txt'])"`

Expected: "Research generation coming in Phase 3"

Run: `ruby -Ilib -e "require 'jojo'; Jojo::CLI.start(['resume', '-e', 'Acme', '-j', 'test.txt'])"`

Expected: "Resume generation coming in Phase 4"

Repeat for cover_letter and website.

### Step 3: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add command stubs for future phases"
```

---

## Task 15: Executable Wrapper

**Files:**
- Create: `bin/jojo`

### Step 1: Create executable wrapper

Create `bin/jojo`:

```ruby
#!/usr/bin/env ruby

require_relative '../lib/jojo'

Jojo::CLI.start(ARGV)
```

### Step 2: Make executable

Run: `chmod +x bin/jojo`

### Step 3: Test executable

Run: `./bin/jojo help`

Expected: Shows Thor help with all commands listed

Run: `./bin/jojo version`

Expected: "Jojo 0.1.0"

### Step 4: Commit

```bash
git add bin/jojo
git commit -m "feat: add executable wrapper script"
```

---

## Task 16: CLI Integration Tests

**Files:**
- Create: `test/cli_test.rb`

### Step 1: Create basic CLI tests

Create `test/cli_test.rb`:

```ruby
require_relative 'test_helper'
require_relative '../lib/jojo/cli'

class CLITest < Minitest::Test
  def test_cli_class_exists
    assert defined?(Jojo::CLI)
  end

  def test_cli_inherits_from_thor
    assert Jojo::CLI < Thor
  end

  def test_has_setup_command
    assert Jojo::CLI.commands.key?('setup')
  end

  def test_has_generate_command
    assert Jojo::CLI.commands.key?('generate')
  end

  def test_has_research_command
    assert Jojo::CLI.commands.key?('research')
  end

  def test_has_resume_command
    assert Jojo::CLI.commands.key?('resume')
  end

  def test_has_cover_letter_command
    assert Jojo::CLI.commands.key?('cover_letter')
  end

  def test_has_website_command
    assert Jojo::CLI.commands.key?('website')
  end

  def test_has_version_command
    assert Jojo::CLI.commands.key?('version')
  end

  def test_has_test_command
    assert Jojo::CLI.commands.key?('test')
  end
end
```

### Step 2: Run CLI tests

Run: `ruby -Ilib:test test/cli_test.rb`

Expected: PASS (10 tests, 10 assertions, 0 failures)

### Step 3: Commit

```bash
git add test/cli_test.rb
git commit -m "test: add CLI integration tests"
```

---

## Task 17: Run All Tests

**Files:**
- None (verification task)

### Step 1: Run all tests

Run: `ruby -Ilib:test test/**/*_test.rb`

Expected: All tests pass

Alternatively:

Run: `./bin/jojo test`

Expected: All tests pass

### Step 2: Verify test count

Expected output should show approximately:
- ConfigTest: 6 tests
- EmployerTest: 6 tests
- CLITest: 10 tests
- Total: ~22 tests, 0 failures

### Step 3: Fix any failing tests before proceeding

If any tests fail, debug and fix them.

---

## Task 18: End-to-End Validation

**Files:**
- Create: `test/fixtures/sample_job.txt` (for testing)

### Step 1: Create sample job description

Create `test/fixtures/sample_job.txt`:

```
Senior Ruby Developer

Acme Corp is seeking an experienced Ruby developer to join our team.

Requirements:
- 5+ years of Ruby experience
- Experience with Rails
- Strong communication skills

To apply, send resume and cover letter.
```

### Step 2: Test complete workflow

Run: `./bin/jojo help`

Expected: Shows all commands with descriptions

Run: `rm -f config.yml .env && ./bin/jojo setup`

Follow prompts with test data, verify config.yml and .env created

Run: `./bin/jojo generate -e "Acme Corp" -j test/fixtures/sample_job.txt`

Expected: Creates `employers/acme-corp/` directory structure

Run: `ls -la employers/acme-corp/`

Expected: Directory exists with `website/` subdirectory

### Step 3: Test rerunnable setup

Run: `./bin/jojo setup`

Choose "no" when asked to overwrite config.yml

Expected: Skips config.yml, verifies .env exists, completes successfully

### Step 4: Verify validation criteria

Check all Phase 1 validation criteria:
- ✅ `./bin/jojo help` shows all commands with descriptions
- ✅ `./bin/jojo setup` creates `config.yml` and `.env` interactively
- ✅ `./bin/jojo setup` is rerunnable (can skip existing files)
- ✅ `./bin/jojo generate -e "Acme Corp" -j test.txt` creates employer directory
- ✅ All tests pass: `ruby -Ilib:test test/**/*_test.rb`
- ✅ `bin/jojo` is executable

---

## Task 19: Update Implementation Plan

**Files:**
- Modify: `docs/plans/implementation_plan.md`

### Step 1: Update implementation plan

In `docs/plans/implementation_plan.md`, update Phase 1 section:

1. Change heading from `## Phase 1: CLI Framework and Configuration` to `## Phase 1: CLI Framework and Configuration ✅`
2. Add `**Status**: COMPLETED` below the **Goal** line
3. Mark all tasks with `[x]` instead of `[ ]`
4. Update validation line to: `**Validation**: ✅ All criteria met, tests passing`

### Step 2: Commit implementation plan update

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 1 as completed in implementation plan"
```

---

## Task 20: Final Commit and Summary

**Files:**
- None (final verification)

### Step 1: Review git log

Run: `git log --oneline -20`

Expected: Should see all commits from Phase 1 implementation

### Step 2: Run final test suite

Run: `./bin/jojo test`

Expected: All tests pass

### Step 3: Create Phase 1 completion commit

```bash
git commit --allow-empty -m "feat: complete Phase 1 - CLI framework and configuration

Phase 1 deliverables:
- Thor-based CLI with all command structure
- Config class with lazy validation
- Employer class with slugification and path management
- Working setup command (rerunnable, error accumulation)
- Generate command (creates directory structure)
- Command stubs for future phases
- Template files for config and examples
- Comprehensive test suite (22+ tests passing)
- Executable wrapper script

Validation criteria met:
✅ bin/jojo help shows all commands
✅ bin/jojo setup creates config and .env
✅ setup is rerunnable
✅ generate creates employer directories
✅ All tests passing
✅ bin/jojo is executable

Ready for Phase 2: Job Description Processing"
```

---

## Notes

- Each task is designed to take 2-5 minutes
- Follow TDD: test first, minimal implementation, then commit
- If any step fails, debug before proceeding
- Keep commits small and atomic
- Run tests frequently to catch issues early
- The `setup` command will be interactive - test it manually as automated testing of interactive commands is complex

## Success Criteria

Phase 1 is complete when:

1. All 22+ tests pass
2. `./bin/jojo help` displays all commands
3. `./bin/jojo setup` successfully creates config.yml and .env
4. `./bin/jojo generate -e "Company" -j file.txt` creates directory structure
5. All code is committed with conventional commit messages
6. Implementation plan is updated with completion status
