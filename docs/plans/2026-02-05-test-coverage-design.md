# Test Coverage Review Design

## Overview

Add SimpleCov to measure test coverage across the jojo codebase, providing visibility into current coverage levels before making data-driven decisions about where to add tests.

## Goals

1. **Visibility first** - Measure current coverage before deciding what to improve
2. **Multiple output formats** - Terminal summary, HTML reports, and JSON for AI analysis
3. **All tests combined** - Unit, integration, and service tests contribute to one report
4. **No threshold initially** - Measure first, set baseline later

## Implementation

### Gemfile Changes

Add to the test group:

```ruby
group :test do
  gem "simplecov", require: false
  gem "simplecov_json_formatter", require: false
end
```

### Test Helper Configuration

Add to the **top** of `test/test_helper.rb` (before any other requires):

```ruby
require "simplecov"
require "simplecov_json_formatter"

SimpleCov.start do
  # Output formats
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

  # Track only lib/ code
  track_files "lib/**/*.rb"

  # Standard exclusions
  add_filter "/test/"
  add_filter "/bin/"
  add_filter "/vendor/"

  # Group by component for easier analysis
  add_group "Commands", "lib/jojo/commands"
  add_group "Generators", "lib/jojo/generators"
  add_group "Prompts", "lib/jojo/prompts"
  add_group "Core", "lib/jojo"
end
```

### Git Ignore

Add to `.gitignore`:

```
coverage/
```

### Output Locations

- `coverage/index.html` - Browsable HTML report
- `coverage/coverage.json` - Machine-readable for AI analysis
- Terminal shows summary after each test run

## Workflow

### Running Tests with Coverage

```bash
./bin/jojo test --all --no-service
```

Terminal output includes coverage summary:
```
Coverage report generated for Unit Tests to /path/to/coverage.
Line Coverage: XX.XX% (XXXX / XXXX lines)
```

### Viewing Detailed Reports

```bash
open coverage/index.html
```

Browse coverage by file with uncovered lines highlighted.

### AI-Assisted Analysis

Read `coverage/coverage.json` to get:
- Files with lowest coverage
- Uncovered methods/branches
- Prioritized recommendations for adding tests

## Post-Measurement Improvement Process

### Phase 1: Measure & Analyze

- Run full test suite with coverage
- Analyze JSON output to identify:
  - Overall coverage percentage
  - Lowest-covered files
  - Completely untested files
  - Coverage by component group

### Phase 2: Prioritize Improvements

Based on data, prioritize by:
1. **Critical paths** - Core business logic with low coverage
2. **Easy wins** - Files close to good coverage needing a few more tests
3. **Complex areas** - May need refactoring to be testable

### Phase 3: Incremental Improvement

- Add tests file-by-file, re-measuring after each
- Once stable, set a baseline threshold to prevent regressions

## Out of Scope

- CI/CD integration (can add later)
- Branch coverage (line coverage is sufficient to start)
- Coverage badges
- Minimum coverage thresholds (measure first)

## Implementation Tasks

1. [ ] Add SimpleCov gems to Gemfile
2. [ ] Run `bundle install`
3. [ ] Add SimpleCov configuration to test/test_helper.rb
4. [ ] Add coverage/ to .gitignore
5. [ ] Run tests to generate baseline coverage report
6. [ ] Analyze coverage data and identify gaps
