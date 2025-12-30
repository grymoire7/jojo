# Improved Setup Process Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Streamline jojo setup into a single intelligent command that detects existing configuration and validates input files

**Architecture:** Extract setup logic into a dedicated SetupService class, create TemplateValidator for checking placeholder markers, update CLI to use new service, and integrate validation into generation commands

**Tech Stack:** Ruby 3.4.5, Thor (CLI), Minitest (testing), ERB (templates)

---

## Phase 1: Template Validator Foundation

### Task 1: Create TemplateValidator Class

**Files:**
- Create: `lib/jojo/template_validator.rb`
- Test: `test/unit/template_validator_test.rb`

**Step 1: Write failing test for marker detection**

Create test file:
```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/template_validator'

describe Jojo::TemplateValidator do
  describe '.appears_unchanged?' do
    it 'returns false when file does not exist' do
      result = Jojo::TemplateValidator.appears_unchanged?('nonexistent.md')
      _(result).must_equal false
    end

    it 'returns true when file contains marker' do
      file = Tempfile.new(['test', '.md'])
      file.write("<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line -->\nContent")
      file.close

      result = Jojo::TemplateValidator.appears_unchanged?(file.path)
      _(result).must_equal true

      file.unlink
    end

    it 'returns false when file does not contain marker' do
      file = Tempfile.new(['test', '.md'])
      file.write("# My Resume\nCustomized content")
      file.close

      result = Jojo::TemplateValidator.appears_unchanged?(file.path)
      _(result).must_equal false

      file.unlink
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/template_validator_test.rb`

Expected: Error about uninitialized constant or missing file

**Step 3: Create minimal TemplateValidator**

```ruby
module Jojo
  class TemplateValidator
    MARKER = "JOJO_TEMPLATE_PLACEHOLDER"

    def self.appears_unchanged?(file_path)
      return false unless File.exist?(file_path)
      File.read(file_path).include?(MARKER)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/template_validator_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/template_validator.rb test/unit/template_validator_test.rb
git commit -m "feat: add TemplateValidator for detecting unchanged templates"
```

---

### Task 2: Add Validation Logic with User Prompts

**Files:**
- Modify: `lib/jojo/template_validator.rb`
- Modify: `test/unit/template_validator_test.rb`

**Step 1: Write failing test for validate_required_file!**

Add to test file:
```ruby
describe '.validate_required_file!' do
  it 'raises error when required file is missing' do
    err = assert_raises(Jojo::TemplateValidator::MissingInputError) do
      Jojo::TemplateValidator.validate_required_file!('inputs/nonexistent.md', 'generic resume')
    end
    _(err.message).must_include 'inputs/nonexistent.md not found'
    _(err.message).must_include 'jojo setup'
  end

  it 'does not raise when file exists without marker' do
    file = Tempfile.new(['test', '.md'])
    file.write("# Customized Resume")
    file.close

    Jojo::TemplateValidator.validate_required_file!(file.path, 'resume')

    file.unlink
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/template_validator_test.rb`

Expected: Error about undefined method or constant

**Step 3: Implement validate_required_file!**

Update `lib/jojo/template_validator.rb`:
```ruby
module Jojo
  class TemplateValidator
    MARKER = "JOJO_TEMPLATE_PLACEHOLDER"

    class MissingInputError < StandardError; end
    class UnchangedTemplateError < StandardError; end

    def self.appears_unchanged?(file_path)
      return false unless File.exist?(file_path)
      File.read(file_path).include?(MARKER)
    end

    def self.validate_required_file!(file_path, description)
      unless File.exist?(file_path)
        raise MissingInputError, <<~MSG
          ✗ Error: #{file_path} not found
            Run 'jojo setup' to create input files.
        MSG
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/template_validator_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/template_validator.rb test/unit/template_validator_test.rb
git commit -m "feat: add validate_required_file! to check for missing inputs"
```

---

### Task 3: Add Interactive Warning for Unchanged Templates

**Files:**
- Modify: `lib/jojo/template_validator.rb`
- Modify: `test/unit/template_validator_test.rb`

**Step 1: Write test for warn_if_unchanged**

