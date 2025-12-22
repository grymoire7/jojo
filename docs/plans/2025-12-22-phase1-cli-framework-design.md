# Phase 1: CLI Framework and Configuration - Design

**Date:** 2025-12-22
**Status:** Design Complete

## Overview

Phase 1 establishes the CLI framework, configuration management, and basic command structure for Jojo. This phase delivers a working `setup` command and stubs for all other commands, setting the foundation for subsequent phases.

## Architecture Decisions

### CLI Structure
- **Thor-based CLI**: Single `Jojo::CLI` class with all commands as methods
- **Fail-fast approach**: Use `abort` for unrecoverable errors in most commands
- **Error accumulation**: `setup` command collects errors and reports at end
- **Auto-detection**: Job input automatically detected as URL (http/https) or file path
- **Simple slugification**: Employer names converted to lowercase-hyphenated directory names

### Configuration
- **Lazy validation**: Config values validated only when accessed
- **Rerunnable setup**: Setup command can be run multiple times, skipping existing files
- **Minimal prompts**: Only essential inputs (name, API key), sensible defaults for rest
- **Template-based**: Uses ERB templates for config generation

## File Structure

```
lib/jojo/
  cli.rb              # Main Thor CLI class with all commands
  config.rb           # Configuration loader with lazy validation
  employer.rb         # Employer directory/slug management

bin/jojo              # Executable wrapper script

templates/
  config.yml.erb      # Config template with <%= seeker_name %>
  generic_resume.md   # Example resume (documentation only)
  recommendations.md  # Example recommendations (documentation only)

test/
  test_helper.rb      # Already exists
  config_test.rb      # Test Config class
  employer_test.rb    # Test Employer class
  cli_test.rb         # Test CLI basics
  fixtures/           # Sample config files for testing
```

## Component Designs

### 1. Executable Wrapper (`bin/jojo`)

Minimal wrapper that loads and starts Thor CLI:

```ruby
#!/usr/bin/env ruby
require_relative '../lib/jojo'
require_relative '../lib/jojo/cli'

Jojo::CLI.start(ARGV)
```

### 2. CLI Class (`lib/jojo/cli.rb`)

Thor class with class-level options and command methods:

```ruby
module Jojo
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: '-v'
    class_option :employer, type: :string, aliases: '-e'
    class_option :job, type: :string, aliases: '-j'

    desc "setup", "Setup configuration"
    def setup
      # Implementation in Section 3
    end

    desc "generate", "Generate everything"
    def generate
      # Implementation in Section 5
    end

    # Other command stubs...
  end
end
```

### 3. Setup Command Flow

Rerunnable setup with error accumulation:

**Steps:**
1. **Handle config.yml**: Prompt to overwrite if exists, otherwise create new
2. **Handle .env**: Check if exists, otherwise prompt for API key
3. **Ensure inputs/**: Create directory if needed
4. **Report results**: Show errors if any, always display next steps
5. **Exit with status**: Exit 1 if errors occurred

**Error handling:**
- Collect errors in array throughout process
- Continue through all steps even if errors occur
- Report all errors at end
- Always show next steps (even with errors)

**Next steps display:**
- Instructions to copy template files to `inputs/`
- Reminder to edit files with actual data
- Optional files clearly marked

### 4. Config Class (`lib/jojo/config.rb`)

Lazy-loading configuration with validation on access:

```ruby
module Jojo
  class Config
    def initialize(config_path = 'config.yml')
      @config_path = config_path
      @config = nil
    end

    # Accessor methods with lazy validation
    def seeker_name
      config['seeker_name']
    end

    def reasoning_ai_service
      validate_ai_config!('reasoning_ai')
      config['reasoning_ai']['service']
    end

    # Additional accessors...

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

    def validate_ai_config!(key)
      unless config[key] && config[key]['service'] && config[key]['model']
        abort "Error: Invalid AI configuration for #{key} in config.yml"
      end
    end
  end
end
```

### 5. Employer Class (`lib/jojo/employer.rb`)

Centralized path management and slugification:

```ruby
module Jojo
  class Employer
    attr_reader :name, :slug, :base_path

    def initialize(name)
      @name = name
      @slug = slugify(name)
      @base_path = File.join('employers', @slug)
    end

    def create_directory!
      FileUtils.mkdir_p(base_path)
      FileUtils.mkdir_p(website_path)
    end

    # Path accessor methods
    def job_description_path
      File.join(base_path, 'job_description.md')
    end

    # Additional path methods...

    private

    def slugify(text)
      text.downcase
          .gsub(/[^a-z0-9]+/, '-')
          .gsub(/^-|-$/, '')
    end
  end
end
```

**Slugification examples:**
- "Acme Corp" → "acme-corp"
- "AT&T Inc." → "at-t-inc"
- "Example Company LLC" → "example-company-llc"

### 6. Command Implementations

**Generate command (Phase 1 version):**
```ruby
desc "generate", "Generate everything"
def generate
  validate_generate_options!

  config = Jojo::Config.new
  employer = Jojo::Employer.new(options[:employer])

  say "Generating application materials for #{employer.name}...", :green
  employer.create_directory!
  say "✓ Created directory: #{employer.base_path}", :green

  # Future phases will add generation steps here
  say "✓ Setup complete. Additional generation steps coming in future phases.", :yellow
end

private

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

**Other commands:** Stubs that validate options and show "coming in Phase N" message.

## Template Files

### `templates/config.yml.erb`

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

### `templates/generic_resume.md`

Example markdown resume showing expected format with explanatory comments.

### `templates/recommendations.md`

Example LinkedIn recommendations showing expected format.

## Testing Strategy

### Test Coverage

**`test/config_test.rb`:**
- Loading valid config
- Missing config file error
- Invalid YAML error
- Lazy validation (only validates when accessed)
- Default values

**`test/employer_test.rb`:**
- Slugification edge cases (spaces, special chars, unicode)
- Path generation correctness
- Directory creation

**`test/cli_test.rb`:**
- Commands exist and are callable
- Option parsing works
- Help text displays

### Test Fixtures

Create `test/fixtures/` with:
- `valid_config.yml` - complete valid config
- `invalid_config.yml` - missing required fields
- `sample_job.txt` - sample job description text

## Validation Criteria

Phase 1 is complete when:

- ✅ `./bin/jojo help` shows all commands with descriptions
- ✅ `./bin/jojo setup` creates `config.yml` and `.env` interactively
- ✅ `./bin/jojo setup` is rerunnable (can skip existing files)
- ✅ `./bin/jojo generate -e "Acme Corp" -j test.txt` creates employer directory
- ✅ All tests pass: `ruby -Ilib:test test/**/*_test.rb`
- ✅ `chmod +x bin/jojo` makes executable

## Future Considerations

### Potential Refactorings
- Extract setup logic to `lib/jojo/commands/setup.rb` if tests become unwieldy
- Extract command validation to shared module
- Add custom Thor error handling class

### Deferred Decisions
- Job description processing (Phase 2)
- Status log format (will evolve through phases)
- Verbose mode implementation (add as needed)

## Notes

- Code duplication in setup command (config.yml creation) can be refactored during implementation or when writing tests
- Template files are examples only; users maintain their own in `inputs/`
- Clear error messages with instructions essential for missing input files
- Exit codes: 0 for success, 1 for errors
