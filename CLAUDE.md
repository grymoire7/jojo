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

## Project Overview

## Development Commands

| Command | Description |
| ------- | ----------- |
|         |             |

## Common Tasks


## Design Document

Reference the design document at `docs/plans/design.md` for understanding the full scope and planned features.

## Implementation Plan

When completing a phase of work, update `docs/plans/implementation_plan.md`:
1. Mark all completed tasks with `[x]` instead of `[ ]`
2. Add "✅" to the phase heading
3. Add `**Status**: COMPLETED` below the goal
4. Update validation section with ✅ if validation passes
5. Make any necessary corrections to task descriptions or code examples based on actual implementation