Add to test file:
```ruby
describe '.warn_if_unchanged' do
  it 'returns :continue when file does not contain marker' do
    file = Tempfile.new(['test', '.md'])
    file.write("# Customized Resume")
    file.close

    result = Jojo::TemplateValidator.warn_if_unchanged(file.path, 'resume')
    _(result).must_equal :continue

    file.unlink
  end

  it 'returns :skip when file does not exist' do
    result = Jojo::TemplateValidator.warn_if_unchanged('nonexistent.md', 'resume')
    _(result).must_equal :skip
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/template_validator_test.rb`

Expected: Error about undefined method

**Step 3: Implement warn_if_unchanged**

Update `lib/jojo/template_validator.rb`:
```ruby
def self.warn_if_unchanged(file_path, description, cli_instance: nil)
  return :skip unless File.exist?(file_path)
  return :continue unless appears_unchanged?(file_path)

  # If no CLI instance provided (testing), return action
  return :needs_warning unless cli_instance

  # Display warning message
  cli_instance.say "⚠ Warning: #{file_path} appears to be an unmodified template", :yellow
  cli_instance.say "  Generated materials may be poor quality until you customize it.", :yellow
  cli_instance.say ""

  # Ask user if they want to continue
  if cli_instance.yes?("Continue anyway?")
    :continue
  else
    :abort
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/template_validator_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/template_validator.rb test/unit/template_validator_test.rb
git commit -m "feat: add warn_if_unchanged for interactive template validation"
```

---

## Phase 2: Setup Service Implementation

### Task 4: Create SetupService Skeleton

**Files:**
- Create: `lib/jojo/setup_service.rb`
- Test: `test/unit/setup_service_test.rb`

**Step 1: Write failing test for SetupService initialization**

Create test file:
```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/setup_service'
require 'thor'

describe Jojo::SetupService do
  before do
    @cli = Minitest::Mock.new
  end

  describe '#initialize' do
    it 'stores cli_instance and force flag' do
      service = Jojo::SetupService.new(cli_instance: @cli, force: true)
      _(service.instance_variable_get(:@cli)).must_equal @cli
      _(service.instance_variable_get(:@force)).must_equal true
    end

    it 'defaults force to false' do
      service = Jojo::SetupService.new(cli_instance: @cli)
      _(service.instance_variable_get(:@force)).must_equal false
    end

    it 'initializes tracking arrays' do
      service = Jojo::SetupService.new(cli_instance: @cli)
      _(service.instance_variable_get(:@created_files)).must_equal []
      _(service.instance_variable_get(:@skipped_files)).must_equal []
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Error about missing file or constant

**Step 3: Create minimal SetupService**

```ruby
require 'fileutils'
require 'erb'

module Jojo
  class SetupService
    def initialize(cli_instance:, force: false)
      @cli = cli_instance
      @force = force
      @created_files = []
      @skipped_files = []
    end

    def run
      # To be implemented
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add SetupService skeleton with initialization"
```

---

### Task 5: Implement API Configuration Setup

**Files:**
- Modify: `lib/jojo/setup_service.rb`
- Modify: `test/unit/setup_service_test.rb`

**Step 1: Write test for setup_api_configuration**

Add to test file:
```ruby
describe '#setup_api_configuration' do
  it 'skips when .env exists and not force mode' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('.env', 'ANTHROPIC_API_KEY=existing')

        @cli.expect :say, nil, ["✓ .env already exists (skipped)", :green]

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_api_configuration)

        @cli.verify
        _(File.read('.env')).must_equal 'ANTHROPIC_API_KEY=existing'
      end
    end
  end

  it 'creates .env when missing' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        @cli.expect :say, nil, ["Setting up Jojo...", :green]
        @cli.expect :say, nil, [String, :green]
        @cli.expect :ask, 'sk-ant-test-key', ["Anthropic API key:"]
        @cli.expect :say, nil, ["✓ Created .env", :green]

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_api_configuration)

        @cli.verify
        _(File.exist?('.env')).must_equal true
        _(File.read('.env')).must_include 'ANTHROPIC_API_KEY=sk-ant-test-key'
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Error about undefined method setup_api_configuration

**Step 3: Implement setup_api_configuration**

