# Search Provider Configuration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Configure search providers (tavily/serper) during `jojo setup`, with API keys in `.env` and service name in `config.yml`

**Architecture:** Refactor SetupService to gather-then-write pattern for .env file. Add optional search provider prompts after LLM configuration. Move search API key from config.yml to ENV. Simplify config structure from nested to flat.

**Tech Stack:** Ruby, TTY::Prompt, Minitest, ERB templates

**Current State:**
- Search API key stored in config.yml (insecure)
- No setup prompts for search provider
- Config uses nested structure: `search_provider: { service: serper, api_key: xxx }`

**Target State:**
- Setup prompts for optional search provider configuration
- API key in .env (e.g., `TAVILY_API_KEY=xxx`)
- Config uses flat structure: `search: tavily`
- Config class reads API key from ENV dynamically

---

## Phase 1: Update Test Fixtures

### Task 1: Update test fixture config format

**Files:**
- Modify: `test/fixtures/valid_config.yml:10-12`

**Step 1: Update fixture to new format**

Replace lines 10-12 in `test/fixtures/valid_config.yml`:

```yaml
search: serper
```

**Step 2: Verify file is valid YAML**

```bash
ruby -ryaml -e "puts YAML.load_file('test/fixtures/valid_config.yml').inspect"
```

Expected: Hash with `"search"=>"serper"`

**Step 3: Commit**

```bash
git add test/fixtures/valid_config.yml
git commit -m "refactor: update test fixture for flattened search config"
```

---

## Phase 2: Update Config Class

### Task 2: Add search_service method with TDD

**Files:**
- Modify: `test/unit/config_test.rb`
- Modify: `lib/jojo/config.rb:46-56`

**Step 1: Write failing test for search_service**

Add to `test/unit/config_test.rb` in the describe block (after existing tests):

```ruby
  describe '#search_service' do
    it 'returns search service from config' do
      config = Jojo::Config.new('test/fixtures/valid_config.yml')
      _(config.search_service).must_equal 'serper'
    end

    it 'returns nil when search not configured' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', <<~YAML)
            seeker_name: Test
            base_url: https://example.com
            reasoning_ai:
              service: anthropic
              model: sonnet
            text_generation_ai:
              service: anthropic
              model: haiku
          YAML

          config = Jojo::Config.new('config.yml')
          _(config.search_service).must_be_nil
        end
      end
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/config_test.rb -n '/search_service/'
```

Expected: FAIL with "NoMethodError: undefined method `search_service'"

**Step 3: Implement search_service method**

Replace `lib/jojo/config.rb:46-56` with:

```ruby
    def search_service
      config['search']
    end

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

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/config_test.rb -n '/search_service/'
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/jojo/config.rb test/unit/config_test.rb
git commit -m "feat: add Config#search_service for flattened config"
```

### Task 3: Add search_api_key method with TDD

**Files:**
- Modify: `test/unit/config_test.rb`
- Modify: `lib/jojo/config.rb`

**Step 1: Write failing test for search_api_key**

Add to `test/unit/config_test.rb` after the `search_service` describe block:

```ruby
  describe '#search_api_key' do
    it 'returns API key from ENV based on service name' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          ENV['TAVILY_API_KEY'] = 'test-tavily-key'

          config = Jojo::Config.new('config.yml')
          _(config.search_api_key).must_equal 'test-tavily-key'
        ensure
          ENV.delete('TAVILY_API_KEY')
        end
      end
    end

    it 'returns nil when service not configured' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', "seeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          config = Jojo::Config.new('config.yml')
          _(config.search_api_key).must_be_nil
        end
      end
    end

    it 'returns nil when ENV var not set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', "search: serper\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          config = Jojo::Config.new('config.yml')
          _(config.search_api_key).must_be_nil
        end
      end
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/config_test.rb -n '/search_api_key/'
```

Expected: FAIL with "NoMethodError: undefined method `search_api_key'"

**Step 3: Implement search_api_key method**

Add to `lib/jojo/config.rb` after `search_service`:

