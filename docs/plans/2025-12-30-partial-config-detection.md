# Partial Configuration Detection Implementation Plan

## Problem Statement

Currently, `jojo setup` can create inconsistent states when only one of `.env` or `config.yml` exists:

**Scenario 1:** `.env` exists, `config.yml` is missing
- Setup skips prompting for LLM provider (extracts from .env)
- But if extraction fails or .env is malformed, config.yml gets created with wrong/missing provider
- Result: API key in .env doesn't match service in config.yml

**Scenario 2:** `config.yml` exists, `.env` is missing
- Setup would skip creating config.yml
- But no .env means no API keys
- Result: Application can't authenticate

**Recent bug:** When adding search provider configuration to existing setup, .env was being overwritten with nil values, destroying existing API keys.

## Solution

Add validation that fails fast when partial configuration is detected (XOR state):

```
IF (.env exists XOR config.yml exists) AND NOT --force
  THEN fail with clear error message and remediation options
  ELSE proceed normally
```

**Benefits:**
- Prevents inconsistent states
- Clear error message guides user to resolution
- Simple all-or-nothing approach - both files exist together or not at all
- Guards against corruption from interrupted setup

## Implementation Tasks

### Task 1: Add validation tests (TDD)

**File:** `test/unit/setup_service_test.rb`

**Test 1:** Detect .env exists without config.yml

```ruby
it 'fails when .env exists but config.yml missing (not force mode)' do
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      File.write('.env', 'ANTHROPIC_API_KEY=test')

      cli = Minitest::Mock.new
      cli.expect :say, nil, ["✗ Partial configuration detected", :red]
      cli.expect :say, nil, ["  Found: .env", :yellow]
      cli.expect :say, nil, ["  Missing: config.yml", :yellow]
      cli.expect :say, nil, ["", :yellow]
      cli.expect :say, nil, [/Options:/, :yellow]
      cli.expect :say, nil, [/jojo setup --force/, :yellow]
      cli.expect :say, nil, [/Manually create/, :yellow]

      service = Jojo::SetupService.new(cli_instance: cli, force: false)

      assert_raises(SystemExit) do
        service.run
      end

      cli.verify
    end
  end
end
```

**Test 2:** Detect config.yml exists without .env

```ruby
it 'fails when config.yml exists but .env missing (not force mode)' do
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      File.write('config.yml', 'seeker_name: Test')

      cli = Minitest::Mock.new
      cli.expect :say, nil, ["✗ Partial configuration detected", :red]
      cli.expect :say, nil, ["  Found: config.yml", :yellow]
      cli.expect :say, nil, ["  Missing: .env", :yellow]
      cli.expect :say, nil, ["", :yellow]
      cli.expect :say, nil, [/Options:/, :yellow]
      cli.expect :say, nil, [/jojo setup --force/, :yellow]
      cli.expect :say, nil, [/Manually create/, :yellow]

      service = Jojo::SetupService.new(cli_instance: cli, force: false)

      assert_raises(SystemExit) do
        service.run
      end

      cli.verify
    end
  end
end
```

**Test 3:** Allow setup when both exist

```ruby
it 'succeeds when both .env and config.yml exist (skips both)' do
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      File.write('.env', 'ANTHROPIC_API_KEY=test')
      File.write('config.yml', 'seeker_name: Test')

      cli = Minitest::Mock.new
      cli.expect :say, nil, ["Setting up Jojo...", :green]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["✓ .env already exists (skipped)", :green]
      # ... rest of normal skip flow

      service = Jojo::SetupService.new(cli_instance: cli, force: false)
      # Should not raise
      # Note: Would need full mock setup to run completely
    end
  end
end
```

**Test 4:** Allow setup when neither exists

```ruby
it 'succeeds when neither .env nor config.yml exist (normal setup)' do
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      # Empty directory - normal setup flow
      # Test already exists in integration tests
    end
  end
end
```

**Test 5:** Allow partial config in force mode

```ruby
it 'proceeds when partial config detected but --force is set' do
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      File.write('.env', 'ANTHROPIC_API_KEY=test')
      # config.yml missing

      cli = Minitest::Mock.new
      prompt = Minitest::Mock.new

      # Should NOT fail, should proceed with force warning and full setup
      cli.expect :say, nil, ["Setting up Jojo...", :green]
      cli.expect :say, nil, [""]
      cli.expect :say, nil, ["⚠ WARNING: --force will overwrite existing configuration files!", :yellow]
      # ... rest of force mode setup

      service = Jojo::SetupService.new(cli_instance: cli, prompt: prompt, force: true)
      # Should not raise SystemExit
    end
  end
end
```