Update `lib/jojo/setup_service.rb`:
```ruby
def run
  @cli.say "Setting up Jojo...", :green
  @cli.say ""

  setup_api_configuration
  setup_personal_configuration
  setup_input_files
  show_summary
end

private

def setup_api_configuration
  if File.exist?('.env') && !@force
    @cli.say "✓ .env already exists (skipped)", :green
    @skipped_files << '.env'
    return
  end

  if @force && File.exist?('.env')
    @cli.say "⚠ Recreating .env (--force mode)", :yellow
  else
    @cli.say "Let's configure your API access.", :green
  end

  api_key = @cli.ask("Anthropic API key:")

  if api_key.strip.empty?
    @cli.say "✗ API key is required", :red
    exit 1
  end

  # Optional: Validate API key format
  if !api_key.start_with?('sk-ant-')
    @cli.say "⚠ Warning: This doesn't look like a valid Anthropic API key (should start with 'sk-ant-')", :yellow
    unless @cli.yes?("Continue anyway?")
      exit 1
    end
  end

  File.write('.env', "ANTHROPIC_API_KEY=#{api_key}\n")
  @cli.say "✓ Created .env", :green
  @created_files << '.env'
end

def setup_personal_configuration
  # Placeholder
end

def setup_input_files
  # Placeholder
end

def show_summary
  # Placeholder
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: implement API configuration setup in SetupService"
```

---

### Task 6: Implement Personal Configuration Setup

**Files:**
- Modify: `lib/jojo/setup_service.rb`
- Modify: `test/unit/setup_service_test.rb`

**Step 1: Write test for setup_personal_configuration**

Add to test file:
```ruby
describe '#setup_personal_configuration' do
  it 'skips when config.yml exists and not force mode' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('config.yml', 'seeker_name: Existing')

        @cli.expect :say, nil, ["✓ config.yml already exists (skipped)", :green]

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_personal_configuration)

        @cli.verify
      end
    end
  end

  it 'creates config.yml from template when missing' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('templates')
        File.write('templates/config.yml.erb', 'seeker_name: <%= seeker_name %>')

        @cli.expect :ask, 'Tracy Atteberry', ["Your name:"]
        @cli.expect :ask, 'https://example.com', ["Your website base URL (e.g., https://yourname.com):"]
        @cli.expect :say, nil, ["✓ Created config.yml", :green]

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_personal_configuration)

        @cli.verify
        _(File.exist?('config.yml')).must_equal true
        _(File.read('config.yml')).must_include 'Tracy Atteberry'
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Test fails

**Step 3: Implement setup_personal_configuration**

Update `lib/jojo/setup_service.rb`:
```ruby
def setup_personal_configuration
  if File.exist?('config.yml') && !@force
    @cli.say "✓ config.yml already exists (skipped)", :green
    @skipped_files << 'config.yml'
    return
  end

  seeker_name = @cli.ask("Your name:")
  if seeker_name.strip.empty?
    @cli.say "✗ Name is required", :red
    exit 1
  end

  base_url = @cli.ask("Your website base URL (e.g., https://yourname.com):")
  if base_url.strip.empty?
    @cli.say "✗ Base URL is required", :red
    exit 1
  end

  begin
    template = ERB.new(File.read('templates/config.yml.erb'))
    File.write('config.yml', template.result(binding))
    @cli.say "✓ Created config.yml", :green
    @created_files << 'config.yml'
  rescue => e
    @cli.say "✗ Failed to create config.yml: #{e.message}", :red
    exit 1
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: implement personal configuration setup in SetupService"
```

---

### Task 7: Implement Input Files Setup

**Files:**
- Modify: `lib/jojo/setup_service.rb`
- Modify: `test/unit/setup_service_test.rb`

**Step 1: Write test for setup_input_files**

Add to test file:
```ruby
describe '#setup_input_files' do
  it 'creates inputs directory if missing' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('templates')
        File.write('templates/generic_resume.md', '<!-- JOJO_TEMPLATE_PLACEHOLDER -->')
        File.write('templates/recommendations.md', '<!-- JOJO_TEMPLATE_PLACEHOLDER -->')
        File.write('templates/projects.yml', '# JOJO_TEMPLATE_PLACEHOLDER')

        @cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        @cli.expect :say, nil, [String, :green]
        3.times { @cli.expect :say, nil, [String, :green] }

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_input_files)

        @cli.verify
        _(Dir.exist?('inputs')).must_equal true
      end
    end
  end

  it 'copies template files to inputs/' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('templates')
        File.write('templates/generic_resume.md', '<!-- JOJO_TEMPLATE_PLACEHOLDER -->\nResume content')
        File.write('templates/recommendations.md', '<!-- JOJO_TEMPLATE_PLACEHOLDER -->\nRecs')
        File.write('templates/projects.yml', '# JOJO_TEMPLATE_PLACEHOLDER\nprojects: []')

        @cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        @cli.expect :say, nil, [String, :green]
        @cli.expect :say, nil, ["✓ Created inputs/generic_resume.md (customize this file)", :green]
        @cli.expect :say, nil, ["✓ Created inputs/recommendations.md (optional - customize or delete)", :green]
        @cli.expect :say, nil, ["✓ Created inputs/projects.yml (optional - customize or delete)", :green]

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_input_files)

        @cli.verify
        _(File.exist?('inputs/generic_resume.md')).must_equal true
        _(File.read('inputs/generic_resume.md')).must_include 'JOJO_TEMPLATE_PLACEHOLDER'
      end
    end
  end

  it 'skips existing files unless force mode' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('inputs')
        FileUtils.mkdir_p('templates')
        File.write('inputs/generic_resume.md', 'Existing resume')
        File.write('templates/generic_resume.md', 'Template')
        File.write('templates/recommendations.md', 'Recs')
        File.write('templates/projects.yml', 'Projects')

        @cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        @cli.expect :say, nil, [String, :green]
        @cli.expect :say, nil, ["✓ inputs/generic_resume.md already exists (skipped)", :green]
        @cli.expect :say, nil, ["✓ Created inputs/recommendations.md (optional - customize or delete)", :green]
        @cli.expect :say, nil, ["✓ Created inputs/projects.yml (optional - customize or delete)", :green]

        service = Jojo::SetupService.new(cli_instance: @cli, force: false)
        service.send(:setup_input_files)

        @cli.verify
        _(File.read('inputs/generic_resume.md')).must_equal 'Existing resume'
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Test fails