```ruby
    def search_api_key
      return nil unless search_service

      # Map service name to env var name
      # tavily → TAVILY_API_KEY, serper → SERPER_API_KEY
      env_var_name = "#{search_service.upcase}_API_KEY"
      ENV[env_var_name]
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/config_test.rb -n '/search_api_key/'
```

Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/jojo/config.rb test/unit/config_test.rb
git commit -m "feat: add Config#search_api_key reading from ENV"
```

### Task 4: Add search_configured? method with TDD

**Files:**
- Modify: `test/unit/config_test.rb`
- Modify: `lib/jojo/config.rb`

**Step 1: Write failing test for search_configured?**

Add to `test/unit/config_test.rb` after the `search_api_key` describe block:

```ruby
  describe '#search_configured?' do
    it 'returns true when service and API key both present' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          ENV['TAVILY_API_KEY'] = 'test-key'

          config = Jojo::Config.new('config.yml')
          _(config.search_configured?).must_equal true
        ensure
          ENV.delete('TAVILY_API_KEY')
        end
      end
    end

    it 'returns false when service missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', "seeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          config = Jojo::Config.new('config.yml')
          _(config.search_configured?).must_equal false
        end
      end
    end

    it 'returns false when API key missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', "search: tavily\nseeker_name: Test\nbase_url: https://example.com\nreasoning_ai:\n  service: anthropic\n  model: sonnet\ntext_generation_ai:\n  service: anthropic\n  model: haiku")

          ENV.delete('TAVILY_API_KEY')

          config = Jojo::Config.new('config.yml')
          _(config.search_configured?).must_equal false
        end
      end
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/config_test.rb -n '/search_configured/'
```

Expected: FAIL with "NoMethodError: undefined method `search_configured?'"

**Step 3: Implement search_configured? method**

Add to `lib/jojo/config.rb` after `search_api_key`:

```ruby
    def search_configured?
      !search_service.nil? && !search_api_key.nil?
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/config_test.rb -n '/search_configured/'
```

Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/jojo/config.rb test/unit/config_test.rb
git commit -m "feat: add Config#search_configured? checking both service and ENV"
```

---

## Phase 3: Update ResearchGenerator

### Task 5: Update ResearchGenerator to use new Config methods

**Files:**
- Modify: `lib/jojo/generators/research_generator.rb:97,106,107`

**Step 1: Update method calls in ResearchGenerator**

Replace line 97:

```ruby
      unless config.search_configured?
```

Replace lines 106-107:

```ruby
        search_client = DeepSearch::Client.new(
          service: config.search_service,
          api_key: config.search_api_key
        )
```

**Step 2: Verify syntax**

```bash
ruby -c lib/jojo/generators/research_generator.rb
```

Expected: Syntax OK

**Step 3: Run ResearchGenerator tests**

```bash
ruby -Ilib:test test/unit/research_generator_test.rb
```

Expected: Tests still pass (mocks may need updating if tests use old method names)

**Step 4: Commit**

```bash
git add lib/jojo/generators/research_generator.rb
git commit -m "refactor: use new Config search methods in ResearchGenerator"
```

---

## Phase 4: Update Templates

### Task 6: Update .env.erb template

**Files:**
- Modify: `templates/.env.erb`

**Step 1: Update template with renamed variables and search block**

Replace entire contents of `templates/.env.erb`:

```erb
# LLM Provider Configuration
# Generated during 'jojo setup' - edit this file to change your API key
<%= llm_env_var_name %>=<%= llm_api_key %>

