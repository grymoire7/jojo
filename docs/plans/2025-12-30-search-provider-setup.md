# Search Provider Configuration Design

**Goal:** Configure search providers (tavily/serper) consistently during `jojo setup`, with API keys in `.env` and service name in `config.yml`

**Date:** 2025-12-30

## Problem Statement

Current search API configuration is inconsistent:
- API key stored in `config.yml` (security issue - shouldn't be in version control)
- Not prompted during `jojo setup` (manual configuration required)
- Different pattern than LLM provider configuration

## Architecture

### Current State
- `config.yml` contains `search_provider.service` and `search_provider.api_key`
- API key stored in version-controlled config file
- No setup prompts for search provider
- ResearchGenerator handles missing config gracefully

### Target State
- Setup asks optional Yes/No question about web search
- If Yes: prompt for provider (tavily/serper) and API key
- `.env` stores search API key (e.g., `TAVILY_API_KEY=...` or `SERPER_API_KEY=...`)
- `config.yml` stores only provider name (e.g., `search: tavily`)
- Config class reads provider from YAML, API key from ENV

### Security Improvement
- API keys move from `config.yml` (version control) to `.env` (gitignored)
- Matches pattern already used for LLM providers

## Implementation Design

### 1. SetupService Flow

**Refactored Setup Order:**
```
1. warn_if_force_mode
2. setup_api_configuration (gather LLM info, DON'T write .env yet)
3. setup_search_configuration (gather search info) ← NEW
4. write_env_file (write .env once with all info) ← NEW
5. setup_personal_configuration
6. setup_input_files
7. show_summary
```

**Method: `setup_api_configuration` (modified)**
- Check if `.env` exists and skip prompt if not force mode
- Prompt for LLM provider and API key
- Store in instance variables: `@llm_provider_slug`, `@llm_api_key`, `@llm_env_var_name`
- **DON'T write .env file** (wait for write_env_file)
- Set `@provider_slug` for backward compatibility with setup_personal_configuration

**Method: `setup_search_configuration` (new)**
- Ask Yes/No: "Configure web search for company research? (requires Tavily or Serper API)"
- If No: set `@search_provider_slug = nil` and return
- If Yes:
  - Select provider: "Which search provider?" → ['tavily', 'serper']
  - Ask for API key with reprompt loop:
    ```ruby
    loop do
      api_key = @cli.ask("#{provider_display_name} API key:")
      break unless api_key.strip.empty?
      @cli.say "⚠ API key cannot be empty. Please try again.", :yellow
    end
    ```
  - Store in instance variables: `@search_provider_slug`, `@search_api_key`, `@search_env_var_name`

**Method: `write_env_file` (new)**
- Render `.env.erb` template with both LLM and search variables
- Write file once
- Add to `@created_files`
- Handle errors with rescue block

### 2. Template Updates

**`.env.erb` Template:**
```erb
# LLM Provider Configuration
# Generated during 'jojo setup' - edit this file to change your API key
<%= llm_env_var_name %>=<%= llm_api_key %>

<% if search_provider_slug %>
# Web Search Provider Configuration (for company research enhancement)
<%= search_env_var_name %>=<%= search_api_key %>
<% end %>
```

**Changes:**
- Rename variables: `env_var_name` → `llm_env_var_name`, `api_key` → `llm_api_key`
- Add conditional block for search provider (only appears if configured)
- Remove hardcoded "SERPER_API_KEY" comment line

**`config.yml.erb` Template:**
```erb
seeker_name: <%= seeker_name %>
base_url: <%= base_url %>
reasoning_ai:
  service: <%= reasoning_provider %>
  model: <%= reasoning_model %>
text_generation_ai:
  service: <%= text_generation_provider %>
  model: <%= text_generation_model %>
voice_and_tone: professional and friendly
<% if search_provider_slug %>
search: <%= search_provider_slug %>
<% end %>

# Website configuration
website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

**Changes:**
- Add conditional `search` field (only if configured during setup)
- Flatten structure: `search: tavily` (not nested with service/api_key)
- Remove `api_key` field from search configuration

### 3. Config Class Updates

**Current Implementation (lib/jojo/config.rb:46-56):**
```ruby
def search_provider_service
  config.dig('search_provider', 'service')
end

def search_provider_api_key
  config.dig('search_provider', 'api_key')
end

def search_provider_configured?
  !search_provider_service.nil? && !search_provider_api_key.nil?
end
```

**New Implementation:**
```ruby
def search_service
  config['search']
end

def search_api_key
  return nil unless search_service

  # Map service name to env var name
  # tavily → TAVILY_API_KEY, serper → SERPER_API_KEY
  env_var_name = "#{search_service.upcase}_API_KEY"
  ENV[env_var_name]
end

def search_configured?
  !search_service.nil? && !search_api_key.nil?
end
```

**Breaking Changes:**
- `search_provider_service` → `search_service`
- `search_provider_api_key` → `search_api_key`
- `search_provider_configured?` → `search_configured?`

**Note:** No backward compatibility needed (only one user currently)

### 4. ResearchGenerator Integration

**Updates in `lib/jojo/generators/research_generator.rb`:**

**Line 97:** Change method name
```ruby
unless config.search_configured?  # was: search_provider_configured?
  log "Warning: Search provider not configured, skipping web search"
  return nil
end
```

**Lines 105-108:** Update to use new Config methods
```ruby
# Configure deepsearch with the search provider
search_client = DeepSearch::Client.new(
  service: config.search_service,        # was: search_provider_service
  api_key: config.search_api_key         # was: search_provider_api_key
)
```

**Total Changes:**
- 3 method name updates in ResearchGenerator
- Simple find/replace pattern

## Error Handling

### During Setup

1. **Empty API key:** Reprompt with warning (not error/exit)
2. **Force mode with existing .env:** Overwrite with new content from template
3. **Template rendering fails:** Show error and exit (existing pattern)

### Runtime (ResearchGenerator)

1. **Search configured but ENV var not set:** `search_configured?` returns false, gracefully skips
2. **Search configured but invalid provider:** DeepSearch raises error, caught by existing rescue block
3. **API call fails:** Existing rescue block handles, logs warning, returns nil

## Testing Strategy

### Config class tests (`test/unit/config_test.rb`):
- Test `search_service` returns value from config YAML
- Test `search_api_key` reads from ENV based on service name
- Test `search_configured?` returns true when both service and ENV var present
- Test `search_configured?` returns false when service missing
- Test `search_configured?` returns false when ENV var missing

### SetupService tests (`test/unit/setup_service_test.rb`):
- New describe block for `setup_search_configuration`
- Test: user selects "yes" and configures tavily
- Test: user selects "yes" and configures serper
- Test: user selects "no" and skips search configuration
- Update existing tests to expect new `write_env_file` call
- Update integration test to include search provider prompts

### ResearchGenerator tests:
- Update mocks to use `search_service`, `search_api_key`, `search_configured?`
- No new test logic needed, just method name changes

### Test Fixtures:
- Update `test/fixtures/valid_config.yml`:
  ```yaml
  search: serper  # was: search_provider: { service: serper, api_key: xxx }
  ```

## Supported Providers

According to deepsearch-rb source (https://github.com/alexshagov/deepsearch-rb):
- `tavily` - Tavily API
- `serper` - Serper API
- `mock` - Not exposed in setup (test-only)

## Migration Path

**No backward compatibility needed** - currently only one user. Existing installations will need to:
1. Run `jojo setup --force` to reconfigure
2. Or manually migrate:
   - Move API key from `config.yml` to `.env` (e.g., `TAVILY_API_KEY=xxx`)
   - Change `config.yml` from `search_provider: { service: tavily, api_key: xxx }` to `search: tavily`

## Key Design Decisions

1. **Optional configuration:** Web search requires paid API, let users skip
2. **Gather then write:** Collect all .env info before writing (cleaner logic)
3. **Flattened config:** `search: tavily` not `search: { service: tavily }`
4. **ENV-based API keys:** Config reads from ENV dynamically
5. **Reprompt on empty:** Better UX than error/exit
