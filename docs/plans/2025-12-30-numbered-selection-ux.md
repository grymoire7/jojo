# Numbered Selection UX Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace free-text provider/model selection with numbered menus using TTY::Prompt

**Architecture:** Add tty-prompt gem, update SetupService to use @prompt.select() instead of @cli.ask() + validation. Tests inject mock prompt for expectations.

**Tech Stack:** Ruby, TTY::Prompt 0.23, Thor CLI, Minitest

**Current State:**
- Provider selection: `@cli.ask()` with manual validation (lines 69-81)
- Model selection: `@cli.ask()` with manual validation (lines 138-153)
- Tests mock `cli.ask` with string responses

**Target State:**
- Provider selection: `@prompt.select()` with numbered menu
- Model selection: `@prompt.select()` with numbered menu
- Tests mock `prompt.select` with expected arguments

---

## Phase 1: Add Dependency

### Task 1: Add tty-prompt gem

**Files:**
- Modify: `Gemfile`

**Step 1: Add gem to Gemfile**

Add after existing gems:

```ruby
gem 'tty-prompt', '~> 0.23'
```

**Step 2: Install gem**

```bash
bundle install
```

Expected: `tty-prompt` installed successfully

**Step 3: Verify installation**

```bash
bundle list | grep tty-prompt
```

Expected: Shows `tty-prompt (0.23.x)`

**Step 4: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "feat: add tty-prompt gem for numbered selection menus"
```

---

## Phase 2: Update SetupService Constructor

### Task 2: Add prompt parameter to constructor

**Files:**
- Modify: `lib/jojo/setup_service.rb:1-11`
- Modify: `test/unit/setup_service_test.rb:6-25`

**Step 1: Write failing test for prompt injection**

Add new test to `test/unit/setup_service_test.rb` after line 25:

```ruby
    it 'accepts optional prompt parameter' do
      cli = Object.new
      prompt = Object.new
      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt)
      _(service.instance_variable_get(:@prompt)).must_be_same_as prompt
    end

    it 'creates default TTY::Prompt when prompt not provided' do
      cli = Object.new
      service = Jojo::SetupService.new(cli_instance: cli)
      _(service.instance_variable_get(:@prompt)).must_be_instance_of TTY::Prompt
    end
```

**Step 2: Run test to verify it fails**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/prompt/'
```

Expected: FAIL with "uninitialized constant TTY"

**Step 3: Add require and update constructor**

At top of `lib/jojo/setup_service.rb:1`:

```ruby
require 'fileutils'
require 'erb'
require 'tty-prompt'
require_relative 'provider_helper'
```

Update constructor at `lib/jojo/setup_service.rb:6-11`:

```ruby
    def initialize(cli_instance:, prompt: nil, force: false)
      @cli = cli_instance
      @prompt = prompt || TTY::Prompt.new
      @force = force
      @created_files = []
      @skipped_files = []
    end
```

**Step 4: Run test to verify it passes**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/prompt/'
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add optional prompt parameter to SetupService constructor"
```

---

## Phase 3: Replace Provider Selection

### Task 3: Update provider selection to use prompt.select

**Files:**
- Modify: `lib/jojo/setup_service.rb:69-81`
- Modify: `test/unit/setup_service_test.rb:48-66`

**Step 1: Update test to mock prompt.select**

Replace test at `test/unit/setup_service_test.rb:48-66`:

```ruby
    it 'creates .env when missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/.env.erb', '<%= env_var_name %>=<%= api_key %>')

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["Let's configure your API access.", :green]
          cli.expect :say, nil, [""]
          cli.expect :ask, 'sk-ant-test-key', ["Anthropic API key:"]
          cli.expect :say, nil, ["✓ Created .env", :green]

          prompt = Minitest::Mock.new
          prompt.expect :select, 'anthropic', ["Which LLM provider?", Jojo::ProviderHelper.available_providers, {per_page: 15}]

          service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          prompt.verify
          _(File.exist?('.env')).must_equal true
          _(File.read('.env')).must_include 'ANTHROPIC_API_KEY=sk-ant-test-key'
        end
      end
    end
```

**Step 2: Run test to verify it fails**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/creates .env when missing/'
```

Expected: FAIL with "no method 'select' has been stubbed"

**Step 3: Update implementation**

Replace `lib/jojo/setup_service.rb:69-81` with:

```ruby
      # Prompt for provider
      providers = ProviderHelper.available_providers
      @cli.say ""
      provider_slug = @prompt.select("Which LLM provider?", providers, per_page: 15)
```

