# CLI Commands Refactor - Remaining Work

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete the incomplete tasks from the CLI refactoring plan that were not fully implemented.

**Context:** The original plan at `docs/plans/2026-02-01-cli-commands-refactor-implementation.md` specified moving generators, prompts, and service files to be co-located with their command classes. While command classes were created and wired into the CLI, many supporting files were not moved as specified.

---

## Task 1: Move Website Prompt

**Files:**
- Restore: `lib/jojo/commands/website/prompt.rb` (was deleted from `lib/jojo/prompts/website_prompt.rb` without being moved)
- Test: Create `test/unit/commands/website/prompt_test.rb`

**Step 1: Check git for the deleted file**

```bash
git show HEAD~50:lib/jojo/prompts/website_prompt.rb > /tmp/website_prompt.rb
```

**Step 2: Create the prompt file in new location**

Create `lib/jojo/commands/website/prompt.rb` with the content from git history, updating the module path from `Jojo::Prompts::Website` to `Jojo::Commands::Website::Prompt`.

**Step 3: Update generator to use new prompt**

Update `lib/jojo/commands/website/generator.rb` to require and use the co-located prompt.

**Step 4: Create test file**

Move/recreate `test/unit/commands/website/prompt_test.rb` from git history, updating namespaces.

**Step 5: Run tests and commit**

---

## Task 2: Move PDF Support Files

**Files:**
- Move: `lib/jojo/pdf_converter.rb` → `lib/jojo/commands/pdf/converter.rb`
- Move: `lib/jojo/pandoc_checker.rb` → `lib/jojo/commands/pdf/pandoc_checker.rb`
- Move: `test/unit/pdf_converter_test.rb` → `test/unit/commands/pdf/converter_test.rb`
- Move: `test/unit/pandoc_checker_test.rb` → `test/unit/commands/pdf/pandoc_checker_test.rb`
- Update: `lib/jojo/commands/pdf/command.rb` to use new paths

**Step 1: Create converter.rb in new location**

Copy `lib/jojo/pdf_converter.rb` to `lib/jojo/commands/pdf/converter.rb`:
- Update module path from `Jojo::PdfConverter` to `Jojo::Commands::Pdf::Converter`
- Update require for pandoc_checker to use relative path

**Step 2: Create pandoc_checker.rb in new location**

Copy `lib/jojo/pandoc_checker.rb` to `lib/jojo/commands/pdf/pandoc_checker.rb`:
- Update module path from `Jojo::PandocChecker` to `Jojo::Commands::Pdf::PandocChecker`

**Step 3: Update pdf/command.rb**

Update `lib/jojo/commands/pdf/command.rb`:
- Change `require_relative "../../pdf_converter"` to `require_relative "converter"`
- Change `Jojo::PdfConverter` to `Converter`

**Step 4: Move and update test files**

Move test files to new locations, updating:
- require paths
- Class references

**Step 5: Delete old files**

```bash
rm lib/jojo/pdf_converter.rb
rm lib/jojo/pandoc_checker.rb
rm test/unit/pdf_converter_test.rb
rm test/unit/pandoc_checker_test.rb
```

**Step 6: Run tests and commit**

---

## Task 3: Move Setup Service

**Files:**
- Move: `lib/jojo/setup_service.rb` → `lib/jojo/commands/setup/service.rb`
- Move: `test/unit/setup_service_test.rb` → `test/unit/commands/setup/service_test.rb`
- Update: `lib/jojo/commands/setup/command.rb` to use new path

**Step 1: Create service.rb in new location**

Copy `lib/jojo/setup_service.rb` to `lib/jojo/commands/setup/service.rb`:
- Update module path from `Jojo::SetupService` to `Jojo::Commands::Setup::Service`

**Step 2: Update setup/command.rb**

Update `lib/jojo/commands/setup/command.rb`:
- Change require to use relative path
- Change class reference from `Jojo::SetupService` to `Service`

**Step 3: Move and update test file**

Move `test/unit/setup_service_test.rb` to `test/unit/commands/setup/service_test.rb`:
- Update require path
- Update class references

**Step 4: Delete old files**

```bash
rm lib/jojo/setup_service.rb
rm test/unit/setup_service_test.rb
```

**Step 5: Run tests and commit**

---

## Task 4: Move Job Description Support Files

**Files:**
- Move: `lib/jojo/job_description_processor.rb` → `lib/jojo/commands/job_description/processor.rb`
- Move: `lib/jojo/prompts/job_description_prompts.rb` → `lib/jojo/commands/job_description/prompt.rb`
- Move: `test/unit/job_description_processor_test.rb` → `test/unit/commands/job_description/processor_test.rb`
- Update: `lib/jojo/commands/job_description/command.rb` to use new paths
- Update: `lib/jojo.rb` to remove old requires

**Step 1: Create processor.rb in new location**

Copy `lib/jojo/job_description_processor.rb` to `lib/jojo/commands/job_description/processor.rb`:
- Update module path from `Jojo::JobDescriptionProcessor` to `Jojo::Commands::JobDescription::Processor`
- Update require for prompt to use relative path