<% if search_provider_slug %>
# Web Search Provider Configuration (for company research enhancement)
<%= search_env_var_name %>=<%= search_api_key %>
<% end %>
```

**Step 2: Verify ERB syntax**

```bash
ruby -rerb -e "ERB.new(File.read('templates/.env.erb')).src" > /dev/null
```

Expected: No errors

**Step 3: Commit**

```bash
git add templates/.env.erb
git commit -m "refactor: update .env.erb for multi-config and optional search"
```

### Task 7: Update config.yml.erb template

**Files:**
- Modify: `templates/config.yml.erb`

**Step 1: Add conditional search block**

Add after `voice_and_tone` line, before website section:

```erb
<% if search_provider_slug %>
search: <%= search_provider_slug %>
<% end %>
```

Full template should be:

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

**Step 2: Verify ERB syntax**

```bash
ruby -rerb -e "ERB.new(File.read('templates/config.yml.erb')).src" > /dev/null
```

Expected: No errors

**Step 3: Commit**

```bash
git add templates/config.yml.erb
git commit -m "feat: add optional search provider to config.yml.erb"
```

---

## Phase 5: Refactor SetupService

### Task 8: Refactor setup_api_configuration to gather (not write)

**Files:**
- Modify: `lib/jojo/setup_service.rb:40-101`
- Modify: `test/unit/setup_service_test.rb` (tests will temporarily break)

**Step 1: Update setup_api_configuration to store variables**

Replace `lib/jojo/setup_service.rb:40-101`:

```ruby
    def setup_api_configuration
      if File.exist?('.env') && !@force
        @cli.say "✓ .env already exists (skipped)", :green
        @skipped_files << '.env'

        # Extract provider from existing .env file
        env_content = File.read('.env')
        env_content.each_line do |line|
          # Match provider-specific API key pattern (e.g., ANTHROPIC_API_KEY=...)
          if line =~ /^([A-Z_]+)_API_KEY=/
            env_var_name = $1
            # Convert env var to provider slug (e.g., ANTHROPIC → anthropic)
            provider_slug = env_var_name.downcase

            # Verify this is a valid provider
            if ProviderHelper.available_providers.include?(provider_slug)
              @provider_slug = provider_slug
              break
            end
          end
        end

        return
      end

      if @force && File.exist?('.env')
        @cli.say "⚠ Recreating .env (--force mode)", :yellow
      else
        @cli.say "Let's configure your API access.", :green
      end

      # Prompt for provider
      providers = ProviderHelper.available_providers
      @cli.say ""
      provider_slug = @prompt.select("Which LLM provider?", providers, {per_page: 15})

      # Get dynamic env var name
      @llm_env_var_name = ProviderHelper.provider_env_var_name(provider_slug)
      provider_display_name = provider_slug.capitalize

      # Prompt for API key
      @llm_api_key = @cli.ask("#{provider_display_name} API key:")

      if @llm_api_key.strip.empty?
        @cli.say "✗ API key is required", :red
        exit 1
      end

      # Store provider for use in setup_personal_configuration
      @provider_slug = provider_slug
      @llm_provider_slug = provider_slug
    end
```

**Step 2: Verify syntax**

```bash
ruby -c lib/jojo/setup_service.rb
```

Expected: Syntax OK

**Step 3: Tests will fail (expected) - continue to next task**

Skip test run for now, will fix after adding write_env_file

**Step 4: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "refactor: setup_api_configuration gathers data without writing"
```

### Task 9: Add setup_search_configuration method with TDD

**Files:**
- Modify: `test/unit/setup_service_test.rb`
- Modify: `lib/jojo/setup_service.rb`

**Step 1: Write failing test for setup_search_configuration**

Add new describe block to `test/unit/setup_service_test.rb` after `setup_personal_configuration` tests:

```ruby
  describe '#setup_search_configuration' do
    it 'configures search when user selects yes and tavily' do
      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      prompt.expect :yes?, true, ["Configure web search for company research? (requires Tavily or Serper API)"]
      prompt.expect :select, 'tavily', ["Which search provider?", ['tavily', 'serper'], Hash]
      cli.expect :ask, 'sk-tavily-test', ["Tavily API key:"]

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
      service.send(:setup_search_configuration)

      cli.verify
      prompt.verify
      _(service.instance_variable_get(:@search_provider_slug)).must_equal 'tavily'
      _(service.instance_variable_get(:@search_api_key)).must_equal 'sk-tavily-test'
      _(service.instance_variable_get(:@search_env_var_name)).must_equal 'TAVILY_API_KEY'
    end

    it 'configures search when user selects yes and serper' do
      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      prompt.expect :yes?, true, ["Configure web search for company research? (requires Tavily or Serper API)"]
      prompt.expect :select, 'serper', ["Which search provider?", ['tavily', 'serper'], Hash]
      cli.expect :ask, 'serper-key-123', ["Serper API key:"]

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
      service.send(:setup_search_configuration)

      cli.verify
      prompt.verify
      _(service.instance_variable_get(:@search_provider_slug)).must_equal 'serper'
      _(service.instance_variable_get(:@search_api_key)).must_equal 'serper-key-123'
      _(service.instance_variable_get(:@search_env_var_name)).must_equal 'SERPER_API_KEY'
    end

    it 'skips search when user selects no' do
      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      prompt.expect :yes?, false, ["Configure web search for company research? (requires Tavily or Serper API)"]

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
      service.send(:setup_search_configuration)

      prompt.verify
      _(service.instance_variable_get(:@search_provider_slug)).must_be_nil
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_search_configuration/'
```

