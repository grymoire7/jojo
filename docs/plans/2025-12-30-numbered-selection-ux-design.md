# Numbered Selection UX Improvement

## Goal

Improve setup UX by replacing free-text provider/model selection with numbered menus. Users type numbers instead of long strings like `claude-3-7-sonnet-20250219`.

## Problem

Current setup requires typing exact provider/model names:
- Error-prone (typos in long model names)
- Tedious (must type full names)
- Unclear what options are available (comma-separated list)

Example:
```
Which LLM provider? (anthropic, bedrock, deepseek, gemini, gpustack, mistral, ollama, openai, openrouter, perplexity, vertexai):
█
```

## Solution

Use TTY::Prompt gem for numbered selection menus with arrow key navigation.

Example:
```
Which LLM provider?
  1. anthropic
  2. bedrock
  3. deepseek
  ...
  11. vertexai
Choose 1-11: █
```

## Architecture

### Dependencies
- Add `tty-prompt` gem (~100KB, zero runtime dependencies)
- Version: `~> 0.23` (current stable)

### Integration
- SetupService instantiates `TTY::Prompt` for interactive selections
- Keep Thor's `@cli.say()` for messages (no change)
- Replace `@cli.ask()` + validation with `@prompt.select()` for lists

### Constructor Changes
```ruby
class SetupService
  def initialize(cli_instance:, prompt: nil, force: false)
    @cli = cli_instance
    @prompt = prompt || TTY::Prompt.new
    @force = force
    @created_files = []
    @skipped_files = []
  end
end
```

## Implementation

### Provider Selection (setup_api_configuration)

**Before (lines 69-81):**
```ruby
providers = ProviderHelper.available_providers
provider_slug = @cli.ask("Which LLM provider? (#{providers.join(', ')}):")

if provider_slug.strip.empty?
  @cli.say "✗ Provider is required", :red
  exit 1
end

unless providers.include?(provider_slug)
  @cli.say "✗ Invalid provider. Choose from: #{providers.join(', ')}", :red
  exit 1
end
```

**After:**
```ruby
providers = ProviderHelper.available_providers
@cli.say ""
provider_slug = @prompt.select("Which LLM provider?", providers, per_page: 15)
```

**Lines removed:** ~10 (validation no longer needed)

### Model Selection (setup_personal_configuration)

**Before (lines 138-153):**
```ruby
@cli.say ""
@cli.say "Available models for #{@provider_slug}:", :cyan
@cli.say "  #{available_models.join(', ')}"
@cli.say ""

reasoning_model = @cli.ask("Which model for reasoning tasks (company research, resume tailoring)?")
if reasoning_model.strip.empty?
  @cli.say "✗ Reasoning model is required", :red
  exit 1
end

text_generation_model = @cli.ask("Which model for text generation tasks (faster, simpler)?")
if text_generation_model.strip.empty?
  @cli.say "✗ Text generation model is required", :red
  exit 1
end
```

**After:**
```ruby
@cli.say ""
reasoning_model = @prompt.select(
  "Which model for reasoning tasks (company research, resume tailoring)?",
  available_models,
  per_page: 15
)

@cli.say ""
text_generation_model = @prompt.select(
  "Which model for text generation tasks (faster, simpler)?",
  available_models,
  per_page: 15
)
```

**Lines removed:** ~10 (display + validation)

## Testing

### Test Changes

**Current mocking:**
```ruby
cli.expect :ask, 'anthropic', ["Which LLM provider? (...)"]
```

**New mocking:**
```ruby
prompt = Minitest::Mock.new
prompt.expect :select, 'anthropic', ["Which LLM provider?", Array, Hash]

service = SetupService.new(cli_instance: cli, prompt: prompt, force: false)
```

### Files to Update
- `test/unit/setup_service_test.rb` - 6 test cases
- `test/integration/setup_integration_test.rb` - 2 test cases

### Test Strategy
1. Add `prompt:` parameter to SetupService constructor (optional, defaults to new TTY::Prompt)
2. Tests inject mock prompt object
3. Mock expectations change from `cli.ask` to `prompt.select`
4. Update expected arguments (question text, array of options, hash of config)

## User Experience

### Features
- **Arrow keys**: Navigate up/down through options
- **Number input**: Type `3` and press Enter
- **Fuzzy search**: Type partial text to filter (e.g., `anthro` → anthropic)
- **Pagination**: Long lists show 15 items at a time with navigation
- **Validation**: Invalid input auto re-prompts, no manual error handling needed
- **Ctrl+C**: Gracefully exits with code 130

### Example Session
```
Setting up Jojo...

Let's configure your API access.

Which LLM provider?
  1. anthropic
  2. bedrock
  3. deepseek
  4. gemini
  5. gpustack
  6. mistral
  7. ollama
  8. openai
  9. openrouter
  10. perplexity
  11. vertexai
Choose 1-11: 1

Anthropic API key: sk-ant-***

Your name: Tracy Atteberry
Your website base URL (e.g., https://yourname.com): https://tracyatteberry.com

Which model for reasoning tasks (company research, resume tailoring)?
  1. claude-3-5-haiku-20241022
  2. claude-3-5-sonnet-20241022
  3. claude-3-7-sonnet-20250219
  4. claude-sonnet-4-5
  5. claude-opus-4-5
Choose 1-5: 4

Which model for text generation tasks (faster, simpler)?
  1. claude-3-5-haiku-20241022
  2. claude-3-5-sonnet-20241022
  3. claude-3-7-sonnet-20250219
  4. claude-sonnet-4-5
  5. claude-opus-4-5
Choose 1-5: 1

✓ Created .env
✓ Created config.yml
```

## Migration & Compatibility

### No Breaking Changes
- Existing `.env` and `config.yml` files unchanged
- Users see improved UX on next `jojo setup --force`
- All existing functionality preserved

### Edge Cases
- **Long lists (50+ models)**: `per_page: 15` handles pagination automatically
- **Single option**: TTY::Prompt shows single item, still requires selection
- **No providers found**: Existing error handling (`available_models.empty?`) still works
- **Non-interactive terminal**: TTY::Prompt detects and falls back to simple prompts

## Benefits

1. **Fewer errors**: No typos in long model names
2. **Faster setup**: Type `4` instead of `claude-3-7-sonnet-20250219`
3. **Better discoverability**: Full list visible, numbered for reference
4. **Less code**: ~20 lines of validation removed
5. **Professional UX**: Arrow keys, pagination, standard CLI conventions

## Implementation Tasks

1. Add `tty-prompt` to Gemfile
2. Update SetupService constructor to accept optional `prompt:` parameter
3. Replace provider selection with `@prompt.select()`
4. Replace model selection with `@prompt.select()`
5. Update unit tests to mock `prompt.select()`
6. Update integration tests to mock `prompt.select()`
7. Run full test suite
8. Manual smoke test
9. Update documentation (README shows new UX example)