**Step 3: Implement setup_input_files**

Update `lib/jojo/setup_service.rb`:
```ruby
def setup_input_files
  FileUtils.mkdir_p('inputs') unless Dir.exist?('inputs')
  @cli.say "✓ inputs/ directory ready", :green
  @cli.say ""
  @cli.say "Setting up your profile templates...", :green

  input_files = {
    'generic_resume.md' => '(customize this file)',
    'recommendations.md' => '(optional - customize or delete)',
    'projects.yml' => '(optional - customize or delete)'
  }

  input_files.each do |filename, description|
    target_path = File.join('inputs', filename)
    source_path = File.join('templates', filename)

    if File.exist?(target_path) && !@force
      @cli.say "✓ inputs/#{filename} already exists (skipped)", :green
      @skipped_files << "inputs/#{filename}"
      next
    end

    unless File.exist?(source_path)
      @cli.say "✗ Template file #{source_path} not found", :red
      @cli.say "  This may indicate a corrupted installation.", :yellow
      exit 1
    end

    FileUtils.cp(source_path, target_path)
    @cli.say "✓ Created inputs/#{filename} #{description}", :green
    @created_files << "inputs/#{filename}"
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: implement input files setup with template copying"
```

---

### Task 8: Implement Summary Display

**Files:**
- Modify: `lib/jojo/setup_service.rb`
- Modify: `test/unit/setup_service_test.rb`

**Step 1: Write test for show_summary**