Expected: FAIL with "NoMethodError: undefined method `setup_search_configuration'"

**Step 3: Implement setup_search_configuration**

Add to `lib/jojo/setup_service.rb` after `setup_api_configuration`:

```ruby
    def setup_search_configuration
      @cli.say ""
      configure_search = @prompt.yes?("Configure web search for company research? (requires Tavily or Serper API)")

      unless configure_search
        @search_provider_slug = nil
        return
      end

      # Select provider
      @search_provider_slug = @prompt.select(
        "Which search provider?",
        ['tavily', 'serper'],
        {per_page: 5}
      )

      # Get env var name
      @search_env_var_name = "#{@search_provider_slug.upcase}_API_KEY"
      provider_display_name = @search_provider_slug.capitalize

      # Prompt for API key with loop for empty validation
      loop do
        @search_api_key = @cli.ask("#{provider_display_name} API key:")
        break unless @search_api_key.strip.empty?
        @cli.say "⚠ API key cannot be empty. Please try again.", :yellow
      end
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_search_configuration/'
```

Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add setup_search_configuration for optional search setup"
```

### Task 10: Add write_env_file method with TDD

**Files:**
- Modify: `test/unit/setup_service_test.rb`
- Modify: `lib/jojo/setup_service.rb`

**Step 1: Write failing test for write_env_file**

Add new describe block to `test/unit/setup_service_test.rb`:

```ruby
  describe '#write_env_file' do
    it 'writes .env with LLM config only when search not configured' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/.env.erb', <<~ERB)
            # LLM Provider Configuration
            # Generated during 'jojo setup' - edit this file to change your API key
            <%= llm_env_var_name %>=<%= llm_api_key %>

            <% if search_provider_slug %>
            # Web Search Provider Configuration (for company research enhancement)
            <%= search_env_var_name %>=<%= search_api_key %>
            <% end %>
          ERB

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ Created .env", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.instance_variable_set(:@llm_env_var_name, 'ANTHROPIC_API_KEY')
          service.instance_variable_set(:@llm_api_key, 'sk-ant-test')
          service.instance_variable_set(:@search_provider_slug, nil)
          service.send(:write_env_file)

          cli.verify
          _(File.exist?('.env')).must_equal true
          content = File.read('.env')
          _(content).must_include 'ANTHROPIC_API_KEY=sk-ant-test'
          _(content).wont_include 'TAVILY'
          _(content).wont_include 'SERPER'
        end
      end
    end

    it 'writes .env with both LLM and search config' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/.env.erb', <<~ERB)
            # LLM Provider Configuration
            # Generated during 'jojo setup' - edit this file to change your API key
            <%= llm_env_var_name %>=<%= llm_api_key %>

            <% if search_provider_slug %>
            # Web Search Provider Configuration (for company research enhancement)
            <%= search_env_var_name %>=<%= search_api_key %>
            <% end %>
          ERB

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ Created .env", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.instance_variable_set(:@llm_env_var_name, 'OPENAI_API_KEY')
          service.instance_variable_set(:@llm_api_key, 'sk-openai-test')
          service.instance_variable_set(:@search_provider_slug, 'tavily')
          service.instance_variable_set(:@search_env_var_name, 'TAVILY_API_KEY')
          service.instance_variable_set(:@search_api_key, 'sk-tavily-test')
          service.send(:write_env_file)

          cli.verify
          _(File.exist?('.env')).must_equal true
          content = File.read('.env')
          _(content).must_include 'OPENAI_API_KEY=sk-openai-test'
          _(content).must_include 'TAVILY_API_KEY=sk-tavily-test'
        end
      end
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/write_env_file/'
```

Expected: FAIL with "NoMethodError: undefined method `write_env_file'"

