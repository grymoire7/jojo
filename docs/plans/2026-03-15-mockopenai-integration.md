# MockOpenAI Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `start_test_server!` / `server_url` / `wait_until_ready` to MockOpenAI, then replace jojo's VCR/WebMock test infrastructure with MockOpenAI.

**Architecture:** Part 1 (MockOpenAI project) adds three public APIs with tests and doc updates. Part 2 (jojo project) bumps `ruby_llm` to 1.13 (which adds `anthropic_api_base` config support), replaces VCR/WebMock with MockOpenAI, and rewrites 5 integration tests to use `MockOpenAI.set_responses`. The two parts are independent commits in different repos; do Part 1 first.

**Tech Stack:** Ruby, Rack/WEBrick, TCPSocket, RSpec (MockOpenAI tests), Minitest (jojo tests), ruby_llm 1.13, MockOpenAI path gem (`../mockopenai`)

---

## Chunk 1: MockOpenAI additions

### Task 1: Add `Server.wait_until_ready`

**Project:** `/Users/tracy/projects/mockopenai`

**Files:**
- Modify: `lib/mock_openai/server.rb`
- Modify: `spec/mock_openai/server_spec.rb`

- [ ] **Step 1: Write failing tests**

Open `spec/mock_openai/server_spec.rb`. Inside `RSpec.describe MockOpenAI::Server do`, add a new `describe ".wait_until_ready"` block after the existing `.start` block:

```ruby
  describe ".wait_until_ready" do
    it "returns without raising when a TCP listener is open on the port" do
      require "socket"
      # Bind to an ephemeral port so we don't collide with anything
      server = TCPServer.new("127.0.0.1", 0)
      port = server.local_address.ip_port
      acceptor = Thread.new { server.accept rescue nil }

      allow(MockOpenAI.config).to receive(:port).and_return(port)
      MockOpenAI::Server.wait_until_ready

      acceptor.kill
      server.close
    end

    it "raises RuntimeError when the port does not open within the timeout" do
      allow(TCPSocket).to receive(:new).and_raise(Errno::ECONNREFUSED)
      expect { MockOpenAI::Server.wait_until_ready(timeout: 0.1) }
        .to raise_error(RuntimeError, /did not start within/)
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd /Users/tracy/projects/mockopenai
bundle exec rspec spec/mock_openai/server_spec.rb --format documentation
```

Expected: `NoMethodError: undefined method 'wait_until_ready' for MockOpenAI::Server`

- [ ] **Step 3: Implement `wait_until_ready` in `lib/mock_openai/server.rb`**

Add `require "socket"` at the top of the file (after existing requires). Then inside `class Server`, add:

```ruby
def self.wait_until_ready(timeout: 5)
  deadline = Time.now + timeout
  loop do
    TCPSocket.new("127.0.0.1", MockOpenAI.config.port).close
    return
  rescue Errno::ECONNREFUSED
    raise "MockOpenAI server did not start within #{timeout}s" if Time.now > deadline
    sleep 0.05
  end
end
```

The full file should look like:

```ruby
# frozen_string_literal: true

require "fileutils"
require "logger"
require "socket"

module MockOpenAI
  class Server
    def self.start(port: MockOpenAI.config.port)
      state_file = MockOpenAI.config.state_file
      FileUtils.mkdir_p(File.dirname(state_file))
      State.reset! unless File.exist?(state_file)

      puts "MockOpenAI v#{VERSION} started"
      puts "  Listening on: http://localhost:#{port}"
      puts "  State file:   #{state_file}"

      config_status = File.exist?("mock_openai.yml") ? "mock_openai.yml" : "mock_openai.yml (not found, using defaults)"
      puts "  Config:       #{config_status}"

      run_rack_server(port: port)
    end

    def self.run_rack_server(port: MockOpenAI.config.port)
      require "rackup"
      Rackup::Server.start(
        app: Router.new,
        Port: port,
        Host: "127.0.0.1",
        server: :webrick,
        Logger: Logger.new($stdout),
        AccessLog: []
      )
    end

    def self.wait_until_ready(timeout: 5)
      deadline = Time.now + timeout
      loop do
        TCPSocket.new("127.0.0.1", MockOpenAI.config.port).close
        return
      rescue Errno::ECONNREFUSED
        raise "MockOpenAI server did not start within #{timeout}s" if Time.now > deadline
        sleep 0.05
      end
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

```
cd /Users/tracy/projects/mockopenai
bundle exec rspec spec/mock_openai/server_spec.rb --format documentation
```

Expected: All 6 server tests pass (4 existing + 2 new).

- [ ] **Step 5: Commit**

```bash
cd /Users/tracy/projects/mockopenai
git add lib/mock_openai/server.rb spec/mock_openai/server_spec.rb
git commit -m "feat: add Server.wait_until_ready"
```

---

### Task 2: Add `MockOpenAI.start_test_server!` and `MockOpenAI.server_url`

**Project:** `/Users/tracy/projects/mockopenai`

**Files:**
- Modify: `lib/mock_openai.rb`
- Modify: `spec/mock_openai_spec.rb`

- [ ] **Step 1: Write failing tests**

Open `spec/mock_openai_spec.rb`. Inside `RSpec.describe MockOpenAI do`, add two new `describe` blocks after the existing ones:

```ruby
  describe ".server_url" do
    it "returns the base URL with the configured port" do
      expect(MockOpenAI.server_url).to eq("http://127.0.0.1:#{MockOpenAI.config.port}")
    end
  end

  describe ".start_test_server!" do
    it "starts a background thread and waits for readiness when port is not open" do
      allow(TCPSocket).to receive(:new).and_raise(Errno::ECONNREFUSED).once
      allow(TCPSocket).to receive(:new).and_return(double(close: nil))
      allow(MockOpenAI::Server).to receive(:start)
      allow(Thread).to receive(:new).and_yield

      expect(MockOpenAI::Server).to receive(:wait_until_ready)
      MockOpenAI.start_test_server!
    end

    it "is a no-op when the port is already open" do
      allow(TCPSocket).to receive(:new).with("127.0.0.1", MockOpenAI.config.port).and_return(double(close: nil))
      expect(Thread).not_to receive(:new)
      MockOpenAI.start_test_server!
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd /Users/tracy/projects/mockopenai
bundle exec rspec spec/mock_openai_spec.rb --format documentation
```

Expected: `NoMethodError: undefined method 'start_test_server!'` and `undefined method 'server_url'`

- [ ] **Step 3: Implement in `lib/mock_openai.rb`**

Add `require "socket"` near the top of `lib/mock_openai.rb` (after `require "json"`). Then in the `class << self` block, add `start_test_server!` and `server_url` with a private `server_reachable?` helper:

```ruby
require "socket"

# ...

module MockOpenAI
  class << self
    def config
      @config ||= Config.load
    end

    def start_test_server!
      return if server_reachable?
      Thread.new { Server.start }
      Server.wait_until_ready
    end

    def server_url
      "http://127.0.0.1:#{config.port}"
    end

    def set_responses(rules)
      State.write(rules: rules.map { |r| r.transform_keys(&:to_s) })
    end

    def set_failure_mode(mode)
      set_responses([{"match" => ".*", "failure_mode" => mode.to_s}])
    end

    def reset!
      State.reset!
    end

    def current_failure_mode
      state = State.read
      catch_all = state["rules"].find { |r| r["match"] == ".*" && r["failure_mode"] }
      catch_all&.dig("failure_mode")&.to_sym
    end

    private

    def server_reachable?
      TCPSocket.new("127.0.0.1", config.port).close
      true
    rescue Errno::ECONNREFUSED
      false
    end
  end
end
```

Note: `private` inside `class << self` makes `server_reachable?` a private singleton method — it can only be called from within the `class << self` block, not as `MockOpenAI.server_reachable?`.

- [ ] **Step 4: Run tests to verify they pass**

```
cd /Users/tracy/projects/mockopenai
bundle exec rspec spec/mock_openai_spec.rb --format documentation
```

Expected: All tests pass including the 3 new ones.

- [ ] **Step 5: Run the full MockOpenAI spec suite**

```
cd /Users/tracy/projects/mockopenai
bundle exec rspec --format documentation
```

Expected: All tests pass with no failures.

- [ ] **Step 6: Commit**

```bash
cd /Users/tracy/projects/mockopenai
git add lib/mock_openai.rb spec/mock_openai_spec.rb
git commit -m "feat: add start_test_server! and server_url"
```

---

### Task 3: Update MockOpenAI documentation

**Project:** `/Users/tracy/projects/mockopenai`

**Files:**
- Modify: `docs/usage/minitest.md`
- Modify: `docs/usage/standalone.md`

No tests — docs only.

- [ ] **Step 1: Update `docs/usage/minitest.md`**

Insert a new "## Starting the test server" section between the existing intro block and "## Failure modes". The full updated file:

```markdown
---
title: Minitest
parent: Usage
nav_order: 5
---