Add to test file:
```ruby
describe '#show_summary' do
  it 'displays created files and next steps' do
    service = Jojo::SetupService.new(cli_instance: @cli)
    service.instance_variable_set(:@created_files, ['.env', 'config.yml', 'inputs/generic_resume.md'])

    @cli.expect :say, nil, [String, :green]
    @cli.expect :say, nil, [String, :green]
    3.times { @cli.expect :say, nil, [String] }
    @cli.expect :say, nil, [String, :cyan]
    5.times { @cli.expect :say, nil, [String] }

    service.send(:show_summary)

    @cli.verify
  end

  it 'shows appropriate message when no files created' do
    service = Jojo::SetupService.new(cli_instance: @cli)
    service.instance_variable_set(:@created_files, [])
    service.instance_variable_set(:@skipped_files, ['.env', 'config.yml'])

    @cli.expect :say, nil, [String, :green]
    @cli.expect :say, nil, [String, :green]
    @cli.expect :say, nil, [String, :cyan]
    3.times { @cli.expect :say, nil, [String] }

    service.send(:show_summary)

    @cli.verify
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Test fails or passes trivially (needs implementation)

**Step 3: Implement show_summary**

Update `lib/jojo/setup_service.rb`:
```ruby
def show_summary
  @cli.say ""
  @cli.say "Setup complete!", :green
  @cli.say ""

  if @created_files.any?
    @cli.say "Created:"
    file_descriptions = {
      '.env' => 'API configuration',
      'config.yml' => 'Personal preferences',
      'inputs/generic_resume.md' => 'Your work history template',
      'inputs/recommendations.md' => 'Optional recommendations',
      'inputs/projects.yml' => 'Optional portfolio projects'
    }

    @created_files.each do |file|
      desc = file_descriptions[file] || 'Configuration file'
      @cli.say "  • #{file} - #{desc}"
    end
    @cli.say ""
  end

  @cli.say "Next steps:", :cyan
  @cli.say "  1. Customize inputs/generic_resume.md with your actual experience"
  @cli.say "  2. Edit or delete inputs/recommendations.md and inputs/projects.yml if not needed"
  @cli.say "  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"
  @cli.say ""
  @cli.say "💡 Tip: Delete the first comment line in each file after customizing."
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: implement summary display with created files and next steps"
```

---

### Task 9: Add Force Mode Warning

**Files:**
- Modify: `lib/jojo/setup_service.rb`
- Modify: `test/unit/setup_service_test.rb`

**Step 1: Write test for force mode warning**

Add to test file:
```ruby
describe '#warn_if_force_mode' do
  it 'prompts for confirmation in force mode' do
    @cli.expect :say, nil, [String, :yellow]
    @cli.expect :say, nil, [String, :yellow]
    @cli.expect :yes?, true, ["Continue?"]

    service = Jojo::SetupService.new(cli_instance: @cli, force: true)
    service.send(:warn_if_force_mode)

    @cli.verify
  end

  it 'exits when user declines force mode' do
    @cli.expect :say, nil, [String, :yellow]
    @cli.expect :say, nil, [String, :yellow]
    @cli.expect :yes?, false, ["Continue?"]

    service = Jojo::SetupService.new(cli_instance: @cli, force: true)

    assert_raises(SystemExit) do
      service.send(:warn_if_force_mode)
    end
  end

  it 'does nothing when not in force mode' do
    service = Jojo::SetupService.new(cli_instance: @cli, force: false)
    service.send(:warn_if_force_mode)
    # No expectations, should complete without errors
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: Test fails

**Step 3: Implement warn_if_force_mode**

Update `lib/jojo/setup_service.rb`:
```ruby
def run
  @cli.say "Setting up Jojo...", :green
  @cli.say ""

  warn_if_force_mode
  setup_api_configuration
  setup_personal_configuration
  setup_input_files
  show_summary
end

private

def warn_if_force_mode
  return unless @force

  @cli.say "⚠ WARNING: --force will overwrite existing configuration files!", :yellow
  @cli.say "  This will replace: .env, config.yml, and all inputs/ files", :yellow

  unless @cli.yes?("Continue?")
    exit 1
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/setup_service_test.rb`

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add force mode warning with user confirmation"
```

---

## Phase 3: CLI Integration

### Task 10: Update CLI Setup Command

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Update require statements**

At the top of `lib/jojo/cli.rb`, add:
```ruby
require_relative 'setup_service'
```

**Step 2: Replace setup command implementation**

Replace the existing `setup` method (around line 29-41) with:
```ruby
desc "setup", "Setup configuration"
method_option :force, type: :boolean, desc: 'Overwrite existing files'
def setup
  Jojo::SetupService.new(
    cli_instance: self,
    force: options[:force]
  ).run
rescue SystemExit
  # Allow clean exit from service
  raise
rescue => e
  say "✗ Setup failed: #{e.message}", :red
  exit 1
end
```

**Step 3: Remove old setup helper methods**

Remove these methods from `lib/jojo/cli.rb`:
- `handle_config_yml` (around line 576-600)
- `handle_env_file` (around line 602-608)
- `create_env_file` (around line 610-624)
- `ensure_inputs_directory` (around line 626-629)
- `report_results` (around line 631-640)
- `display_next_steps` (around line 642-650)

**Step 4: Test setup command manually**

Run: `./bin/jojo setup --help`

Expected: Shows help with --force option

**Step 5: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "refactor: replace setup command with SetupService"
```

---

## Phase 4: Template File Updates

### Task 11: Update Generic Resume Template

**Files:**
- Modify: `templates/generic_resume.md`

