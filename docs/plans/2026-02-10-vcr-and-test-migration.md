# VCR, JojoTest Base Class, and Class-Style Test Migration

## Context

Jojo's service tests (`test/service/`) make real API calls and are quarantined behind an interactive cost warning, so they rarely run. The detritus project demonstrates a better pattern: VCR records real API responses once, then replays them for free. Adopting VCR eliminates the need for a separate cost-incurring test tier.

Alongside VCR, we introduce a `JojoTest` base class (like detritus's `DetritusTest`) and migrate all spec-style tests to conventional class-style Minitest with explicit inheritance. This gives us a consistent foundation where every test inherits shared setup (temp directory isolation, VCR access, fixture helpers).

**HTTP layer:** Both jojo and detritus use `ruby_llm`, which uses Faraday over `net/http`. VCR hooks into this via WebMock at the `net/http` level — the same approach detritus uses.

Note: Detritus can be found at /Users/tracy/projects/detritus if needed for reference.

---

## Phase 1: Create JojoTest base class and VCR infrastructure

### 1a. Add VCR + WebMock to Gemfile

**File:** `Gemfile`

Add to the `:test` group:
```ruby
gem "vcr"
gem "webmock"
```

Run `bundle install`.

### 1b. Configure VCR and create JojoTest in test_helper.rb

**File:** `test/test_helper.rb`

After the existing SimpleCov/Minitest requires, add VCR configuration and the base class:

```ruby
require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("cassettes", __dir__)
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV["ANTHROPIC_API_KEY"] }
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }
  config.ignore_localhost = true
end

class JojoTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def with_vcr(cassette_name, &block)
    VCR.use_cassette(cassette_name, &block)
  end

  def write_test_config(overrides = {})
    defaults = {
      "seeker_name" => "Test User",
      "base_url" => "https://example.com",
      "reasoning_ai" => {"service" => "openai", "model" => "gpt-4"},
      "text_generation_ai" => {"service" => "openai", "model" => "gpt-4"}
    }
    File.write("config.yml", defaults.merge(overrides).to_yaml)
  end

  def create_application_fixture(slug, files: {})
    FileUtils.mkdir_p("applications/#{slug}")
    files.each { |name, content| File.write("applications/#{slug}/#{name}", content) }
  end

  def create_inputs_fixture(files: {})
    FileUtils.mkdir_p("inputs")
    files.each { |name, content| File.write("inputs/#{name}", content) }
  end
end
```

Replace `require "minitest/spec"` with `require "minitest/expectations"` (keeps `_(x).must_equal` syntax without the `describe`/`it` DSL).

### 1c. Create cassettes directory

**New file:** `test/cassettes/.gitkeep`

Cassettes are test fixtures and should be committed.

---

## Phase 2: Migrate all spec-style tests to class-style

Migrate all 64 `describe`/`it` files to `class`/`def test_` style inheriting from `JojoTest`. This is a mechanical transformation.

### Conversion rules

| Spec-style | Class-style |
|---|---|
| `describe Foo do` | `class FooTest < JojoTest` |
| `before do` | `def setup; super; ...` |
| `after do` | `def teardown; ...; super` |
| `it "does thing" do` | `def test_does_thing` |
| `include CommandTestHelper` + `setup_temp_project` | Inherit from `JojoTest` (provides the same via `setup`) |

### One describe file = one class

Each test file becomes a single class. Nested `describe` blocks with their own `before` become **private helper methods** called by the tests that need them:

```ruby
# Before (spec-style with nested describes):
describe Jojo::Commands::Branding::Command do
  include CommandTestHelper
  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {...})
    @mock_cli = Minitest::Mock.new
  end
  after { teardown_temp_project }

  describe "guard failures" do
    it "exits when employer not found" do
      @mock_cli.expect(:say, nil, [/not found/, :red])
      ...
    end
  end

  describe "successful execution" do
    before do
      @mock_status_logger = Minitest::Mock.new
      @mock_application = Minitest::Mock.new
      ...
    end
    it "calls generator.generate" do ...
  end
end

# After (class-style, single class):
class BrandingCommandTest < JojoTest
  def setup
    super
    write_test_config
    create_application_fixture("acme-corp", files: {...})
    @mock_cli = Minitest::Mock.new
  end

  # Guard tests — only need @mock_cli from setup
  def test_exits_when_employer_not_found
    @mock_cli.expect(:say, nil, [/not found/, :red])
    ...
  end

  # Success tests — call helper for extra mocks
  def test_calls_generator_generate
    setup_execution_mocks
    @mock_generator.expect(:generate, nil)
    ...
  end

  private

  def setup_execution_mocks
    @mock_status_logger = Minitest::Mock.new
    @mock_application = Minitest::Mock.new
    @mock_ai_client = Minitest::Mock.new
    @mock_generator = Minitest::Mock.new
    @mock_application.expect(:artifacts_exist?, true)
    ...
  end
end
```

The extra mocks created by helper methods don't interfere with tests that don't call them. Unused `Minitest::Mock` objects are inert — they only matter when `.verify` is called.

### Handling assertions

Keep `_(x).must_equal y` expectations as-is during migration. They work in class-style tests with `require "minitest/expectations"`. Converting to `assert_equal` style is a separate future effort.

### Files to migrate

- **~64 spec-style files** across `test/unit/` and `test/integration/` — convert to class-style inheriting `JojoTest`
- **4 class-style files** already using `class FooTest < Minitest::Test` — change superclass to `JojoTest`

### Remove CommandTestHelper

**Delete:** `test/support/command_test_helper.rb` — its functionality is absorbed into `JojoTest`.

**Edit:** `test/test_helper.rb` — remove `require_relative "support/command_test_helper"`.

---

## Phase 3: Migrate service tests to use VCR

### 3a. Convert and move service tests

**`test/service/resume_transformer_service_test.rb`** → **`test/integration/resume_transformer_vcr_test.rb`**

- Convert from spec-style to class-style inheriting `JojoTest`
- Remove `skip "ANTHROPIC_API_KEY not set"` guard
- Wrap each test in `with_vcr("descriptive_cassette_name")`

**`test/service/job_description_processor_test.rb`** → **`test/integration/job_description_processor_vcr_test.rb`**

- Same conversion (currently has no implemented tests; VCR unblocks the URL processing tests noted in the file)

### 3b. Record cassettes

One-time process:
1. Ensure `ANTHROPIC_API_KEY` is set in `.env`
2. Run the migrated tests: `bundle exec ruby -Ilib:test test/integration/resume_transformer_vcr_test.rb`
3. VCR records responses to `test/cassettes/`
4. Verify cassettes don't contain real API keys (check for `<ANTHROPIC_API_KEY>` placeholder)
5. Commit cassettes

### 3c. Simplify Rakefile

**File:** `Rakefile`

- Remove `test:service` task (with its interactive cost warning)
- Remove service glob from `test:minitest`
- Delete `test/service/` directory

---

## Commits

Three separate commits matching the phases:

1. **`feat: add JojoTest base class with VCR infrastructure`** — Phase 1
2. **`refactor: migrate all tests from spec-style to class-style`** — Phase 2
3. **`feat: convert service tests to VCR, eliminate cost-incurring test tier`** — Phase 3

---

## Verification

1. After Phase 1: `./bin/test` passes (no behavior change yet)
2. After Phase 2: `./bin/test` passes with all tests converted; no `describe`/`it` usage remains
3. After Phase 3:
   - `./bin/test` runs everything including former service tests
   - Unset `ANTHROPIC_API_KEY` and run again — still passes (replaying from cassettes)
   - `grep -r "ANTHROPIC_API_KEY" test/cassettes/` shows only the `<ANTHROPIC_API_KEY>` placeholder
   - `bundle exec standardrb` passes