# Minitest

Add `require "mock_openai/minitest"` to `test/test_helper.rb` once, then
include `MockOpenAI::Minitest` in any test class that needs it.

```ruby
# test/test_helper.rb
require "mock_openai/minitest"
```

```ruby
# test/services/my_service_test.rb
class MyChatTest < Minitest::Test
  include MockOpenAI::Minitest

  def test_returns_canned_response
    MockOpenAI.set_responses([{ match: "Hello", response: "Hi!" }])
    assert_equal "Hi!", MyService.call_openai("Hello")
  end
end
```

`MockOpenAI::Minitest` hooks into Minitest's `before_setup` and
`after_teardown` callbacks, so state is reset before and after each test
without interfering with your own `setup` and `teardown` methods.

## Starting the test server

`MockOpenAI::Minitest` resets state between tests but does not start a server.
If your code makes **outbound HTTP connections** to an LLM API — CLI tools,
Rails apps calling the API in integration tests, background jobs — you must
start a server process and point your LLM client at it.

Call `MockOpenAI.start_test_server!` once at the top of `test/test_helper.rb`
and configure your LLM client to use `MockOpenAI.server_url`:

```ruby
# test/test_helper.rb
require "mock_openai/minitest"

MockOpenAI.start_test_server!

RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", "test-key")
  config.anthropic_api_base = MockOpenAI.server_url
end
```

`start_test_server!` is idempotent — calling it more than once is safe. It
blocks until the server is accepting connections.

`start_test_server!` is **not** needed when testing a Rack app directly via
`rack-test` (e.g. in MockOpenAI's own spec suite, where requests go through
the Rack stack in-process without opening a TCP connection).

## Failure modes

There are no shortcut tags in Minitest (unlike RSpec metadata). Set failure
modes explicitly in your test or `setup`:

```ruby
def test_falls_back_on_rate_limit
  MockOpenAI.set_failure_mode(:rate_limit)

  result = SmartService.call("summarize this")

  assert_equal :cache, result[:source]
end
```

Available failure modes: `:timeout`, `:rate_limit`, `:internal_error`,
`:malformed_json`, `:truncated_stream`.
```

- [ ] **Step 2: Update `docs/usage/standalone.md`**

Replace the full file content with:

```markdown
---
title: Standalone Server
parent: Usage
nav_order: 2
---

# Standalone Server

Use the standalone server when your app and tests run in **separate processes** —
for example, Capybara or Playwright tests that drive a full Rails stack over a
real HTTP connection. Start the mock server in a terminal before running your
test suite:

```
mock-openai start
```

Configure your LLM client in `config/environments/test.rb`:

```ruby
OpenAI.configure do |c|
  c.api_base = "http://localhost:4000/v1"
end
```

Tests still control behavior via `MockOpenAI.set_responses` — it writes to
the same shared state file that the server reads on every request.

## Unit and integration tests (same-process)

If your app and tests run in the **same process** — the common case for Rails
unit/integration tests, CLI tools, and plain Ruby projects — use
`MockOpenAI.start_test_server!` in `test_helper.rb` instead. See the
[Minitest](minitest.md) guide.
```

- [ ] **Step 3: Commit**

```bash
cd /Users/tracy/projects/mockopenai
git add docs/usage/minitest.md docs/usage/standalone.md
git commit -m "docs: update minitest and standalone guides for start_test_server!"
```

---

## Chunk 2: Jojo integration

### Task 4: Update Gemfile

**Project:** `/Users/tracy/projects/jojo`

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Make three changes to `Gemfile`**

1. Change `gem "ruby_llm", "~> 1.9"` to `gem "ruby_llm", "~> 1.13"`
2. In `group :test do`, remove `gem "vcr"` and `gem "webmock"`
3. In `group :test do`, add `gem "mockopenai", path: "../mockopenai"`

The `group :test do` block should become:

```ruby
group :test do
  gem "simplecov", require: false
  gem "simplecov_json_formatter", require: false
  gem "mockopenai", path: "../mockopenai"
