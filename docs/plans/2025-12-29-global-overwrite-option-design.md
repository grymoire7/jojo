# Global Overwrite Option Design

**Date:** 2025-12-29
**Status:** Design Complete

## Problem Statement

Jojo currently has inconsistent file overwriting behavior across commands:
- `jojo new` requires an explicit `--overwrite` flag
- `jojo setup` prompts interactively before overwriting
- All content generators (`research`, `resume`, `cover_letter`, `website`, `annotate`, `generate`) silently overwrite files without asking

This inconsistency can lead to accidental data loss when users regenerate content that they've manually edited.

## Solution Overview

Make `--overwrite` a global option with consistent behavior across all commands. By default, jojo will prompt before overwriting any existing file. Users can bypass prompts via the `--overwrite` flag or `JOJO_ALWAYS_OVERWRITE` environment variable.

## Behavior Specification

### Default Behavior

When any command attempts to write a file that already exists, jojo will prompt:
```
{filename} exists. Overwrite? (y/n)
```

The user's response determines whether that specific file is written or skipped.

### Override Mechanisms (Precedence Order)

1. **`--overwrite` flag**: Silently overwrites all files without prompting
2. **`--no-overwrite` flag**: Always prompts, even if `JOJO_ALWAYS_OVERWRITE` is set
3. **`JOJO_ALWAYS_OVERWRITE` environment variable**: When set to truthy values (`1`, `true`, `yes`), silently overwrites all files
4. **Default**: Prompt for each file

### Multi-file Operations

Commands that write multiple files (like `jojo generate`) will ask individually for each existing file. If the user says "no" to any file, that file is skipped and generation continues with remaining files.

### Non-interactive Environments

When running in non-TTY environments (CI/CD, cron, piped commands) and prompting would be required, jojo will exit with an error:
```
Cannot prompt in non-interactive mode. Use --overwrite or set JOJO_ALWAYS_OVERWRITE=true
```

This forces explicit intent and avoids surprising behavior in automated contexts.

## Implementation Architecture

### Core Component: OverwriteHelper Module

Create a new mixin module at `lib/jojo/overwrite_helper.rb`:

```ruby
module Jojo
  module OverwriteHelper
    def with_overwrite_check(path, overwrite_flag, &block)
      # Check if file exists
      return yield unless File.exist?(path)

      # Check override mechanisms in precedence order
      return yield if should_overwrite?(overwrite_flag)

      # Prompt user or fail in non-TTY
      if $stdout.isatty
        filename = File.basename(path)
        yield if yes?("#{filename} exists. Overwrite?")
      else
        raise Thor::Error, "Cannot prompt in non-interactive mode. Use --overwrite or set JOJO_ALWAYS_OVERWRITE=true"
      end
    end

    private

    def should_overwrite?(flag)
      # --overwrite flag wins
      return true if flag == true
      # --no-overwrite flag blocks env var
      return false if flag == false
      # Check environment variable
      env_overwrite?
    end

    def env_overwrite?
      %w[1 true yes].include?(ENV['JOJO_ALWAYS_OVERWRITE']&.downcase)
    end
  end
end
```

### Integration Points

1. **CLI class** includes the module:
   ```ruby
   class CLI < Thor
     include OverwriteHelper
   ```

2. **Global option** added to Thor:
   ```ruby
   class_option :overwrite, type: :boolean, banner: 'Overwrite existing files without prompting'
   ```

3. **All generators** updated to use the helper instead of direct `File.write()` calls

## Command-Specific Changes

### 1. `jojo new` (lib/jojo/cli.rb:52-70)

**Current behavior:**
- Has command-specific `--overwrite` option
- Checks `employer.artifacts_exist?` and exits with error if true and no flag

**Changes:**
- Remove command-specific `--overwrite` option
- Remove custom `employer.artifacts_exist?` check
- Update `employer.create_artifacts()` to use `with_overwrite_check` for each file
- Use global `--overwrite` flag

### 2. `jojo setup` (lib/jojo/cli.rb:560-565)

**Current behavior:**
- Custom `yes?("config.yml already exists. Overwrite?")` prompt

**Changes:**
- Remove custom prompt
- Wrap `File.write(config_path, config_content)` in `with_overwrite_check`
- Use global overwrite behavior

### 3. Content Generators

