# Interactive CLI Design

## Problem

The current CLI has cognitive load issues:
- Hard to remember command sequencing (which order to run commands)
- Unclear what each command does, its inputs/outputs
- No visibility into which commands call paid APIs
- No awareness of stale artifacts when dependencies are regenerated

## Solution

Add an interactive mode (`jojo` with no args or `jojo i`) that provides a
dashboard showing workflow state, guides users through the process, and tracks
artifact staleness.

## Dashboard

```
┌─ Jojo ───────────────────────────────────────────────┐
│  Active: acme-corp-senior-dev                        │
│  Company: Acme Corp  •  Role: Senior Developer       │
├──────────────────────────────────────────────────────┤
│  Workflow                             Status         │
│  ─────────────────────────────────────────────────   │
│  1. Job Description              💰   ✅ Generated   │
│  2. Research                     💰   ✅ Generated   │
│  3. Resume                       💰   🍞 Stale       │
│  4. Cover Letter                 💰   ⭕ Ready       │
│  5. Annotations                  💰   ⭕ Ready       │
│  6. FAQ                          💰   ⭕ Ready       │
│  7. Branding Statement           💰   ⭕ Ready       │
│  8. Website                           🔒 Blocked     │
│  9. PDF                               🔒 Blocked     │
├──────────────────────────────────────────────────────┤
│  Status:  ✅Generated  🍞Stale  ⭕Ready  🔒Blocked   │
├──────────────────────────────────────────────────────┤
│  [1-7] Generate/regenerate item    [a] All ready     │
│  [o] Open folder  [s] Switch application  [q] Quit   │
└──────────────────────────────────────────────────────┘
```

### Status Icons

| Icon | Meaning |
|------|---------|
| ✅ | Generated and up-to-date |
| 🍞 | Stale - generated but a dependency was regenerated since |
| ⭕ | Ready - prerequisites met, can generate now |
| 🔒 | Blocked - missing prerequisites |
| 💰 | Calls paid API (shown in workflow column) |

## Dependency Graph

Static configuration defining workflow relationships:

```yaml
workflow:
  job_description:
    dependencies: []
    command: new
    paid: false

  research:
    dependencies: [job_description]
    command: research
    paid: true

  resume:
    dependencies: [job_description, research]
    command: resume
    paid: true

  cover_letter:
    dependencies: [resume]
    command: cover_letter
    paid: true

  annotations:
    dependencies: [job_description]
    command: annotate
    paid: true

  faq:
    dependencies: [job_description, resume]
    command: faq
    paid: true

  website:
    dependencies: [resume, annotations, faq]
    command: website
    paid: false

  pdf:
    dependencies: [resume, cover_letter]
    command: pdf
    paid: false
```

### Staleness Detection

Uses file modification times - no metadata files needed:

```ruby
def stale?(file, dependencies)
  return false unless File.exist?(file)

  file_mtime = File.mtime(file)
  dependencies.any? { |dep| File.exist?(dep) && File.mtime(dep) > file_mtime }
end
```

## Interaction Flows

### Selecting a Blocked Item

```
┌─ Cover Letter ───────────────────────────────────────┐
│  Cannot generate yet. Missing prerequisites:         │
│                                                      │
│    • resume.md (not generated)                       │
│                                                      │
│  [3] Generate Resume first    [Esc] Back             │
└──────────────────────────────────────────────────────┘
```

### Selecting a Ready or Stale Item

```
┌─ Cover Letter ───────────────────────────────────────┐
│  Generate cover letter? 💰                           │
│                                                      │
│  Inputs:                                             │
│    • resume.md (generated 2 hours ago)               │
│    • job_description.md                              │
│                                                      │
│  Output:                                             │
│    • cover_letter.md                                 │
│                                                      │
│  [Enter] Generate    [Esc] Back                      │
└──────────────────────────────────────────────────────┘
```

### Selecting a Generated Item

```
┌─ Cover Letter ───────────────────────────────────────┐
│  cover_letter.md already exists (generated 1h ago)   │
│                                                      │
│  [r] Regenerate 💰    [v] View    [Esc] Back         │
└──────────────────────────────────────────────────────┘
```

### Generation in Progress

```
┌─ Jojo ───────────────────────────────────────────────┐
│  Active: acme-corp-senior-dev                        │
│  ...                                                 │
│  4. Cover Letter                 💰    ⠋ Generating… │
│  ...                                                 │
├──────────────────────────────────────────────────────┤
│  Generating cover letter...  [Ctrl+C] Cancel         │
└──────────────────────────────────────────────────────┘
```

### Error Handling

```
┌─ Error ──────────────────────────────────────────────┐
│                                                      │
│  Cover letter generation failed:                     │
│                                                      │
│  API Error: Rate limit exceeded. Try again in 60s.   │
│                                                      │
│  [r] Retry    [v] View full error    [Esc] Back      │
└──────────────────────────────────────────────────────┘
```

## Application Switching

```
┌─ Switch Application ─────────────────────────────────┐
│                                                      │
│  Recent applications:                                │
│                                                      │
│  1. acme-corp-senior-dev        ███████░░░  70%     │
│     Acme Corp • Senior Developer                     │
│                                                      │
│  2. globex-staff-engineer       ██████████  Done    │
│     Globex Inc • Staff Engineer                      │
│                                                      │
│  3. initech-lead-dev            ██░░░░░░░░  20%     │
│     Initech • Lead Developer                         │
│                                                      │
│  [1-3] Select    [n] New application    [Esc] Back   │
└──────────────────────────────────────────────────────┘
```

Progress bar shows workflow completion (generated, non-stale items / total).

## First Run / No Applications

```
┌─ Jojo ───────────────────────────────────────────────┐
│                                                      │
│  Welcome! No applications yet.                       │
│                                                      │
│  To get started, create your first application:      │
│                                                      │
│  [n] New application    [q] Quit                     │
└──────────────────────────────────────────────────────┘
```

### New Application Flow

```
┌─ New Application ────────────────────────────────────┐
│                                                      │
│  Slug (e.g., acme-corp-senior-dev):                  │
│  > █                                                 │
│                                                      │
└──────────────────────────────────────────────────────┘
```

Then:

```
┌─ New Application ────────────────────────────────────┐
│                                                      │
│  Job description source:                             │
│                                                      │
│  [u] URL    [f] File path    [p] Paste text          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## State Persistence

`.jojo_state` (gitignored) stores the last active application slug so running `jojo` resumes where you left off.

## Implementation

### New Files

| File | Purpose |
|------|---------|
| `lib/jojo/interactive.rb` | Main interactive UI loop |
| `lib/jojo/workflow.rb` | Dependency graph, status computation, staleness detection |
| `lib/jojo/ui/dashboard.rb` | Dashboard rendering |
| `lib/jojo/ui/dialogs.rb` | Modal dialogs (confirmation, error, input) |

### Changes to Existing Files

- `lib/jojo/cli.rb` - Add `jojo` (no args) and `jojo i` entry points
- `.gitignore` - Add `.jojo_state`

### Dependencies

TUI library for cursor control and key handling. Options:
- **tty-prompt / tty-cursor / tty-box** - Popular, well-maintained TTY toolkit
- **reline** - Already in deps, more limited
- **curses** - Powerful but lower-level

### What Stays the Same

- All existing generators, prompts, and AI logic
- Existing CLI commands still work (power users, scripts, CI)
- File structure and outputs unchanged

## Terminology

- Code uses `Employer` class internally
- UI uses "application" (user may apply to multiple jobs at same company)