end
```

- [ ] **Step 2: Install updated dependencies**

```
cd /Users/tracy/projects/jojo
bundle install
```

Expected: `ruby_llm` resolves to `1.13.x`. `mockopenai` is loaded from the path. No `vcr` or `webmock` in the bundle output.

- [ ] **Step 3: Commit**

```bash
cd /Users/tracy/projects/jojo
git add Gemfile Gemfile.lock
git commit -m "chore: bump ruby_llm to 1.13, replace vcr/webmock with mockopenai"
```

---

### Task 5: Update `test/test_helper.rb`

**Project:** `/Users/tracy/projects/jojo`

**Files:**
- Modify: `test/test_helper.rb`

- [ ] **Step 1: Remove VCR/WebMock requires and config**

Remove these lines from `test/test_helper.rb` (lines 44–62 in the current file):

```ruby
require "vcr"
require "webmock"

# Ensure API keys are set so RubyLLM passes config validation
# before making HTTP requests that VCR can intercept
ENV["ANTHROPIC_API_KEY"] ||= "test-key-for-vcr"
ENV["OPENAI_API_KEY"] ||= "test-key-for-vcr"

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
```

- [ ] **Step 2: Add MockOpenAI startup after `require_relative "../lib/jojo"`**

After the `require_relative "../lib/jojo"` line, insert:

```ruby
require "mock_openai/minitest"

MockOpenAI.start_test_server!

RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", "test-key")
  config.anthropic_api_base = MockOpenAI.server_url
end
```

`RubyLLM` must be configured after `lib/jojo` loads (which loads `ruby_llm`).

- [ ] **Step 3: Add `include MockOpenAI::Minitest` to `JojoTest`**

Inside `class JojoTest < Minitest::Test`, add `include MockOpenAI::Minitest` as the first line:

```ruby
class JojoTest < Minitest::Test
  include MockOpenAI::Minitest

  def setup
    # ... rest unchanged
```

- [ ] **Step 4: Remove the `with_vcr` helper**

Remove this method from `JojoTest`:

```ruby
def with_vcr(cassette_name, &block)
  VCR.use_cassette(cassette_name, &block)
end
```

- [ ] **Step 5: Verify `test_helper.rb` looks correct**

The section around `require_relative "../lib/jojo"` should now read:

```ruby
require_relative "../lib/jojo"

require "mock_openai/minitest"

MockOpenAI.start_test_server!

RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", "test-key")
  config.anthropic_api_base = MockOpenAI.server_url
end

# Stub Tailwind CSS builds by default...
```

And `JojoTest` should open with:

```ruby
class JojoTest < Minitest::Test
  include MockOpenAI::Minitest

  def setup
```

- [ ] **Step 6: Commit**

```bash
cd /Users/tracy/projects/jojo
git add test/test_helper.rb
git commit -m "refactor: replace VCR config with MockOpenAI in test_helper"
```

---

### Task 6: Convert VCR integration tests to MockOpenAI

**Project:** `/Users/tracy/projects/jojo`

**Files:**
- Delete: `test/integration/resume_transformer_vcr_test.rb`
- Create: `test/integration/resume_transformer_test.rb`

The five tests map to these mock responses (from the spec):

| Test | MockOpenAI response |
|---|---|
| `test_filter_field_filters_skills_*` | `"[0, 6]"` |
| `test_reorder_field_maintains_all_items_*` | `"[0, 1, 2]"` |
| `test_reorder_field_allows_removal_*` | `"[0, 2, 1, 3, 4]"` |
| `test_rewrite_field_tailors_summary_*` | `"Experienced software engineer with broad technical background across multiple domains"` |
| `test_raises_permission_violation_*` | `"[0, 1, 2]"` — returns only 3 of 5 items, triggering the violation |

`".*"` is a safe catch-all because each test is isolated (state resets before each test via `MockOpenAI::Minitest`) and makes exactly one LLM call.

- [ ] **Step 1: Create `test/integration/resume_transformer_test.rb`**

```ruby
require_relative "../test_helper"
require_relative "../../lib/jojo/commands/resume/transformer"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/config"
require "yaml"

