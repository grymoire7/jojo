# MockOpenAI Integration

**Date:** 2026-03-15
**Status:** Approved
**Projects:** mockopenai (additions), jojo (integration)

## Overview

Replace jojo's VCR-based LLM test mocking with MockOpenAI. This validates
MockOpenAI in a real project and removes the VCR/WebMock dependency entirely.

The work splits into two parts:
1. **MockOpenAI additions** — add `start_test_server!`, `server_url`, and
   `Server.wait_until_ready` to make test setup a single call; update docs
2. **Jojo integration** — upgrade RubyLLM, wire in MockOpenAI, replace VCR tests

## Part 1: MockOpenAI additions

### New public API

**`MockOpenAI.start_test_server!`**

Starts the server in a background thread and blocks until it is accepting
connections. Idempotent — calling it a second time is a no-op (checks if the
port is already responding before starting a thread).

```ruby
MockOpenAI.start_test_server!
```

**`MockOpenAI.server_url`**

Returns the base URL of the running server so clients can configure themselves
without hardcoding the port.

```ruby
MockOpenAI.server_url  # => "http://127.0.0.1:4000"
```

**`MockOpenAI::Server.wait_until_ready(timeout: 5)`**

Polls the configured port via `TCPSocket` until it accepts a connection or the
timeout expires. Raises `RuntimeError` on timeout.

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

### Files changed (mockopenai)

- **`lib/mock_openai/server.rb`** — add `wait_until_ready`
- **`lib/mock_openai.rb`** — add `start_test_server!` and `server_url`
- **`docs/usage/minitest.md`** — show `start_test_server!` as standard setup;
  clarify when it is and isn't needed
- **`docs/usage/standalone.md`** — clarify this is for separate-process tests
  (Capybara, Playwright); not for unit/integration tests

### When `start_test_server!` is required

`start_test_server!` is needed whenever application code makes real outbound
HTTP connections to an LLM API. This includes:

- CLI tools (like jojo)
- Rails/Sinatra apps making outbound API calls in unit/integration tests
- Background jobs, plain Ruby scripts

`start_test_server!` is **not** needed when testing MockOpenAI's own Rack app
directly via `rack-test` — that is only the case inside MockOpenAI's own spec
suite.

## Part 2: Jojo integration

### Files changed (jojo)

- **`Gemfile`** — bump `ruby_llm` to `~> 1.13`; add
  `gem "mockopenai", path: "../mockopenai"` in test group; remove `vcr` and
  `webmock`
- **`test/test_helper.rb`** — remove VCR config; add MockOpenAI server startup
  and RubyLLM configuration; include `MockOpenAI::Minitest` in `JojoTest`;
  remove `with_vcr` helper
- **`test/integration/resume_transformer_vcr_test.rb`** → rename to
  `resume_transformer_test.rb`; replace `with_vcr` wrappers with
  `MockOpenAI.set_responses`; rename class to `ResumeTransformerTest`
- **`test/cassettes/`** — delete all 5 cassette files and directory

### test_helper.rb changes

Remove the VCR config block entirely. Replace with:

```ruby
require "mock_openai/minitest"

MockOpenAI.start_test_server!

RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", "test-key")
  config.anthropic_api_base = MockOpenAI.server_url
end
```

Include `MockOpenAI::Minitest` in `JojoTest`:

```ruby
class JojoTest < Minitest::Test
  include MockOpenAI::Minitest
  # ... rest of class unchanged
end
```

Remove the `with_vcr` helper method — it is no longer needed.

**Why this works:** Jojo's `AIClient#configure_ruby_llm` sets only the API key
(and similar auth fields) from its config. It does not touch `anthropic_api_base`,
so the base URL set in test_helper persists for all tests.

### Test rule responses

Each test makes exactly one LLM call and runs in isolation (MockOpenAI resets
state between tests via `MockOpenAI::Minitest`), so `".*"` is a safe catch-all
match pattern.

| Test | Response |
|---|---|
| `test_filter_field_filters_skills_*` | `"[0, 6]"` |
| `test_reorder_field_maintains_all_items_*` | `"[0, 1, 2]"` |
| `test_reorder_field_allows_removal_*` | `"[0, 2, 1, 3, 4]"` |
| `test_rewrite_field_tailors_summary_*` | `"Experienced software engineer with broad technical background across multiple domains"` |
| `test_raises_permission_violation_*` | `"[0, 1, 2]"` — 3 of 5 items, which triggers PermissionViolation on a `can_remove: false` field |

Each test sets its rule before its assertions (no `with_vcr` wrapper needed):

```ruby
def test_filter_field_filters_skills_and_returns_valid_json_indices
  MockOpenAI.set_responses([{match: ".*", response: "[0, 6]"}])

  data = {"skills" => ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]}
  @transformer.send(:filter_field, "skills", data)

  assert_kind_of Array, data["skills"]
  # ...
end
```

### RubyLLM version

Bump from `~> 1.9` to `~> 1.13`. Version 1.13.2 adds `anthropic_api_base`
config support, which is required to redirect Anthropic calls to MockOpenAI.

## Testing

### MockOpenAI spec additions

- **`spec/mock_openai/server_spec.rb`** (update) — add test for
  `wait_until_ready` (starts server in thread, verifies method returns without
  raising)
- **`spec/mock_openai_spec.rb`** (update) — add tests for `start_test_server!`
  (idempotent, server is reachable after call) and `server_url` (returns
  correct URL string)

### Jojo test verification

Run `./bin/test` — all tests must pass with no cassette files present and no
VCR/WebMock in the Gemfile.
