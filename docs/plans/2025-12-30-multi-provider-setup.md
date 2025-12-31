# Multi-Provider LLM Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable users to choose their LLM provider and models during setup, replacing hardcoded Anthropic assumptions

**Architecture:** Refactor setup flow to use RubyLLM introspection for provider/model discovery. Create `.env.erb` template for dynamic environment variable names. Update config.yml.erb to accept provider/model variables from setup prompts. Pattern designed to support future deepsearch provider integration.

**Tech Stack:** Ruby, RubyLLM 1.9, Thor CLI, Minitest, ERB templates

**Current State:**
- Setup hardcodes Anthropic API key prompt
- `.env` file created with string concatenation (`ANTHROPIC_API_KEY=...`)
- `config.yml.erb` hardcodes `service: anthropic` and models `sonnet`/`haiku`
- `AIClient#configure_ruby_llm` only configures Anthropic

**Target State:**
- Setup prompts for provider choice (11 providers available)
- Setup shows only valid models for chosen provider
- `.env.erb` template uses dynamic env var name
- `config.yml.erb` uses ERB variables for service/model
- `AIClient#configure_ruby_llm` configures all providers dynamically
- Pattern extensible for deepsearch/websearch provider integration

---

## Phase 1: Create .env.erb Template

### Task 1: Create .env.erb template file

**Files:**
- Create: `templates/.env.erb`

**Step 1: Write .env.erb template**

Create template with dynamic environment variable name:

```erb
# LLM Provider Configuration
# Generated during 'jojo setup' - edit this file to change your API key
<%= env_var_name %>=<%= api_key %>

# Optional: Web Search Provider (for company research enhancement)
# Uncomment and configure if using deepsearch gem
# SERPER_API_KEY=your_serper_key_here
```

**Step 2: Verify template exists**

```bash
ls -la templates/.env.erb
```

Expected: File exists with 9 lines

**Step 3: Commit**

```bash
git add templates/.env.erb
git commit -m "feat: add .env.erb template for multi-provider support"
```

---

## Phase 2: Add Provider Selection Helper

### Task 2: Create ProviderHelper module

**Files:**
- Create: `lib/jojo/provider_helper.rb`
- Create: `test/unit/provider_helper_test.rb`

**Step 1: Write failing test for available_providers**

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/provider_helper'

describe Jojo::ProviderHelper do
  describe '.available_providers' do
    it 'returns list of provider slugs from RubyLLM' do
      providers = Jojo::ProviderHelper.available_providers
      _(providers).must_be_kind_of Array
      _(providers).must_include 'anthropic'
      _(providers).must_include 'openai'
      _(providers.length).must_be :>, 5
    end

    it 'returns providers in alphabetical order' do
      providers = Jojo::ProviderHelper.available_providers
      _(providers).must_equal providers.sort
    end
  end
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/provider_helper_test.rb
```

Expected: FAIL with "NameError: uninitialized constant Jojo::ProviderHelper"

**Step 3: Write minimal implementation**

```ruby
require 'ruby_llm'

module Jojo
  module ProviderHelper
    def self.available_providers
      RubyLLM.providers.map(&:slug).sort
    end
  end
end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/provider_helper_test.rb
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/jojo/provider_helper.rb test/unit/provider_helper_test.rb
git commit -m "feat: add ProviderHelper for RubyLLM introspection"
```

### Task 3: Add provider_env_var_name method

**Files:**
- Modify: `lib/jojo/provider_helper.rb`
- Modify: `test/unit/provider_helper_test.rb`

**Step 1: Write failing test**

Add to `test/unit/provider_helper_test.rb`:

```ruby
  describe '.provider_env_var_name' do
    it 'returns uppercase env var name for provider' do
      _(Jojo::ProviderHelper.provider_env_var_name('anthropic')).must_equal 'ANTHROPIC_API_KEY'
      _(Jojo::ProviderHelper.provider_env_var_name('openai')).must_equal 'OPENAI_API_KEY'
    end

    it 'raises error for unknown provider' do
      error = assert_raises(ArgumentError) do
        Jojo::ProviderHelper.provider_env_var_name('unknown_provider')
      end
      _(error.message).must_include 'Unknown provider'
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/provider_helper_test.rb
```

Expected: FAIL with "NoMethodError: undefined method `provider_env_var_name'"