**Step 1: Backup existing template**

Run: `cp templates/generic_resume.md templates/generic_resume.md.bak`

**Step 2: Update generic_resume.md**

Replace content with the design from design doc:
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

**Step 3: Remove backup**

Run: `rm templates/generic_resume.md.bak`

**Step 4: Commit**

```bash
git add templates/generic_resume.md
git commit -m "feat: update generic_resume.md template with marker and examples"
```

---

### Task 12: Update Recommendations Template

**Files:**
- Modify: `templates/recommendations.md`

**Step 1: Update recommendations.md**

Replace content with:
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

**Step 2: Commit**

```bash
git add templates/recommendations.md
git commit -m "feat: update recommendations.md template with marker and examples"
```

---

### Task 13: Update Projects Template

**Files:**
- Modify: `templates/projects.yml`

**Step 1: Update projects.yml**

Replace content with:
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

**Step 2: Commit**

```bash
git add templates/projects.yml
git commit -m "feat: update projects.yml template with marker and examples"
```

---

## Phase 5: Validation Integration

### Task 14: Add Validation to 'new' Command

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Add require for TemplateValidator**

At top of file, add:
```ruby
require_relative 'template_validator'
```

**Step 2: Add validation to new command**

Update the `new` method (around line 55) to add validation at the start:
```ruby
def new
  # Validate required inputs exist before creating employer
  begin
    Jojo::TemplateValidator.validate_required_file!(
      'inputs/generic_resume.md',
      'generic resume'
    )
  rescue Jojo::TemplateValidator::MissingInputError => e
    say e.message, :red
    exit 1
  end

  # Warn if generic resume hasn't been customized
  result = Jojo::TemplateValidator.warn_if_unchanged(
    'inputs/generic_resume.md',
    'generic resume',
    cli_instance: self
  )

  if result == :abort
    say "Setup your inputs first, then run this command again.", :yellow
    exit 1
  end

  config = Jojo::Config.new
  # ... rest of existing method
end
```

**Step 3: Test manually**

Run: `./bin/jojo new -s test-employer -j test.txt` (without inputs/)

Expected: Error message about missing inputs/generic_resume.md

**Step 4: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add template validation to 'new' command"
```

---

### Task 15: Add Validation to 'generate' Command

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Add validation to generate command**

Update the `generate` method (around line 124) to add validation after slug resolution:
```ruby
def generate
  slug = resolve_slug
  employer = Jojo::Employer.new(slug)

  unless employer.artifacts_exist?
    say "✗ Employer '#{slug}' not found.", :red
    say "  Run 'jojo new -s #{slug} -j JOB_DESCRIPTION' to create it.", :yellow
    exit 1
  end

  # Validate required inputs
  begin
    Jojo::TemplateValidator.validate_required_file!(
      'inputs/generic_resume.md',
      'generic resume'
    )
  rescue Jojo::TemplateValidator::MissingInputError => e
    say e.message, :red
    exit 1
  end

  # Warn about unchanged templates
  ['inputs/generic_resume.md', 'inputs/recommendations.md', 'inputs/projects.yml'].each do |file|
    next unless File.exist?(file)

    result = Jojo::TemplateValidator.warn_if_unchanged(
      file,
      File.basename(file),
      cli_instance: self
    )

    if result == :abort
      say "Customize your templates first, then run this command again.", :yellow
      exit 1
    end
  end

  config = Jojo::Config.new
  # ... rest of existing method
end
```

**Step 2: Test manually**

Create test setup, then run generate with unchanged template

**Step 3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add template validation to 'generate' command"
```

---

## Phase 6: Documentation Updates

### Task 16: Update README Installation Section

**Files:**
- Modify: `README.md`

**Step 1: Update Installation section**

Replace lines 72-96 (Installation section) with:
```markdown
## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/grymoire7/jojo.git
   cd jojo
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Run setup (creates .env, config.yml, and input templates):
   ```bash
   ./bin/jojo setup
   ```

   This will guide you through:
   - Setting up your Anthropic API key
   - Configuring your personal information
   - Creating input file templates

**Note**: The setup command is idempotent - you can run it multiple times safely. It only creates missing files.
```

**Step 2: Update Configuration section**

