# Design: `./bin/setup` Bootstrap Script

**Date:** 2026-02-25

## Problem

New users must manually run `bundle install` and separately install system dependencies
(pandoc, wkhtmltopdf) before `./bin/jojo setup` is usable. This creates friction and
undocumented failure modes.

## Goal

A single `./bin/setup` command that bootstraps a fresh clone to a fully runnable state,
then hands off to `./bin/jojo setup` for application configuration.

## Approach

A bash shell script with a reusable `check_and_install` helper function. Shell is the right
layer because it runs before Ruby is available. The helper function is justified by two
system dependencies (pandoc, wkhtmltopdf) with differing macOS install types (formula vs
cask).

## Target Platforms

- macOS via Homebrew
- Linux (Debian/Ubuntu) via apt-get
- Other Linux: non-fatal — print manual instructions, continue

## Script Structure

```
bin/setup
  ├── check_and_install(label, brew_formula, brew_type, apt_package)
  ├── Step 1: Check Ruby version against .ruby-version
  ├── Step 2: bundle install
  ├── Step 3: npm install (in templates/website/)
  ├── Step 4: check_and_install pandoc
  ├── Step 5: check_and_install wkhtmltopdf
  └── Step 6: Prompt → run ./bin/jojo setup
```

## Helper Function: `check_and_install`

Parameters: `label`, `brew_formula`, `brew_type` (`formula`|`cask`), `apt_package`

1. `command -v <label>` → if found, print `✓ <label> already installed`, return
2. Prompt: `<label> not found. Install it? [y/N]`
3. On yes:
   - `Darwin` → `brew install [--cask] <brew_formula>`
   - `Linux` with `apt-get` → `sudo apt-get install -y <apt_package>`
   - `Linux` without `apt-get` → print manual instructions, continue (non-fatal)
4. On no: print note that `jojo pdf` requires this tool, continue (non-fatal)

Notable: `wkhtmltopdf` uses `brew_type=cask`; `pandoc` uses `brew_type=formula`.

## Error Handling

- `set -e` at top of script — most command failures abort automatically
- **Ruby version mismatch**: exit 1, print required vs found, suggest rbenv or mise
- **Missing Homebrew on macOS**: exit 1, print "Install from https://brew.sh, then re-run"
- **Skipped system deps**: non-fatal, print a reminder and continue
- **`jojo setup` failure**: handed off — its own error handling applies

## `--check` Flag

Runs all detection checks and prints status without installing or modifying anything.
Useful for diagnosing environment issues and for CI verification.

## Output Style

Uses `✓`/`✗` and ANSI color codes (green/red/yellow) consistent with `jojo setup` output.

## CI Integration

Add a `./bin/setup --check` step to the existing GitHub Actions workflow to verify
detection logic runs correctly on ubuntu-latest.

## Testing

No automated tests for the script itself (avoids `bats` as a new dependency).
- `--check` flag enables non-destructive CI verification
- Manual verification on macOS and Ubuntu covers install paths

## Resulting User Flow

```bash
git clone https://github.com/grymoire7/jojo.git
cd jojo
./bin/setup        # replaces: bundle install + manual dep hunting + ./bin/jojo setup
```