**Step 2: Create prompt.rb in new location**

Copy `lib/jojo/prompts/job_description_prompts.rb` to `lib/jojo/commands/job_description/prompt.rb`:
- Update module path from `Jojo::Prompts::JobDescription` to `Jojo::Commands::JobDescription::Prompt`

**Step 3: Update job_description/command.rb**

Update `lib/jojo/commands/job_description/command.rb`:
- Add `require_relative "processor"`
- Change class reference from `Jojo::JobDescriptionProcessor` to `Processor`

**Step 4: Move and update test file**

Move test file to new location, updating paths and class references.

**Step 5: Update lib/jojo.rb**

Remove the old requires:
```ruby
# Remove these lines:
require_relative "jojo/prompts/job_description_prompts"
require_relative "jojo/job_description_processor"
```

**Step 6: Delete old files**

```bash
rm lib/jojo/job_description_processor.rb
rm lib/jojo/prompts/job_description_prompts.rb
rmdir lib/jojo/prompts  # Should now be empty
rm test/unit/job_description_processor_test.rb
```

**Step 7: Run tests and commit**

---

## Task 5: Verify Resume Support Files Are Co-located

**Files:**
- Check: `lib/jojo/resume_curation_service.rb` vs `lib/jojo/commands/resume/curation_service.rb`
- Check: `lib/jojo/resume_transformer.rb` vs `lib/jojo/commands/resume/transformer.rb`
- Move tests if old source files are duplicates

**Step 1: Compare files**

Check if the files in `lib/jojo/commands/resume/` are complete copies or if the old files have different content.

**Step 2: If duplicates, delete old files**

```bash
rm lib/jojo/resume_curation_service.rb
rm lib/jojo/resume_transformer.rb
```

**Step 3: Move test files**

- Move: `test/unit/resume_curation_service_test.rb` → `test/unit/commands/resume/curation_service_test.rb`
- Move: `test/unit/resume_transformer_test.rb` → `test/unit/commands/resume/transformer_test.rb`

Update require paths and class references in moved tests.

**Step 4: Delete old test files**

```bash
rm test/unit/resume_curation_service_test.rb
rm test/unit/resume_transformer_test.rb
```

**Step 5: Run tests and commit**

---

## Task 6: Final Cleanup and Verification

**Files:**
- Update: `lib/jojo.rb` (if any remaining old requires)
- Verify: No old directories remain

**Step 1: Audit lib/jojo.rb**

Ensure `lib/jojo.rb` only requires:
- Core utilities (state_persistence, config, employer, etc.)
- Command infrastructure (commands/base, commands/console_output)
- CLI

It should NOT directly require any generators, prompts, or services.

**Step 2: Verify old directories are gone**

```bash
ls lib/jojo/generators/  # Should not exist
ls lib/jojo/prompts/     # Should not exist
ls lib/jojo/ui/          # Should not exist
```

**Step 3: Run full test suite**

```bash
./bin/jojo test --all --no-service
```

**Step 4: Verify line count**

```bash
wc -l lib/jojo/cli.rb
# Expected: ~150-200 lines
```

**Step 5: Final commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor: complete CLI commands refactor cleanup

All generators, prompts, and services now co-located
with their command classes under lib/jojo/commands/.
Old directories and duplicate files removed.
EOF
)"
```

---

## Summary of Files to Move

| Old Location | New Location |
|--------------|--------------|
| `lib/jojo/prompts/website_prompt.rb` | `lib/jojo/commands/website/prompt.rb` (restore from git) |
| `lib/jojo/pdf_converter.rb` | `lib/jojo/commands/pdf/converter.rb` |
| `lib/jojo/pandoc_checker.rb` | `lib/jojo/commands/pdf/pandoc_checker.rb` |
| `lib/jojo/setup_service.rb` | `lib/jojo/commands/setup/service.rb` |
| `lib/jojo/job_description_processor.rb` | `lib/jojo/commands/job_description/processor.rb` |
| `lib/jojo/prompts/job_description_prompts.rb` | `lib/jojo/commands/job_description/prompt.rb` |
| `lib/jojo/resume_curation_service.rb` | (already at `lib/jojo/commands/resume/curation_service.rb`, delete old) |
| `lib/jojo/resume_transformer.rb` | (already at `lib/jojo/commands/resume/transformer.rb`, delete old) |

## Test Files to Move

| Old Location | New Location |
|--------------|--------------|
| `test/unit/pdf_converter_test.rb` | `test/unit/commands/pdf/converter_test.rb` |
| `test/unit/pandoc_checker_test.rb` | `test/unit/commands/pdf/pandoc_checker_test.rb` |
| `test/unit/setup_service_test.rb` | `test/unit/commands/setup/service_test.rb` |
| `test/unit/job_description_processor_test.rb` | `test/unit/commands/job_description/processor_test.rb` |
| `test/unit/resume_curation_service_test.rb` | `test/unit/commands/resume/curation_service_test.rb` |
| `test/unit/resume_transformer_test.rb` | `test/unit/commands/resume/transformer_test.rb` |