Update lines 98-177 (Configuration section) to remove manual file copying instructions:
```markdown
## Configuration

### Environment Variables

The setup command creates `.env` with your API key. You can edit it directly if needed:

```bash
ANTHROPIC_API_KEY=your_api_key_here
SERPER_API_KEY=your_serper_key_here  # Optional, for web search
```

### User Configuration

After running `./bin/jojo setup`, you can edit `config.yml` to customize:

```yaml
seeker_name: Your Name
base_url: https://yourwebsite.com/applications

reasoning_ai:
  service: anthropic
  model: sonnet        # or opus for higher quality

text_generation_ai:
  service: anthropic
  model: haiku         # faster for simple tasks

voice_and_tone: professional and friendly

website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

### Input Files

The setup command creates these files in `inputs/` with example content:

1. **`inputs/generic_resume.md`** (required) - Your complete work history
   - Contains examples you should replace with your actual experience
   - Include ALL your skills and experience - tailoring will select what's relevant
   - **Delete the first comment line after customizing**

2. **`inputs/recommendations.md`** (optional) - LinkedIn recommendations
   - Used in website carousel
   - Delete file if you don't want recommendations

3. **`inputs/projects.yml`** (optional) - Portfolio projects
   - Used for project selection and highlighting
   - Delete file if you don't have projects to showcase

**Important**: The first line of each template file contains a marker comment. Delete this line after you customize the file - jojo will warn you if templates are unchanged.
```

**Step 3: Update Quick Start section**

Replace lines 148-178 (Quick Start - Step 0) with:
```markdown
## Quick start

### Step 0: Run setup

If you haven't already, run setup to create your configuration and input files:

```bash
./bin/jojo setup
```

Then customize your input files:

1. **Edit your generic resume**:
   ```bash
   nvim inputs/generic_resume.md  # or your preferred editor
   ```
   Replace the example content with your actual experience, skills, and achievements.
   **Delete the first comment line** (`<!-- JOJO_TEMPLATE_PLACEHOLDER -->`) when done.

2. **(Optional) Customize or delete recommendations**:
   ```bash
   nvim inputs/recommendations.md
   # Or delete: rm inputs/recommendations.md
   ```

3. **(Optional) Customize or delete projects**:
   ```bash
   nvim inputs/projects.yml
   # Or delete: rm inputs/projects.yml
   ```

**Note**: The `inputs/` directory is gitignored, so your personal information stays private.
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: update README for improved setup process"
```

---

## Phase 7: Integration Testing

### Task 17: Create End-to-End Setup Test

**Files:**
- Create: `test/integration/setup_integration_test.rb`

**Step 1: Write integration test**

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/cli'
require 'fileutils'

describe 'Setup Integration' do
  it 'creates all files on first run' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Copy templates directory
        FileUtils.cp_r(File.join(__dir__, '../../templates'), '.')

        # Simulate user input
        input = StringIO.new("sk-ant-test-key\nTest User\nhttps://example.com\n")
        cli = Jojo::CLI.new

        # Mock STDIN
        original_stdin = $stdin
        $stdin = input

        begin
          cli.invoke(:setup, [], {})

          # Verify files created
          _(File.exist?('.env')).must_equal true
          _(File.exist?('config.yml')).must_equal true
          _(File.exist?('inputs/generic_resume.md')).must_equal true
          _(File.exist?('inputs/recommendations.md')).must_equal true
          _(File.exist?('inputs/projects.yml')).must_equal true

          # Verify content
          _(File.read('.env')).must_include 'sk-ant-test-key'
          _(File.read('config.yml')).must_include 'Test User'
          _(File.read('inputs/generic_resume.md')).must_include 'JOJO_TEMPLATE_PLACEHOLDER'
        ensure
          $stdin = original_stdin
        end
      end
    end
  end

  it 'is idempotent - skips existing files on second run' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.cp_r(File.join(__dir__, '../../templates'), '.')

        # First run
        File.write('.env', 'ANTHROPIC_API_KEY=original')
        File.write('config.yml', 'seeker_name: Original')

        cli = Jojo::CLI.new
        output = capture_io { cli.invoke(:setup, [], {}) }

        # Verify files not overwritten
        _(File.read('.env')).must_equal 'ANTHROPIC_API_KEY=original'
        _(File.read('config.yml')).must_equal 'seeker_name: Original'

        # Verify skipped messages
        _(output[0]).must_include 'already exists (skipped)'
      end
    end
  end
end
```

**Step 2: Run test**

Run: `ruby -Ilib:test test/integration/setup_integration_test.rb`

