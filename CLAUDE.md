# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 MANDATORY DEBUGGING PROTOCOL

**FOR ANY TECHNICAL ISSUE - ALWAYS use systematic debugging:**

- Bug reports, test failures, unexpected behavior, performance issues
- Regression issues, integration problems, build failures
- **Before attempting ANY fix, use the `superpowers:systematic-debugging` skill**

**FORBIDDEN PATTERNS (cause more bugs than they fix):**
- "Quick fixes" and guesswork - **STRICTLY PROHIBITED**
- Trying random API calls without understanding root cause
- Making multiple changes at once
- Skipping evidence gathering because issue "seems simple"

**DEBUGGING WORKFLOW:**
1. **Evidence Gathering First:** Add comprehensive logging to understand what's actually happening
2. **Pattern Analysis:** Compare working vs broken implementations
3. **Single Hypothesis Testing:** Make one targeted change to test theory
4. **Root Cause Fixes:** Address the actual cause, not symptoms

**REMEMBER:** Systematic debugging is 5x faster than guess-and-check thrashing.

## 🚨 INPUTS DIRECTORY PROTECTION

**CRITICAL: The `inputs/` directory contains user-curated data and MUST NEVER be modified by tests or automation:**

- **NEVER read from `inputs/` in tests** - use `test/fixtures/` instead
- **NEVER write to `inputs/` in tests** - use temporary directories
- **NEVER delete files from `inputs/`** - this directory is for production use only
- **Test fixtures MUST go in `test/fixtures/`** - dedicated directory for test data

**When writing tests:**
1. Always use `test/fixtures/` for test input files
2. Use temporary directories or mock data for test outputs
3. Never use `FileUtils.rm_rf` or similar on `inputs/`
4. Verify tests use `inputs_path: 'test/fixtures'` parameter when available

## Project Overview

## Development Commands

| Command                   | Description                                 |
| ------------------------- | ------------------------------------------- |
| ./bin/jojo help           | Display help for using jojo from the CLI.   |
| ./bin/jojo help [command] | Display help for a particular jojo command. |
| ./bin/test                | Run all tests. Use this often.              |
| ./bin/coverage_summary    | Get text coverage summaery (see --help).    |

## Common Tasks


## Documentation

Reference the documentation site in `docs/` for architecture, commands, and guides. Key files:
- `docs/architecture/overview.md` — system design and directory structure
- `docs/architecture/key-decisions.md` — why things are built the way they are