**Step 3: Write implementation**

Add to `lib/jojo/provider_helper.rb`:

```ruby
    def self.provider_env_var_name(provider_slug)
      provider = RubyLLM.providers.find { |p| p.slug == provider_slug }
      raise ArgumentError, "Unknown provider: #{provider_slug}" unless provider

      provider.configuration_requirements.first.to_s.upcase
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/provider_helper_test.rb
```

Expected: PASS (4 tests)

**Step 5: Commit**

```bash
git add lib/jojo/provider_helper.rb test/unit/provider_helper_test.rb
git commit -m "feat: add provider_env_var_name to ProviderHelper"
```

### Task 4: Add available_models method

**Files:**
- Modify: `lib/jojo/provider_helper.rb`
- Modify: `test/unit/provider_helper_test.rb`

**Step 1: Write failing test**

Add to `test/unit/provider_helper_test.rb`:

```ruby
  describe '.available_models' do
    it 'returns models for specified provider' do
      models = Jojo::ProviderHelper.available_models('anthropic')
      _(models).must_be_kind_of Array
      _(models).must_include 'claude-sonnet-4-5'
      _(models).must_include 'claude-3-5-haiku-20241022'
      _(models.all? { |m| m.is_a?(String) }).must_equal true
    end

    it 'returns models in alphabetical order' do
      models = Jojo::ProviderHelper.available_models('anthropic')
      _(models).must_equal models.sort
    end

    it 'returns empty array for provider with no models' do
      # Note: All providers should have models, but test the edge case
      models = Jojo::ProviderHelper.available_models('unknown')
      _(models).must_equal []
    end
  end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/provider_helper_test.rb
```

Expected: FAIL with "NoMethodError: undefined method `available_models'"

**Step 3: Write implementation**

Add to `lib/jojo/provider_helper.rb`:

```ruby
    def self.available_models(provider_slug)
      RubyLLM.models
        .filter { |m| m.provider == provider_slug }
        .map(&:id)
        .sort
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/provider_helper_test.rb
```

Expected: PASS (7 tests)

**Step 5: Commit**

```bash
git add lib/jojo/provider_helper.rb test/unit/provider_helper_test.rb
git commit -m "feat: add available_models to ProviderHelper"
```

---

## Phase 3: Update SetupService for Multi-Provider

### Task 5: Update setup_api_configuration - provider selection

**Files:**
- Modify: `lib/jojo/setup_service.rb:37-68`
- Modify: `test/unit/setup_service_test.rb:28-63`

**Step 1: Update test to expect provider prompt**

Replace test at `test/unit/setup_service_test.rb:46-62` with:

```ruby
    it 'creates .env when missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('templates')
          File.write('templates/.env.erb', '<%= env_var_name %>=<%= api_key %>')

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["Let's configure your API access.", :green]
          cli.expect :ask, 'anthropic', ["Which LLM provider? (#{Jojo::ProviderHelper.available_providers.join(', ')}):"]
          cli.expect :ask, 'sk-ant-test-key', ["Anthropic API key:"]
          cli.expect :say, nil, ["✓ Created .env", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          _(File.exist?('.env')).must_equal true
          _(File.read('.env')).must_include 'ANTHROPIC_API_KEY=sk-ant-test-key'
        end
      end
    end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb
```

Expected: FAIL - test expects provider prompt but doesn't get one

**Step 3: Add require to SetupService**

Add to top of `lib/jojo/setup_service.rb:1`:

```ruby
require 'fileutils'
require 'erb'
require_relative 'provider_helper'
```

**Step 4: Update setup_api_configuration method**

Replace `lib/jojo/setup_service.rb:37-68` with:

```ruby
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

      # Prompt for provider
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

      # Get dynamic env var name
      env_var_name = ProviderHelper.provider_env_var_name(provider_slug)
      provider_display_name = provider_slug.capitalize

      # Prompt for API key
      api_key = @cli.ask("#{provider_display_name} API key:")

      if api_key.strip.empty?
        @cli.say "✗ API key is required", :red
        exit 1
      end

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

      # Store provider for use in setup_personal_configuration
      @provider_slug = provider_slug
    end
```