Expected: Tests pass

**Step 3: Commit**

```bash
git add test/integration/setup_integration_test.rb
git commit -m "test: add integration tests for setup flow"
```

---

### Task 18: Run Full Test Suite

**Step 1: Run all unit tests**

Run: `./bin/jojo test --unit`

Expected: All tests pass

**Step 2: Run all tests**

Run: `./bin/jojo test --all`

Expected: All tests pass

**Step 3: If any tests fail, fix them**

Identify failing tests and fix issues

**Step 4: Commit any fixes**

```bash
git add .
git commit -m "fix: resolve test failures"
```

---

## Phase 8: Manual Verification

### Task 19: Test Fresh Setup Flow

**Step 1: Create clean test directory**

```bash
cd /tmp
git clone /path/to/jojo jojo-test
cd jojo-test
bundle install
```

**Step 2: Run setup and verify flow**

```bash
./bin/jojo setup
```

Verify:
- Prompts for API key
- Prompts for name and URL
- Creates all expected files
- Shows helpful summary

**Step 3: Run setup again and verify idempotence**

```bash
./bin/jojo setup
```

Verify:
- Shows "already exists (skipped)" messages
- Does not prompt for anything
- Does not overwrite files

**Step 4: Test force mode**

```bash
./bin/jojo setup --force
```

Verify:
- Shows warning about overwriting
- Prompts for confirmation
- Re-prompts for all values

**Step 5: Clean up**

```bash
cd /tmp
rm -rf jojo-test
```

---

### Task 20: Test Validation Flow

**Step 1: Create employer without customizing template**

```bash
# In main jojo directory with unchanged templates
./bin/jojo new -s test-employer -j test_job.txt
```

Verify:
- Shows warning about unchanged template
- Prompts to continue
- Allows proceeding

**Step 2: Test with missing inputs**

```bash
rm -rf inputs/
./bin/jojo new -s test-employer -j test_job.txt
```

Verify:
- Shows error about missing generic_resume.md
- Suggests running jojo setup
- Exits with error code

**Step 3: Test generate with unchanged template**

```bash
./bin/jojo setup  # Recreate inputs
./bin/jojo generate -s test-employer
```

Verify:
- Warns about unchanged templates
- Prompts to continue

---

## Phase 9: Final Touches

### Task 21: Update CHANGELOG

**Files:**
- Create or Modify: `CHANGELOG.md`

**Step 1: Add entry for this feature**

```markdown
# Changelog

## [Unreleased]

### Added
- Improved setup process: single command creates all configuration files
- Template validation: warns when input files haven't been customized
- `--force` flag for setup command to overwrite existing files
- Comprehensive template examples for resume, recommendations, and projects

### Changed
- Setup command now creates input file templates automatically
- Input templates include placeholder markers for validation
- Setup is now idempotent - safe to run multiple times

### Removed
- Manual template copying no longer required
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for improved setup"
```

---

### Task 22: Final Integration Test

**Step 1: Run complete workflow test**

```bash
# Clean state
rm -rf inputs/ .env config.yml employers/

# Setup
./bin/jojo setup
# Provide test inputs

# Customize generic_resume.md (remove marker)
sed -i '' '1d' inputs/generic_resume.md

# Create employer
./bin/jojo new -s test-co -j docs/sample_job.txt

# Generate (if you have API key)
# ./bin/jojo generate -s test-co
```

Verify: Everything works end-to-end

**Step 2: Run all tests one final time**

Run: `./bin/jojo test --all -q`

Expected: All pass, clean output

**Step 3: Commit if any final fixes**

```bash
git add .
git commit -m "fix: final integration fixes"
```

---

## Validation Checklist

Before marking complete, verify:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Setup creates .env, config.yml, and input files
- [ ] Setup is idempotent (running twice is safe)
- [ ] Force mode prompts for confirmation
- [ ] Template validation blocks on missing files
- [ ] Template validation warns on unchanged files
- [ ] README accurately reflects new setup process
- [ ] Templates contain placeholder markers
- [ ] Generated materials use customized inputs correctly

## Notes

- The test suite uses Minitest (not RSpec)
- Use `_(value).must_equal expected` syntax for assertions
- Mock CLI interactions using Minitest::Mock
- Use `Dir.mktmpdir` for file system tests
- Template files are in `templates/` directory
- Input files go in `inputs/` (gitignored)