**Step 4: Run test to verify it passes**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/creates .env when missing/'
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: replace provider selection with numbered menu"
```

---

## Phase 4: Replace Model Selection

### Task 4: Update model selection to use prompt.select

**Files:**
- Modify: `lib/jojo/setup_service.rb:138-153`
- Modify: `test/unit/setup_service_test.rb:87-126`

**Step 1: Update test to mock prompt.select for models**

Replace test at `test/unit/setup_service_test.rb:87-126`:

```ruby
    it 'creates config.yml from template when missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/config.yml.erb', <<~YAML)
            seeker_name: <%= seeker_name %>
            base_url: <%= base_url %>
            reasoning_ai:
              service: <%= reasoning_provider %>
              model: <%= reasoning_model %>
            text_generation_ai:
              service: <%= text_generation_provider %>
              model: <%= text_generation_model %>
          YAML

          cli = Minitest::Mock.new
          cli.expect :ask, 'Tracy Atteberry', ["Your name:"]
          cli.expect :ask, 'https://example.com', ["Your website base URL (e.g., https://yourname.com):"]
          cli.expect :say, nil, [""]
          cli.expect :say, nil, [""]
          cli.expect :say, nil, ["✓ Created config.yml", :green]

          prompt = Minitest::Mock.new
          available_models = Jojo::ProviderHelper.available_models('anthropic')
          prompt.expect :select, 'claude-sonnet-4-5', [
            "Which model for reasoning tasks (company research, resume tailoring)?",
            available_models,
            {per_page: 15}
          ]
          prompt.expect :select, 'claude-3-5-haiku-20241022', [
            "Which model for text generation tasks (faster, simpler)?",
            available_models,
            {per_page: 15}
          ]

          service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
          service.instance_variable_set(:@provider_slug, 'anthropic')
          service.send(:setup_personal_configuration)

          cli.verify
          prompt.verify
          _(File.exist?('config.yml')).must_equal true
          content = File.read('config.yml')
          _(content).must_include 'Tracy Atteberry'
          _(content).must_include 'service: anthropic'
          _(content).must_include 'model: claude-sonnet-4-5'
          _(content).must_include 'model: claude-3-5-haiku-20241022'
        end
      end
    end
```

**Step 2: Run test to verify it fails**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/creates config.yml from template when missing/'
```

Expected: FAIL with "no method 'select' has been stubbed"

**Step 3: Update implementation**

Replace `lib/jojo/setup_service.rb:138-153` with:

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

**Step 4: Run test to verify it passes**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/creates config.yml from template when missing/'
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: replace model selection with numbered menus"
```

---

## Phase 5: Update Integration Tests

### Task 5: Update integration tests for prompt.select

**Files:**
- Modify: `test/integration/setup_integration_test.rb:38-54`
- Modify: `test/integration/setup_integration_test.rb:128-144`

**Step 1: Update first integration test (Anthropic)**

Replace lines 38-54 in `test/integration/setup_integration_test.rb`:

```ruby
        # setup_api_configuration
        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :say, nil, [""]
        cli.expect :ask, 'sk-ant-test123', ["Anthropic API key:"]
        cli.expect :say, nil, ["✓ Created .env", :green]

        # setup_personal_configuration
        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        # Add prompt mock
        prompt = Minitest::Mock.new
        providers = Jojo::ProviderHelper.available_providers
        available_models = Jojo::ProviderHelper.available_models('anthropic')

        prompt.expect :select, 'anthropic', ["Which LLM provider?", providers, {per_page: 15}]
        prompt.expect :select, 'claude-sonnet-4-5', [
          "Which model for reasoning tasks (company research, resume tailoring)?",
          available_models,
          {per_page: 15}
        ]
        prompt.expect :select, 'claude-3-5-haiku-20241022', [
          "Which model for text generation tasks (faster, simpler)?",
          available_models,
          {per_page: 15}
        ]
```

Update service instantiation at line ~75:

```ruby
        service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: false)
```

Add prompt.verify at line ~78:

```ruby
        cli.verify
        prompt.verify
```

**Step 2: Update second integration test (OpenAI)**

Replace lines 128-144 in `test/integration/setup_integration_test.rb` with similar pattern:

```ruby
        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :say, nil, [""]
        cli.expect :ask, 'sk-test-openai', ["Openai API key:"]
        cli.expect :say, nil, ["✓ Created .env", :green]

        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        # Add prompt mock
        prompt = Minitest::Mock.new
        providers = Jojo::ProviderHelper.available_providers
        available_models = Jojo::ProviderHelper.available_models('openai')

        prompt.expect :select, 'openai', ["Which LLM provider?", providers, {per_page: 15}]
        prompt.expect :select, 'gpt-4o', [
          "Which model for reasoning tasks (company research, resume tailoring)?",
          available_models,
          {per_page: 15}
        ]
        prompt.expect :select, 'gpt-4o-mini', [
          "Which model for text generation tasks (faster, simpler)?",
          available_models,
          {per_page: 15}
        ]