**Step 3: Implement write_env_file**

Add to `lib/jojo/setup_service.rb` after `setup_search_configuration`:

```ruby
    def write_env_file
      # Render .env from template
      begin
        template = ERB.new(File.read('templates/.env.erb'))
        File.write('.env', template.result(binding))
        @cli.say "✓ Created .env", :green
        @created_files << '.env'
      rescue => e
        @cli.say "✗ Failed to create .env: #{e.message}", :red
        exit 1
      end
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/write_env_file/'
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add write_env_file for unified .env generation"
```

### Task 11: Update run method to call new flow

**Files:**
- Modify: `lib/jojo/setup_service.rb:16-25`

**Step 1: Update run method**

Replace `lib/jojo/setup_service.rb:16-25`:

```ruby
    def run
      @cli.say "Setting up Jojo...", :green
      @cli.say ""

      warn_if_force_mode
      setup_api_configuration
      setup_search_configuration
      write_env_file
      setup_personal_configuration
      setup_input_files
      show_summary
    end
```

**Step 2: Verify syntax**

```bash
ruby -c lib/jojo/setup_service.rb
```

Expected: Syntax OK

**Step 3: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "refactor: update setup flow to gather-then-write pattern"
```

### Task 12: Update setup_personal_configuration to use search variable

**Files:**
- Modify: `lib/jojo/setup_service.rb:103-158`

**Step 1: Add search_provider_slug to binding for template**

In `setup_personal_configuration`, before the ERB template rendering (around line 150), add:

```ruby
      # Set provider variables for config template
      reasoning_provider = @provider_slug
      text_generation_provider = @provider_slug
      search_provider_slug = @search_provider_slug  # ADD THIS LINE

      begin
```

The section should look like:

```ruby
      # Set provider variables for config template
      reasoning_provider = @provider_slug
      text_generation_provider = @provider_slug
      search_provider_slug = @search_provider_slug

      begin
        template = ERB.new(File.read('templates/config.yml.erb'))
        File.write('config.yml', template.result(binding))
        @cli.say "✓ Created config.yml", :green
        @created_files << 'config.yml'
      rescue => e
        @cli.say "✗ Failed to create config.yml: #{e.message}", :red
        exit 1
      end
```

**Step 2: Verify syntax**

```bash
ruby -c lib/jojo/setup_service.rb
```

Expected: Syntax OK

**Step 3: Commit**

```bash
git add lib/jojo/setup_service.rb
git commit -m "feat: pass search_provider_slug to config.yml template"
```

---

## Phase 6: Update Existing Tests

### Task 13: Fix setup_api_configuration tests

**Files:**
- Modify: `test/unit/setup_service_test.rb:28-63`

**Step 1: Update tests to not expect .env file creation**

Replace the test at lines 46-62:

```ruby
    it 'gathers LLM config when .env missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/.env.erb', '<%= llm_env_var_name %>=<%= llm_api_key %>')

          cli = Minitest::Mock.new
          prompt = Minitest::Mock.new

          cli.expect :say, nil, ["Let's configure your API access.", :green]
          cli.expect :say, nil, [""]
          prompt.expect :select, 'anthropic', ["Which LLM provider?", Array, Hash]
          cli.expect :ask, 'sk-ant-test-key', ["Anthropic API key:"]

          service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          prompt.verify
          _(File.exist?('.env')).must_equal false  # File not created yet
          _(service.instance_variable_get(:@llm_provider_slug)).must_equal 'anthropic'
          _(service.instance_variable_get(:@llm_api_key)).must_equal 'sk-ant-test-key'
        end
      end
    end
```

**Step 2: Run tests to verify they pass**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_api_configuration/'
```

Expected: PASS (2 tests)

**Step 3: Commit**

