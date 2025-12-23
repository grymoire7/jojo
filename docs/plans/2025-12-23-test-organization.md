# Test Organization Implementation Plan

**Date:** 2025-12-23

**Goal:** Reorganize test suite using directory structure to separate unit, integration, and service tests, with corresponding CLI flags for selective test execution.

**Architecture:** Move all tests into categorized directories (`test/unit/`, `test/integration/`, `test/service/`), update test command to support multiple flags (`--unit`, `--integration`, `--service`, `--all`), default to `--unit` for fast TDD cycle.

**Decision Rule:** If test calls a real external service → `test/service/`, mocked external calls → `test/integration/` or `test/unit/`, pure unit logic → `test/unit/`.

---

## Task 1: Create Directory Structure

**Files:**
- Create: `test/unit/` directory
- Create: `test/integration/` directory
- Create: `test/service/` directory
- Create: `test/unit/generators/` directory
- Create: `test/unit/prompts/` directory

### Step 1: Create directories

```bash
mkdir -p test/unit/generators
mkdir -p test/unit/prompts
mkdir -p test/integration
mkdir -p test/service
```

### Step 2: Verify structure

```bash
tree test/
```

Expected output:
```
test/
├── fixtures/
├── integration/
├── service/
├── test_helper.rb
└── unit/
    ├── generators/
    └── prompts/
```

### Step 3: Commit

```bash
git add test/
git commit -m "chore: create test directory structure for organization"
```

---

## Task 2: Move Existing Tests to Unit Directory

**Files:**
- Move: `test/cli_test.rb` → `test/unit/cli_test.rb`
- Move: `test/config_test.rb` → `test/unit/config_test.rb`
- Move: `test/employer_test.rb` → `test/unit/employer_test.rb`
- Move: `test/status_logger_test.rb` → `test/unit/status_logger_test.rb`
- Move: `test/job_description_processor_test.rb` → `test/unit/job_description_processor_test.rb`
- Move: `test/generators/research_generator_test.rb` → `test/unit/generators/research_generator_test.rb`
- Move: `test/prompts/research_prompt_test.rb` → `test/unit/prompts/research_prompt_test.rb`

### Step 1: Move test files

```bash
git mv test/cli_test.rb test/unit/cli_test.rb
git mv test/config_test.rb test/unit/config_test.rb
git mv test/employer_test.rb test/unit/employer_test.rb
git mv test/status_logger_test.rb test/unit/status_logger_test.rb
git mv test/job_description_processor_test.rb test/unit/job_description_processor_test.rb
git mv test/generators/research_generator_test.rb test/unit/generators/research_generator_test.rb
git mv test/prompts/research_prompt_test.rb test/unit/prompts/research_prompt_test.rb
```

### Step 2: Remove empty directories

```bash
rmdir test/generators
rmdir test/prompts
```

### Step 3: Verify tests still run

Run: `ruby -Ilib:test -e 'Dir.glob("test/unit/**/*_test.rb").each { |f| require f.sub(/^test\//, "") }'`

Expected: All tests pass

### Step 4: Commit

```bash
git add test/
git commit -m "chore: move all tests to test/unit/ directory"
```

---

## Task 3: Update Test Command with Category Flags

**Files:**
- Modify: `lib/jojo/cli.rb` (test command)

### Step 1: Update test command implementation

Replace the `test` method in `lib/jojo/cli.rb`:

```ruby
desc "test", "Run tests"
method_option :unit, type: :boolean, desc: 'Run unit tests (default)'
method_option :integration, type: :boolean, desc: 'Run integration tests'
method_option :service, type: :boolean, desc: 'Run service tests (may use real APIs)'
method_option :all, type: :boolean, desc: 'Run all tests'
def test
  # Determine which test categories to run
  categories = []

  if options[:all]
    categories = ['unit', 'integration', 'service']
  else
    # Collect specified categories
    categories << 'unit' if options[:unit]
    categories << 'integration' if options[:integration]
    categories << 'service' if options[:service]

    # Default to unit tests if no flags specified
    categories = ['unit'] if categories.empty?
  end

  # Safety confirmation for service tests
  if categories.include?('service') && !ENV['SKIP_SERVICE_CONFIRMATION']
    unless yes?("⚠️  Run service tests? These may cost money and require API keys. Continue? (y/n)")
      # Remove service from categories if user declines
      categories.delete('service')
      # Exit if service was the only category requested
      if categories.empty?
        say "No tests to run.", :yellow
        exit 0
      end
    end
  end

  # Build test file patterns
  patterns = categories.map { |cat| "test/#{cat}/**/*_test.rb" }

  # Build and execute test command
  pattern_glob = patterns.join(',')
  test_cmd = "ruby -Ilib:test -e 'Dir.glob(\"{#{pattern_glob}}\").each { |f| require f.sub(/^test\\//, \"\") }'"

  if options[:quiet]
    exec "#{test_cmd} > /dev/null 2>&1"
  else
    exec test_cmd
  end
end
```

### Step 2: Test each flag individually

Run each command and verify it works:

```bash
./bin/jojo test              # Should run unit tests (default)
./bin/jojo test --unit       # Should run unit tests explicitly
./bin/jojo test --integration # Should run integration tests (none yet, should show 0 tests)
./bin/jojo test --service    # Should prompt for confirmation, then run 0 tests
./bin/jojo test --all        # Should prompt for confirmation, then run all tests
```

### Step 3: Test combining flags

```bash
./bin/jojo test --unit --integration  # Should run both unit and integration tests
```

Expected: Runs tests from both directories

### Step 4: Test with quiet flag

```bash
./bin/jojo test -q
echo "Exit code: $?"
```

Expected: No output, exit code 0

### Step 5: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "feat: add test category flags (--unit, --integration, --service, --all)"
```

---

## Task 4: Update Test Command Help and Documentation

**Files:**
- Modify: `lib/jojo/cli.rb` (add details to test description)
- Modify: `README.md` or create testing documentation

### Step 1: Enhance test command description

Update the test command description in `lib/jojo/cli.rb`:

```ruby
desc "test", "Run tests (default: --unit for fast feedback)"
long_desc <<~DESC
  Run test suite with optional category filtering.

  Categories:
    --unit         Unit tests (fast, no external dependencies) [default]
    --integration  Integration tests (mocked external services)
    --service      Service tests (real API calls, may cost money)
    --all          All test categories

  Examples:
    jojo test                        # Run unit tests only (fast)
    jojo test --all                  # Run all tests
    jojo test --unit --integration   # Run unit and integration tests
    jojo test --service              # Run service tests (with confirmation)
    jojo test -q                     # Quiet mode, check exit code
DESC
```

### Step 2: Verify help output

```bash
./bin/jojo help test
```

Expected: Shows enhanced description with examples

### Step 3: Commit

```bash
git add lib/jojo/cli.rb
git commit -m "docs: enhance test command help with category descriptions"
```

---

## Task 5: Add Environment Variable for Service Test Confirmation

**Files:**
- Document: `README.md` or `.env.example`

### Step 1: Document SKIP_SERVICE_CONFIRMATION

Add to `.env.example` or document in README:

```bash
# Skip confirmation prompt when running service tests
# Useful for CI environments
# SKIP_SERVICE_CONFIRMATION=true
```

### Step 2: Test skipping confirmation

```bash
SKIP_SERVICE_CONFIRMATION=true ./bin/jojo test --service
```

Expected: Runs service tests without prompting

### Step 3: Commit documentation

```bash
git add .env.example
git commit -m "docs: document SKIP_SERVICE_CONFIRMATION env var"
```

---

## Task 6: Update Implementation Plan

**Files:**
- Modify: `docs/plans/implementation_plan.md`

### Step 1: Add test organization section

Add after Phase 3 or in the Testing Strategy section:

```markdown
## Test Organization

**Structure**: Tests are organized by category in separate directories:

- `test/unit/` - Fast unit tests with no external dependencies (default)
- `test/integration/` - Integration tests with mocked external services
- `test/service/` - Tests that call real external APIs (Serper, OpenAI, etc.)

**Running Tests**:

```bash
./bin/jojo test                       # Unit tests only (fast, default)
./bin/jojo test --all                 # All test categories
./bin/jojo test --unit --integration  # Multiple categories
./bin/jojo test --service             # Service tests (confirmation required)
./bin/jojo test -q                    # Quiet mode
```

**Decision Rule**:
- Real external service call → `test/service/`
- Mocked external service → `test/integration/` or `test/unit/`
- Pure unit logic → `test/unit/`
```

### Step 2: Commit

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: document test organization structure"
```

---

## Validation

Run all validation steps:

### 1. Verify directory structure

```bash
tree test/ -L 2
```

Expected:
```
test/
├── fixtures/
│   ├── generic_resume.md
│   ├── invalid_config.yml
│   └── valid_config.yml
├── integration/
├── service/
├── test_helper.rb
└── unit/
    ├── cli_test.rb
    ├── config_test.rb
    ├── employer_test.rb
    ├── generators/
    ├── job_description_processor_test.rb
    ├── prompts/
    └── status_logger_test.rb
```

### 2. Verify default behavior

```bash
./bin/jojo test
```

Expected: Runs 43 unit tests, all pass

### 3. Verify all tests run with --all

```bash
./bin/jojo test --all
```

Expected: Prompts for confirmation, runs all 43 tests

### 4. Verify combining flags

```bash
./bin/jojo test --unit --integration
```

Expected: Runs unit tests (integration is empty, 0 tests from there)

### 5. Verify quiet mode still works

```bash
./bin/jojo test -q
echo $?
```

Expected: No output, exit code 0

### 6. Verify help

```bash
./bin/jojo help test
```

Expected: Shows enhanced help with category descriptions and examples

---

## Notes

- All existing tests are unit tests (fast, no external dependencies)
- `test/integration/` and `test/service/` are empty initially
- Future tests requiring real API calls go in `test/service/`
- Future tests with mocked APIs go in `test/integration/`
- The skipped URL processing test from `job_description_processor_test.rb` will be moved to `test/service/` in a future task when properly implemented
- Service test confirmation can be skipped with `SKIP_SERVICE_CONFIRMATION=true` (useful for CI)
- Default behavior (`./bin/jojo test`) optimizes for fast TDD cycle