```

Update service instantiation and add prompt.verify similarly.

**Step 3: Run test to verify it fails**

```bash
bundle exec ruby -Ilib:test test/integration/setup_integration_test.rb
```

Expected: FAIL with mock errors

**Step 4: Complete the updates**

Apply all changes from steps 1-2.

**Step 5: Run test to verify it passes**

```bash
bundle exec ruby -Ilib:test test/integration/setup_integration_test.rb
```

Expected: PASS (2 tests)

**Step 6: Commit**

```bash
git add test/integration/setup_integration_test.rb
git commit -m "test: update integration tests for numbered selection"
```

---

## Phase 6: Validation

### Task 6: Run full test suite

**Step 1: Run all tests**

```bash
./bin/jojo test
```

Expected: All tests PASS (169 tests, 533+ assertions)

**Step 2: If any tests fail, fix them**

Review failures and update tests to use prompt mock instead of cli.ask mock.

**Step 3: Commit any fixes**

```bash
git add test/
git commit -m "test: fix remaining tests for numbered selection"
```

---

## Phase 7: Documentation

### Task 7: Update README with new UX example

**Files:**
- Modify: `README.md:89-94`

**Step 1: Update setup wizard description**

Replace lines 89-94 in `README.md`:

```markdown
   The setup wizard will guide you through:
   - **LLM Provider Selection**: Choose from 11 supported providers using numbered menu
   - **API Key Configuration**: Provide your API key for the chosen provider
   - **Model Selection**: Choose reasoning and text generation models using numbered menus
   - **Personal Information**: Your name and website URL
   - **Template Files**: Creates resume, recommendations, and projects templates
```

**Step 2: Add UX example section**

Add after the setup section (around line 96):

```markdown
   **Example:**
   ```
   Which LLM provider?
     1. anthropic
     2. bedrock
     3. deepseek
     ...
     11. vertexai
   Choose 1-11: 1

   Anthropic API key: sk-ant-***

   Your name: Tracy Atteberry
   Your website base URL: https://tracyatteberry.com

   Which model for reasoning tasks (company research, resume tailoring)?
     1. claude-3-5-haiku-20241022
     2. claude-3-5-sonnet-20241022
     3. claude-sonnet-4-5
     4. claude-opus-4-5
   Choose 1-4: 3
   ```
```

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update README with numbered selection UX example"
```

---

## Phase 8: Update CHANGELOG

### Task 8: Document UX improvement in CHANGELOG

**Files:**
- Modify: `CHANGELOG.md:16-20`

**Step 1: Add UX improvement entry**

Add under "### Added" section in CHANGELOG.md:

```markdown
- Numbered selection menus for provider/model choice (type `3` instead of `claude-sonnet-4-5`)
- Arrow key navigation for all selection menus
- Fuzzy search support in selection menus
```

Add under "### Changed" section:

```markdown
- Setup now uses interactive numbered menus instead of free-text input for providers and models
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for numbered selection UX"
```

---

## Phase 9: Final Verification

### Task 9: Manual smoke test

**Step 1: Run setup in test directory**

```bash
mkdir -p /tmp/jojo-ux-test
cd /tmp/jojo-ux-test
export JOJO_EMPLOYER_SLUG=test-ux
/Users/tracy/projects/jojo/bin/jojo setup
```

**Step 2: Test numbered selection**

- Verify numbered list appears for providers
- Type `1` to select anthropic
- Enter test API key
- Verify numbered list appears for models
- Type `3` to select a model
- Type `1` to select another model

**Step 3: Verify files created**

```bash
cat .env
cat config.yml
```

Expected:
- `.env` contains correct provider API key
- `config.yml` contains selected models

**Step 4: Clean up**

```bash
cd /Users/tracy/projects/jojo
rm -rf /tmp/jojo-ux-test
```

---

## Validation Checklist

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Provider selection shows numbered menu
- [ ] Model selection shows numbered menus
- [ ] Typing number selects item correctly
- [ ] Arrow keys work for navigation (manual test)
- [ ] Pagination works for long lists (manual test)
- [ ] Documentation updated (README, CHANGELOG)
- [ ] No breaking changes to existing configs