```bash
git add test/unit/setup_service_test.rb
git commit -m "test: update setup_api_configuration tests for gather pattern"
```

### Task 14: Update setup_personal_configuration tests

**Files:**
- Modify: `test/unit/setup_service_test.rb` (around line 82-102)

**Step 1: Add search_provider_slug to test setup**

Update the test that creates config.yml to set `@search_provider_slug`:

In the test around line 82-102, add before `service.send(:setup_personal_configuration)`:

```ruby
          service.instance_variable_set(:@provider_slug, 'anthropic')
          service.instance_variable_set(:@search_provider_slug, nil)  # ADD THIS LINE
          service.send(:setup_personal_configuration)
```

**Step 2: Run tests to verify they pass**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_personal_configuration/'
```

Expected: PASS (2 tests)

**Step 3: Commit**

```bash
git add test/unit/setup_service_test.rb
git commit -m "test: add search_provider_slug to setup_personal_configuration tests"
```

---

## Phase 7: Integration Testing

### Task 15: Add integration test for setup with search

**Files:**
- Modify: `test/integration/setup_integration_test.rb`

**Step 1: Add test for setup flow with search provider**

Add new test to `test/integration/setup_integration_test.rb`:

```ruby
  it 'completes full setup flow with search provider' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files
        FileUtils.mkdir_p('templates')
        FileUtils.cp(
          File.join(__dir__, '../../templates/.env.erb'),
          'templates/.env.erb'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/config.yml.erb'),
          'templates/config.yml.erb'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/generic_resume.md'),
          'templates/generic_resume.md'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/recommendations.md'),
          'templates/recommendations.md'
        )
        FileUtils.cp(
          File.join(__dir__, '../../templates/projects.yml'),
          'templates/projects.yml'
        )

        # Mock CLI interactions
        cli = Minitest::Mock.new
        prompt = Minitest::Mock.new

        # warn_if_force_mode (skipped - not in force mode)

        # setup_api_configuration
        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :say, nil, [""]
        prompt.expect :select, 'anthropic', ["Which LLM provider?", Array, Hash]
        cli.expect :ask, 'sk-ant-test123', ["Anthropic API key:"]

        # setup_search_configuration
        cli.expect :say, nil, [""]
        prompt.expect :yes?, true, [String]  # Configure search?
        prompt.expect :select, 'tavily', ["Which search provider?", Array, Hash]
        cli.expect :ask, 'sk-tavily-test', ["Tavily API key:"]

        # write_env_file
        cli.expect :say, nil, ["✓ Created .env", :green]

        # setup_personal_configuration
        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        prompt.expect :select, 'claude-sonnet-4-5', [/Which model for reasoning/, Array, Hash]
        cli.expect :say, nil, [""]
        prompt.expect :select, 'claude-3-5-haiku-20241022', [/Which model for text generation/, Array, Hash]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        # setup_input_files
        cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setting up your profile templates...", :green]
        3.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        8.times { cli.expect :say, nil, [String] }

        service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
        service.run

        cli.verify
        prompt.verify

        # Verify .env
        _(File.exist?('.env')).must_equal true
        env_content = File.read('.env')
        _(env_content).must_include 'ANTHROPIC_API_KEY=sk-ant-test123'
        _(env_content).must_include 'TAVILY_API_KEY=sk-tavily-test'

        # Verify config.yml
        _(File.exist?('config.yml')).must_equal true
        config_content = File.read('config.yml')
        _(config_content).must_include 'seeker_name: Test User'
        _(config_content).must_include 'service: anthropic'
        _(config_content).must_include 'search: tavily'

        # Verify input files
        _(File.exist?('inputs/generic_resume.md')).must_equal true
        _(File.exist?('inputs/recommendations.md')).must_equal true
        _(File.exist?('inputs/projects.yml')).must_equal true
      end
    end
  end