**Step 5: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_api_configuration/'
```

Expected: PASS (but may need to update other tests in this describe block)

**Step 6: Update skip test**

Update test at `test/unit/setup_service_test.rb:29-44` to work with new structure:

```ruby
    it 'skips when .env exists and not force mode' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('.env', 'ANTHROPIC_API_KEY=existing')

          cli = Minitest::Mock.new
          cli.expect :say, nil, ["✓ .env already exists (skipped)", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.send(:setup_api_configuration)

          cli.verify
          _(File.read('.env')).must_equal 'ANTHROPIC_API_KEY=existing'
        end
      end
    end
```

**Step 7: Run all setup_api_configuration tests**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_api_configuration/'
```

Expected: PASS (2 tests)

**Step 8: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add provider selection to setup_api_configuration"
```

### Task 6: Update setup_personal_configuration - model selection

**Files:**
- Modify: `lib/jojo/setup_service.rb:70-98`
- Modify: `test/unit/setup_service_test.rb:65-102`

**Step 1: Update test to expect model prompts**

Replace test at `test/unit/setup_service_test.rb:82-101` with:

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
          cli.expect :ask, 'claude-sonnet-4-5', ["Which model for reasoning tasks (company research, resume tailoring)?"]
          cli.expect :ask, 'claude-3-5-haiku-20241022', ["Which model for text generation tasks (faster, simpler)?"]
          cli.expect :say, nil, ["✓ Created config.yml", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.instance_variable_set(:@provider_slug, 'anthropic')
          service.send(:setup_personal_configuration)

          cli.verify
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
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_personal_configuration/'
```

Expected: FAIL - test expects model prompts

**Step 3: Update setup_personal_configuration method**

Replace `lib/jojo/setup_service.rb:70-98` with:

```ruby
    def setup_personal_configuration
      if File.exist?('config.yml') && !@force
        @cli.say "✓ config.yml already exists (skipped)", :green
        @skipped_files << 'config.yml'
        return
      end

      # Basic info
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

      # Model selection
      available_models = ProviderHelper.available_models(@provider_slug)

      if available_models.empty?
        @cli.say "✗ No models found for provider: #{@provider_slug}", :red
        exit 1
      end

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

      # Set provider variables for config template
      reasoning_provider = @provider_slug
      text_generation_provider = @provider_slug

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

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_personal_configuration/'
```

Expected: Tests fail because mock expects model list display

**Step 5: Update test to expect model list display**

Update test to add expectations:

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
          cli.expect :say, nil, ["Available models for anthropic:", :cyan]
          cli.expect :say, nil, [String] # Model list
          cli.expect :say, nil, [""]
          cli.expect :ask, 'claude-sonnet-4-5', ["Which model for reasoning tasks (company research, resume tailoring)?"]
          cli.expect :ask, 'claude-3-5-haiku-20241022', ["Which model for text generation tasks (faster, simpler)?"]
          cli.expect :say, nil, ["✓ Created config.yml", :green]

          service = Jojo::SetupService.new(cli_instance: cli, force: false)
          service.instance_variable_set(:@provider_slug, 'anthropic')
          service.send(:setup_personal_configuration)

          cli.verify
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

**Step 6: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/setup_personal_configuration/'
```

Expected: PASS (2 tests)

**Step 7: Commit**

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: add model selection to setup_personal_configuration"
```

---

## Phase 4: Update Templates

### Task 7: Update config.yml.erb template

**Files:**
- Modify: `templates/config.yml.erb`

**Step 1: Update template with ERB variables**

Replace `templates/config.yml.erb` with:

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

# Website configuration
website:
  cta_text: "Schedule a Call"
  cta_link: "https://calendly.com/yourname/30min"  # or mailto:you@email.com
```

**Step 2: Verify template syntax**

```bash
ruby -rerb -e "ERB.new(File.read('templates/config.yml.erb')).result(binding)" 2>&1 | head
```

Expected: No syntax errors (will fail on unbound variables, which is expected)

**Step 3: Commit**

```bash
git add templates/config.yml.erb
git commit -m "feat: update config.yml.erb for multi-provider support"
```

---

## Phase 5: Update AIClient for Dynamic Configuration

### Task 8: Update AIClient to configure all providers

**Files:**
- Modify: `lib/jojo/ai_client.rb:42-46`
- Create: `test/unit/ai_client_test.rb`

**Step 1: Write test for dynamic provider configuration**

Create `test/unit/ai_client_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/ai_client'
require_relative '../../lib/jojo/config'

describe Jojo::AIClient do
  describe '#initialize' do
    it 'configures ruby_llm with anthropic provider' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', <<~YAML)
            seeker_name: Test User
            base_url: https://example.com
            reasoning_ai:
              service: anthropic
              model: claude-sonnet-4-5
            text_generation_ai:
              service: anthropic
              model: claude-3-5-haiku-20241022
          YAML

          ENV['ANTHROPIC_API_KEY'] = 'test-key'

          config = Jojo::Config.new('config.yml')
          client = Jojo::AIClient.new(config)

          # Verify RubyLLM was configured
          _(RubyLLM.configuration.anthropic_api_key).must_equal 'test-key'
        ensure
          ENV.delete('ANTHROPIC_API_KEY')
        end
      end
    end

    it 'configures ruby_llm with openai provider' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('config.yml', <<~YAML)
            seeker_name: Test User
            base_url: https://example.com
            reasoning_ai:
              service: openai
              model: gpt-4o
            text_generation_ai:
              service: openai
              model: gpt-4o-mini
          YAML

          ENV['OPENAI_API_KEY'] = 'test-openai-key'

          config = Jojo::Config.new('config.yml')
          client = Jojo::AIClient.new(config)

          # Verify RubyLLM was configured
          _(RubyLLM.configuration.openai_api_key).must_equal 'test-openai-key'
        ensure
          ENV.delete('OPENAI_API_KEY')
        end
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/ai_client_test.rb
```

Expected: FAIL - openai test fails because configure_ruby_llm only sets anthropic

**Step 3: Update configure_ruby_llm method**

Replace `lib/jojo/ai_client.rb:42-46` with:

```ruby
    def configure_ruby_llm
      RubyLLM.configure do |ruby_llm_config|
        # Configure all providers that might be used
        # RubyLLM only requires the API key for the provider being used
        ruby_llm_config.anthropic_api_key = ENV['ANTHROPIC_API_KEY'] if ENV['ANTHROPIC_API_KEY']
        ruby_llm_config.openai_api_key = ENV['OPENAI_API_KEY'] if ENV['OPENAI_API_KEY']
        ruby_llm_config.deepseek_api_key = ENV['DEEPSEEK_API_KEY'] if ENV['DEEPSEEK_API_KEY']
        ruby_llm_config.gemini_api_key = ENV['GEMINI_API_KEY'] if ENV['GEMINI_API_KEY']
        ruby_llm_config.mistral_api_key = ENV['MISTRAL_API_KEY'] if ENV['MISTRAL_API_KEY']
        ruby_llm_config.openrouter_api_key = ENV['OPENROUTER_API_KEY'] if ENV['OPENROUTER_API_KEY']
        ruby_llm_config.perplexity_api_key = ENV['PERPLEXITY_API_KEY'] if ENV['PERPLEXITY_API_KEY']
        # Note: bedrock, ollama, vertexai, gpustack have different config requirements
      end
    end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/ai_client_test.rb
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/jojo/ai_client.rb test/unit/ai_client_test.rb
git commit -m "feat: configure RubyLLM for all API-key-based providers"
```

---

## Phase 6: Integration Testing

### Task 9: Add integration test for full setup flow

**Files:**
- Create: `test/integration/setup_integration_test.rb`

**Step 1: Create integration test**

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/setup_service'

describe 'Setup Integration' do
  it 'completes full setup flow with anthropic provider' do
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

        # warn_if_force_mode (skipped - not in force mode)

        # setup_api_configuration
        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :ask, 'anthropic', [/Which LLM provider/]
        cli.expect :ask, 'sk-ant-test123', ["Anthropic API key:"]
        cli.expect :say, nil, ["✓ Created .env", :green]

        # setup_personal_configuration
        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Available models for anthropic:", :cyan]
        cli.expect :say, nil, [String] # model list
        cli.expect :say, nil, [""]
        cli.expect :ask, 'claude-sonnet-4-5', [/Which model for reasoning/]
        cli.expect :ask, 'claude-3-5-haiku-20241022', [/Which model for text generation/]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        # setup_input_files
        cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setting up your profile templates...", :green]
        3.times { cli.expect :say, nil, [String, :green] }

        # show_summary
        8.times { cli.expect :say, nil, [String] }
        5.times { cli.expect :say, nil, [String, :cyan] }

        service = Jojo::SetupService.new(cli_instance: cli, force: false)
        service.run

        cli.verify

        # Verify .env
        _(File.exist?('.env')).must_equal true
        env_content = File.read('.env')
        _(env_content).must_include 'ANTHROPIC_API_KEY=sk-ant-test123'

        # Verify config.yml
        _(File.exist?('config.yml')).must_equal true
        config_content = File.read('config.yml')
        _(config_content).must_include 'seeker_name: Test User'
        _(config_content).must_include 'service: anthropic'
        _(config_content).must_include 'model: claude-sonnet-4-5'
        _(config_content).must_include 'model: claude-3-5-haiku-20241022'

        # Verify input files
        _(File.exist?('inputs/generic_resume.md')).must_equal true
        _(File.exist?('inputs/recommendations.md')).must_equal true
        _(File.exist?('inputs/projects.yml')).must_equal true
      end
    end
  end

  it 'completes full setup flow with openai provider' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup template files (same as above)
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

        cli.expect :say, nil, ["Setting up Jojo...", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Let's configure your API access.", :green]
        cli.expect :ask, 'openai', [/Which LLM provider/]
        cli.expect :ask, 'sk-test-openai', ["Openai API key:"]
        cli.expect :say, nil, ["✓ Created .env", :green]

        cli.expect :ask, 'Test User', ["Your name:"]
        cli.expect :ask, 'https://test.com', [/Your website base URL/]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Available models for openai:", :cyan]
        cli.expect :say, nil, [String]
        cli.expect :say, nil, [""]
        cli.expect :ask, 'gpt-4o', [/Which model for reasoning/]
        cli.expect :ask, 'gpt-4o-mini', [/Which model for text generation/]
        cli.expect :say, nil, ["✓ Created config.yml", :green]

        cli.expect :say, nil, ["✓ inputs/ directory ready", :green]
        cli.expect :say, nil, [""]
        cli.expect :say, nil, ["Setting up your profile templates...", :green]
        3.times { cli.expect :say, nil, [String, :green] }

        8.times { cli.expect :say, nil, [String] }
        5.times { cli.expect :say, nil, [String, :cyan] }

        service = Jojo::SetupService.new(cli_instance: cli, force: false)
        service.run

        cli.verify

        # Verify .env
        env_content = File.read('.env')
        _(env_content).must_include 'OPENAI_API_KEY=sk-test-openai'

        # Verify config.yml
        config_content = File.read('config.yml')
        _(config_content).must_include 'service: openai'
        _(config_content).must_include 'model: gpt-4o'
        _(config_content).must_include 'model: gpt-4o-mini'
      end
    end
  end
end
```

**Step 2: Run test**

```bash
ruby -Ilib:test test/integration/setup_integration_test.rb
```

Expected: PASS (2 tests) - full end-to-end flow works

**Step 3: Commit**

```bash
git add test/integration/setup_integration_test.rb
git commit -m "test: add integration tests for multi-provider setup"
```

---

## Phase 7: Update Existing Tests

### Task 10: Update all existing tests to work with new setup flow

**Files:**
- Modify: `test/unit/setup_service_test.rb`

**Step 1: Update warn_if_force_mode tests**

The tests at lines 228-260 should still pass. Run to verify:

```bash
ruby -Ilib:test test/unit/setup_service_test.rb -n '/warn_if_force_mode/'
```

Expected: PASS (3 tests)

**Step 2: Update show_summary test**

Test at line 183 needs mock expectations updated for new file descriptions. Update:

```ruby
    it 'displays created files and next steps' do
      cli = Minitest::Mock.new
      service = Jojo::SetupService.new(cli_instance: cli)
      service.instance_variable_set(:@created_files, ['.env', 'config.yml', 'inputs/generic_resume.md'])

      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["Setup complete!", :green]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["Created:"]
      3.times { cli.expect :say, nil, [String] }
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["Next steps:", :cyan]
      cli.expect :say, nil, ["  1. Customize inputs/generic_resume.md with your actual experience"]
      cli.expect :say, nil, ["  2. Edit or delete inputs/recommendations.md and inputs/projects.yml if not needed"]
      cli.expect :say, nil, ["  3. Run 'jojo new -s <slug> -j <job-file>' to start your first application"]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["💡 Tip: Delete the first comment line in each file after customizing."]

      service.send(:show_summary)

      cli.verify
    end
```

**Step 3: Run all setup_service tests**

```bash
ruby -Ilib:test test/unit/setup_service_test.rb
```

Expected: PASS (all tests)

**Step 4: Commit**

```bash
git add test/unit/setup_service_test.rb
git commit -m "test: update setup_service tests for multi-provider"
```

---

## Phase 8: Documentation

### Task 11: Update CHANGELOG

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add entry to CHANGELOG**

Add at top of `CHANGELOG.md` (after `# Changelog` header):

```markdown
## [Unreleased]

### Changed
- **BREAKING**: Setup now prompts for LLM provider selection instead of assuming Anthropic
- Setup prompts for reasoning and text generation models for chosen provider
- `.env` file now uses provider-specific environment variable names (e.g., `OPENAI_API_KEY` for OpenAI)
- `config.yml` now includes provider-specific service and model configurations

### Added
- Support for 11 LLM providers via RubyLLM (anthropic, bedrock, deepseek, gemini, gpustack, mistral, ollama, openai, openrouter, perplexity, vertexai)
- `ProviderHelper` module for RubyLLM provider/model introspection
- `.env.erb` template for dynamic environment variable generation
- Multi-provider AI client configuration

### Migration Guide
If you have an existing Jojo installation with Anthropic:
1. Your existing `.env` and `config.yml` will continue to work
2. To switch providers, run `jojo setup --force` and select new provider
3. Or manually edit `.env` to use provider-specific key (e.g., `OPENAI_API_KEY`)
4. And edit `config.yml` to update `service:` and `model:` fields
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for multi-provider support"
```

### Task 12: Update README

**Files:**
- Modify: `README.md`

**Step 1: Find setup documentation section**

```bash
grep -n "## Setup" README.md
```

**Step 2: Update setup instructions**

Update the setup section to mention provider choice:

```markdown
## Setup

Run the interactive setup wizard:

```bash
jojo setup
```

The setup wizard will guide you through:
1. **LLM Provider Selection**: Choose from 11 supported providers (Anthropic, OpenAI, DeepSeek, Gemini, Mistral, etc.)
2. **API Key Configuration**: Provide your API key for the chosen provider
3. **Model Selection**: Choose models for reasoning tasks and text generation
4. **Personal Information**: Your name and website URL
5. **Template Files**: Creates resume, recommendations, and projects templates

This creates:
- `.env` - API key configuration
- `config.yml` - Personal preferences and model selections
- `inputs/` - Template files for your resume and optional content
```

**Step 3: Add provider support section**

Add new section after setup:

```markdown
## Supported LLM Providers

Jojo supports the following LLM providers via [RubyLLM](https://github.com/alexrudall/ruby_llm):

- **Anthropic** (Claude models)
- **OpenAI** (GPT models)
- **DeepSeek**
- **Google Gemini**
- **Mistral**
- **OpenRouter**
- **Perplexity**
- **Ollama** (local models)
- **AWS Bedrock**
- **Google Vertex AI**
- **GPUStack**

To switch providers, run `jojo setup --force` or manually edit your `config.yml` and `.env` files.
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: update README for multi-provider support"
```

---

## Phase 9: Validation and Cleanup

### Task 13: Run full test suite

**Step 1: Run all tests**

```bash
ruby -Ilib:test:test/fixtures -e 'Dir.glob("test/**/*_test.rb").each { |f| require_relative f }'
```

Expected: All tests PASS

**Step 2: If any tests fail, fix them**

Review failures and update tests to work with new multi-provider setup.

**Step 3: Run specific test commands from project**

```bash
./bin/jojo test
```

Expected: All tests PASS

**Step 4: Commit any fixes**

```bash
git add test/
git commit -m "test: fix remaining test failures for multi-provider"
```

### Task 14: Manual smoke test

**Step 1: Run setup in a test directory**

```bash
mkdir -p /tmp/jojo-test
cd /tmp/jojo-test
export JOJO_EMPLOYER_SLUG=test-smoke
/Users/tracy/projects/jojo/bin/jojo setup
```

**Step 2: Test with Anthropic**

- Select `anthropic` provider
- Enter test API key `sk-ant-test-key-123`
- Select `claude-sonnet-4-5` for reasoning
- Select `claude-3-5-haiku-20241022` for text generation
- Enter name and URL

**Step 3: Verify files created**

```bash
cat .env
cat config.yml
ls -la inputs/
```

Expected:
- `.env` contains `ANTHROPIC_API_KEY=sk-ant-test-key-123`
- `config.yml` contains `service: anthropic` and chosen models
- `inputs/` contains 3 template files

**Step 4: Test force mode with different provider**

```bash
/Users/tracy/projects/jojo/bin/jojo setup --force
```

- Select `openai` provider
- Enter test API key `sk-test-openai-456`
- Select models

**Step 5: Verify files updated**

```bash
cat .env
cat config.yml
```

Expected:
- `.env` contains `OPENAI_API_KEY=sk-test-openai-456`
- `config.yml` contains `service: openai` and new models

**Step 6: Clean up**

```bash
cd /Users/tracy/projects/jojo
rm -rf /tmp/jojo-test
```

### Task 15: Final commit and summary

**Step 1: Review all changes**

```bash
git log --oneline HEAD~15..HEAD
git diff main...HEAD
```

**Step 2: Ensure all files committed**

```bash
git status
```

Expected: Working tree clean

**Step 3: Create summary commit (if needed)**

```bash
git commit --allow-empty -m "feat: complete multi-provider LLM setup implementation

- Add provider selection to setup wizard
- Support 11 LLM providers via RubyLLM
- Create .env.erb template for dynamic env vars
- Update config.yml.erb for provider/model variables
- Add ProviderHelper for RubyLLM introspection
- Update AIClient to configure all providers
- Add comprehensive test coverage
- Update documentation"
```

---

## Future Extensibility: DeepSearch Provider Pattern

When implementing deepsearch provider support, follow this pattern:

1. **Add web search provider prompts** to SetupService (similar to LLM provider)
2. **Extend .env.erb template** with search provider env vars:
   ```erb
   # Web Search Provider (optional)
   <% if search_env_var_name %>
   <%= search_env_var_name %>=<%= search_api_key %>
   <% end %>
   ```
3. **Create SearchProviderHelper** (mirror of ProviderHelper)
4. **Update config.yml.erb** with search provider configuration:
   ```erb
   # Optional: Web search for company research
   <% if search_provider %>
   search_provider:
     service: <%= search_provider %>
   <% end %>
   ```
5. **Update Config class** to read search_provider config
6. **Update deepsearch integration** to use dynamic provider

This keeps setup as single source of truth for all provider configurations.

---

## Validation Checklist

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Setup wizard prompts for provider
- [ ] Setup wizard prompts for models
- [ ] `.env` created with correct provider env var name
- [ ] `config.yml` contains correct provider and models
- [ ] Can switch between providers with `--force`
- [ ] AIClient configures RubyLLM for all providers
- [ ] Documentation updated (README, CHANGELOG)
- [ ] Pattern extensible for deepsearch providers