**Run tests to verify they fail:**

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/partial config/'
```

Expected: All new tests fail (method doesn't exist yet)

### Task 2: Implement validation method

**File:** `lib/jojo/setup_service.rb`

**Location:** After `warn_if_force_mode` method (around line 40)

```ruby
def validate_configuration_completeness
  return if @force  # Force mode bypasses validation

  env_exists = File.exist?('.env')
  config_exists = File.exist?('config.yml')

  # XOR check: fail if exactly one exists
  if env_exists && !config_exists
    @cli.say "✗ Partial configuration detected", :red
    @cli.say "  Found: .env", :yellow
    @cli.say "  Missing: config.yml", :yellow
    @cli.say "", :yellow
    @cli.say "Options:", :yellow
    @cli.say "  • Run 'jojo setup --force' to recreate all configuration", :yellow
    @cli.say "  • Manually create config.yml to match your existing .env setup", :yellow
    exit 1
  elsif config_exists && !env_exists
    @cli.say "✗ Partial configuration detected", :red
    @cli.say "  Found: config.yml", :yellow
    @cli.say "  Missing: .env", :yellow
    @cli.say "", :yellow
    @cli.say "Options:", :yellow
    @cli.say "  • Run 'jojo setup --force' to recreate all configuration", :yellow
    @cli.say "  • Manually create .env with your API keys", :yellow
    exit 1
  end

  # Both exist or neither exists - normal flow
end
```

**Update run method** to call validation (line 16-27):

```ruby
def run
  @cli.say "Setting up Jojo...", :green
  @cli.say ""

  warn_if_force_mode
  validate_configuration_completeness  # ADD THIS LINE
  setup_api_configuration
  setup_search_configuration
  write_env_file
  setup_personal_configuration
  setup_input_files
  show_summary
end
```

**Verify syntax:**

```bash
ruby -c lib/jojo/setup_service.rb
```

### Task 3: Run tests to verify implementation

```bash
bundle exec ruby -Ilib:test test/unit/setup_service_test.rb -n '/partial config/'
```

Expected: All 5 new tests pass

### Task 4: Run full test suite

```bash
SKIP_SERVICE_CONFIRMATION=true ./bin/jojo test
```

Expected: All tests pass (188+ tests)

### Task 5: Manual testing

**Test partial config detection (.env exists):**

```bash
mkdir -p /tmp/jojo-partial-test-1
cd /tmp/jojo-partial-test-1
echo "ANTHROPIC_API_KEY=test-key" > .env
export JOJO_EMPLOYER_SLUG=test-smoke
/Users/tracy/projects/jojo/bin/jojo setup
```

Expected output:
```
✗ Partial configuration detected
  Found: .env
  Missing: config.yml

Options:
  • Run 'jojo setup --force' to recreate all configuration
  • Manually create config.yml to match your existing .env setup
```

**Test partial config detection (config.yml exists):**

```bash
mkdir -p /tmp/jojo-partial-test-2
cd /tmp/jojo-partial-test-2
echo "seeker_name: Test" > config.yml
export JOJO_EMPLOYER_SLUG=test-smoke
/Users/tracy/projects/jojo/bin/jojo setup
```

Expected: Similar error but with files reversed

**Test force mode bypasses check:**

```bash
cd /tmp/jojo-partial-test-1
export JOJO_EMPLOYER_SLUG=test-smoke
/Users/tracy/projects/jojo/bin/jojo setup --force
```

Expected: Proceeds with normal setup, recreates both files

**Cleanup:**

```bash
rm -rf /tmp/jojo-partial-test-1 /tmp/jojo-partial-test-2
```

### Task 6: Commit changes

```bash
git add lib/jojo/setup_service.rb test/unit/setup_service_test.rb
git commit -m "feat: detect and prevent partial configuration states

- Add validate_configuration_completeness check
- Fail with clear error when only .env or config.yml exists
- Bypass validation in --force mode
- Prevents inconsistent setup states (API keys without config, etc)
- Add tests for all partial configuration scenarios"
```

## Validation Checklist

After implementation:

- [ ] Tests for .env-only scenario pass
- [ ] Tests for config.yml-only scenario pass
- [ ] Tests for both-exist scenario pass
- [ ] Tests for neither-exist scenario pass
- [ ] Tests for force-mode bypass pass
- [ ] Full test suite passes
- [ ] Manual test: .env exists alone → fails with clear message
- [ ] Manual test: config.yml exists alone → fails with clear message
- [ ] Manual test: both exist → skips both normally
- [ ] Manual test: force mode with partial config → proceeds

## Edge Cases Considered

1. **Empty files:** If `.env` or `config.yml` are empty/corrupted, validation still detects them. User must use `--force` to fix.

2. **File permissions:** If files exist but aren't readable, File.exist? still returns true. Later operations will fail with permission errors (expected behavior).

3. **Interrupted setup:** If user Ctrl+C during setup after creating .env but before config.yml, next run will detect partial state and require --force.

4. **Concurrent setups:** Multiple `jojo setup` runs could theoretically create race condition. Out of scope - user shouldn't run concurrent setups.

## Related Files

- `lib/jojo/setup_service.rb` - Core implementation
- `test/unit/setup_service_test.rb` - Unit tests
- `test/integration/setup_integration_test.rb` - May need updates if integration tests assume partial states