class ResumeTransformerTest < JojoTest
  def setup
    super
    @config = Jojo::Config.new(fixture_path("valid_config.yml"))
    @ai_client = Jojo::AIClient.new(@config, verbose: false)
    @config_hash = YAML.load_file(fixture_path("valid_config.yml"))
    @job_context = {
      job_description: "Looking for a Senior Ruby on Rails developer with PostgreSQL and Docker experience. Must have strong backend skills and experience with microservices architecture."
    }
    @transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: @ai_client,
      config: @config_hash,
      job_context: @job_context
    )
  end

  def test_filter_field_filters_skills_and_returns_valid_json_indices
    MockOpenAI.set_responses([{match: ".*", response: "[0, 6]"}])

    data = {"skills" => ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]}

    @transformer.send(:filter_field, "skills", data)

    assert_kind_of Array, data["skills"]
    assert_operator data["skills"].length, :>, 0
    assert_operator data["skills"].length, :<=, 8

    data["skills"].each do |skill|
      assert_includes ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"], skill
    end
  end

  def test_reorder_field_maintains_all_items_when_can_remove_is_false
    MockOpenAI.set_responses([{match: ".*", response: "[0, 1, 2]"}])

    data = {
      "experience" => [
        {"company" => "TechCorp", "title" => "Senior Engineer", "description" => "Led Ruby on Rails team"},
        {"company" => "StartupXYZ", "title" => "Developer", "description" => "Built Python APIs"},
        {"company" => "ConsultingCo", "title" => "Junior Dev", "description" => "Frontend JavaScript work"}
      ]
    }

    original_count = data["experience"].length

    @transformer.send(:reorder_field, "experience", data, can_remove: false)

    assert_equal original_count, data["experience"].length
    assert_kind_of Array, data["experience"]
    companies = data["experience"].map { |exp| exp["company"] }.sort
    assert_equal ["ConsultingCo", "StartupXYZ", "TechCorp"], companies
  end

  def test_reorder_field_allows_removal_when_can_remove_is_true
    MockOpenAI.set_responses([{match: ".*", response: "[0, 2, 1, 3, 4]"}])

    data = {"skills" => ["Ruby", "Python", "JavaScript", "Cobol", "Fortran"]}

    @transformer.send(:reorder_field, "skills", data, can_remove: true)

    assert_kind_of Array, data["skills"]
    assert_operator data["skills"].length, :>, 0
    assert_operator data["skills"].length, :<=, 5
  end

  def test_rewrite_field_tailors_summary_to_job_description
    MockOpenAI.set_responses([{match: ".*", response: "Experienced software engineer with broad technical background across multiple domains"}])

    data = {"summary" => "Experienced software engineer with broad technical background across multiple domains"}

    @transformer.send(:rewrite_field, "summary", data)

    assert_kind_of String, data["summary"]
    assert_operator data["summary"].length, :>, 0
  end

  def test_raises_permission_violation_if_ai_removes_from_reorder_only_field
    # Response returns only 3 of 5 items — this triggers a PermissionViolation
    # because can_remove: false requires all items to be returned.
    MockOpenAI.set_responses([{match: ".*", response: "[0, 1, 2]"}])

    transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: @ai_client,
      config: @config_hash,
      job_context: {
        job_description: "Looking ONLY for Ruby developers. No other languages."
      }
    )

    data = {"languages" => ["English", "Spanish", "French", "German", "Japanese"]}

    error = assert_raises(Jojo::PermissionViolation) do
      transformer.send(:reorder_field, "languages", data, can_remove: false)
    end
    assert_includes error.message, "removed items"
  end
end
```

- [ ] **Step 2: Stage the deletion of the old VCR test file**

`git rm` removes the file from disk and stages the deletion in one step:

```bash
cd /Users/tracy/projects/jojo
git rm test/integration/resume_transformer_vcr_test.rb
```

- [ ] **Step 3: Commit**

```bash
cd /Users/tracy/projects/jojo
git add test/integration/resume_transformer_test.rb
git commit -m "refactor: convert VCR integration tests to MockOpenAI"
```

---

### Task 7: Delete cassette files and verify

**Project:** `/Users/tracy/projects/jojo`

**Files:**
- Delete: `test/cassettes/` (entire directory — 5 yml files)

- [ ] **Step 1: Delete the cassettes directory**

```bash
cd /Users/tracy/projects/jojo
rm -rf test/cassettes
```

- [ ] **Step 2: Run the full test suite**

```
cd /Users/tracy/projects/jojo
./bin/test
```

Expected: All tests pass with no failures. No VCR, WebMock, or cassette-related output. MockOpenAI server startup message may appear once at the top of the output.

- [ ] **Step 3: Commit**

```bash
cd /Users/tracy/projects/jojo
git rm -r test/cassettes
git commit -m "chore: remove VCR cassette files"
```