```

**Step 2: Run integration test**

```bash
ruby -Ilib:test test/integration/setup_integration_test.rb
```

Expected: PASS (all tests including new one)

**Step 3: Commit**

```bash
git add test/integration/setup_integration_test.rb
git commit -m "test: add integration test for setup with search provider"
```

---

## Phase 8: Remove Old Config Methods

### Task 16: Remove deprecated Config methods

**Files:**
- Modify: `lib/jojo/config.rb`

**Step 1: Remove old search_provider_* methods**

Remove the old methods from `lib/jojo/config.rb` (should be after the new methods):

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

**Step 2: Run all tests to ensure nothing breaks**

```bash
ruby -Ilib:test test/unit/config_test.rb
```

Expected: PASS (all tests)

**Step 3: Commit**

```bash
git add lib/jojo/config.rb
git commit -m "refactor: remove deprecated search_provider_* methods"
```

---

## Phase 9: Manual Testing

### Task 17: Manual smoke test with tavily

**Step 1: Create test directory**

```bash
mkdir -p /tmp/jojo-search-test
cd /tmp/jojo-search-test
```

**Step 2: Run setup**

```bash
export JOJO_EMPLOYER_SLUG=test-smoke
/Users/tracy/projects/jojo/bin/jojo setup
```

**Step 3: Interact with prompts**

- Select `anthropic` for LLM provider
- Enter a test API key: `sk-ant-test-key-123`
- Select "Yes" for search configuration
- Select `tavily` for search provider
- Enter test search key: `tvly-test-key-456`
- Enter name: `Test User`
- Enter URL: `https://test.com`
- Select models: `claude-sonnet-4-5` and `claude-3-5-haiku-20241022`

**Step 4: Verify .env file**

```bash
cat .env
```

Expected output:
```
# LLM Provider Configuration
# Generated during 'jojo setup' - edit this file to change your API key
ANTHROPIC_API_KEY=sk-ant-test-key-123

# Web Search Provider Configuration (for company research enhancement)
TAVILY_API_KEY=tvly-test-key-456
```

**Step 5: Verify config.yml file**

```bash
cat config.yml
```

Expected: Contains `search: tavily` and no `api_key` field for search

**Step 6: Clean up**

```bash
cd /Users/tracy/projects/jojo
rm -rf /tmp/jojo-search-test
```

### Task 18: Manual smoke test without search

**Step 1: Create test directory**

```bash
mkdir -p /tmp/jojo-no-search-test
cd /tmp/jojo-no-search-test
```

**Step 2: Run setup**

```bash
export JOJO_EMPLOYER_SLUG=test-smoke
/Users/tracy/projects/jojo/bin/jojo setup
```

**Step 3: Interact with prompts**

- Select `openai` for LLM provider
- Enter test key: `sk-openai-test`
- Select "No" for search configuration
- Enter name and URL
- Select models

**Step 4: Verify .env file**

```bash
cat .env
```

Expected: Contains only OPENAI_API_KEY, no search provider section

**Step 5: Verify config.yml file**

```bash
cat config.yml | grep search
```

Expected: No output (no search field in config)

**Step 6: Clean up**

```bash
cd /Users/tracy/projects/jojo
rm -rf /tmp/jojo-no-search-test
```

---

## Phase 10: Final Validation

### Task 19: Run full test suite

**Step 1: Run all unit tests**

```bash
ruby -Ilib:test:test/fixtures -e 'Dir.glob("test/unit/**/*_test.rb").each { |f| require_relative f }'
```

Expected: All tests PASS

**Step 2: Run all integration tests**

```bash
ruby -Ilib:test:test/fixtures -e 'Dir.glob("test/integration/**/*_test.rb").each { |f| require_relative f }'
```

Expected: All tests PASS

**Step 3: Run project test command**

```bash
./bin/jojo test
```

Expected: All tests PASS

---

## Validation Checklist

After completing all tasks, verify:

- [ ] Config class has new methods (search_service, search_api_key, search_configured?)
- [ ] Old Config methods removed
- [ ] ResearchGenerator uses new Config methods
- [ ] Templates updated (.env.erb and config.yml.erb)
- [ ] SetupService uses gather-then-write pattern
- [ ] Setup prompts for optional search configuration
- [ ] .env contains both LLM and search API keys (when configured)
- [ ] config.yml uses flat structure (search: tavily)
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual testing with search works
- [ ] Manual testing without search works
- [ ] No search API key in config.yml files