**Commands affected:**
- `jojo research`
- `jojo resume`
- `jojo cover_letter`
- `jojo website`
- `jojo annotate`
- `jojo generate` (calls all above)

**Current behavior:**
- Each generator's `save_*` method does direct `File.write(path, content)`
- Silently overwrites existing files

**Changes:**
Update each save method from:
```ruby
def save_research(employer, research_text)
  File.write(employer.research_path, research_text)
end
```

To:
```ruby
def save_research(employer, research_text, overwrite_flag)
  with_overwrite_check(employer.research_path, overwrite_flag) do
    File.write(employer.research_path, research_text)
  end
end
```

The `overwrite_flag` comes from the global `options[:overwrite]` automatically.

## Testing Strategy

### Unit Tests for OverwriteHelper

Create `test/overwrite_helper_test.rb`:

**Test coverage:**
- `should_overwrite?` with various flag combinations:
  - `true` (--overwrite) → returns true
  - `false` (--no-overwrite) → returns false
  - `nil` with env var set → returns true
  - `nil` without env var → returns false
- `env_overwrite?` with different environment variable values:
  - `1`, `true`, `yes` → true
  - `0`, `false`, `no`, `anything_else` → false
  - Unset or empty → false
- Mock file existence and TTY checks

### Integration Tests for Each Command

**Test coverage per command:**
- File doesn't exist → writes without prompting
- File exists, user says "yes" → overwrites
- File exists, user says "no" → skips file
- `--overwrite` flag → skips prompts, overwrites all
- `--no-overwrite` flag → prompts even with env var
- `JOJO_ALWAYS_OVERWRITE=true` → skips prompts, overwrites all
- `JOJO_ALWAYS_OVERWRITE=false` → prompts normally
- Non-TTY environment without flags → raises error

### Multi-file Operation Tests

Focus on `jojo generate`:
- Multiple files exist, mixed user responses (yes to some, no to others)
- Verify skipped files aren't modified
- Verify accepted files are written correctly
- All files exist with `--overwrite` → all overwritten

### Edge Cases

- File exists but isn't writable → permission error
- Directory doesn't exist → should fail before prompting
- Symlinks → follow and check target file

### Test Fixtures

All test input files must use `test/fixtures/` directory (per CLAUDE.md guidelines - never use `inputs/` in tests).

## Files to Create

1. `lib/jojo/overwrite_helper.rb` - New helper module
2. `test/overwrite_helper_test.rb` - Unit tests for helper

## Files to Modify

1. `lib/jojo/cli.rb` - Add global option, include helper, update commands
2. Generator classes:
   - `lib/jojo/generators/research_generator.rb`
   - `lib/jojo/generators/resume_generator.rb`
   - `lib/jojo/generators/cover_letter_generator.rb`
   - `lib/jojo/generators/website_generator.rb`
   - `lib/jojo/generators/annotation_generator.rb`
3. Integration tests for all affected commands

## Migration Notes

### Breaking Changes

**For `jojo new`:**
- Previously: Required explicit `--overwrite` flag to overwrite
- Now: Prompts for each existing file (can use `--overwrite` to skip prompts)
- Migration: Scripts using `jojo new` in automation should add `--overwrite` or set `JOJO_ALWAYS_OVERWRITE=true`

**For content generators:**
- Previously: Silently overwrote files
- Now: Prompts before overwriting
- Migration: Scripts expecting silent overwrites should add `--overwrite` or set `JOJO_ALWAYS_OVERWRITE=true`

### Non-breaking Changes

**For `jojo setup`:**
- Previously: Prompted interactively
- Now: Still prompts (consistent behavior, just using global mechanism)
- Migration: None required

## Success Criteria

1. All commands use consistent overwrite behavior
2. `--overwrite` and `--no-overwrite` flags work globally
3. `JOJO_ALWAYS_OVERWRITE` environment variable is respected
4. Non-TTY environments fail gracefully with helpful error message
5. All tests pass
6. No accidental data loss from silent overwrites
7. Documentation updated to reflect new behavior

## Future Enhancements (Out of Scope)

- Summary at end of multi-file operations showing what was overwritten/skipped
- Wildcard support for selective overwrites (e.g., "overwrite all .md files")
- Backup/versioning before overwrite
- Diff view before overwrite decision
