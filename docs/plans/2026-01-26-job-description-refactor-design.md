# Job Description Command Refactor Design

## Overview

Separate job description processing from `jojo new` into its own `jojo job_description` command. This creates a cleaner separation of concerns and aligns the CLI with the interactive workflow where "Job Description" is already listed as a distinct step.

## Current State

- `jojo new -s slug -j job_source` creates directory AND processes job description
- Interactive mode bundles both in `handle_new_application`
- `JobDescriptionProcessor` class already handles all processing logic (well-factored)

## Design

### CLI Commands

#### `jojo new` (Modified)

```ruby
desc "new", "Create a new job application workspace"
method_option :slug, aliases: "-s", type: :string, required: true,
              desc: "Unique identifier for this application"

def new
  validate_resume_data_exists!
  employer = Employer.new(options[:slug])

  if employer.base_path.exist?
    say "Application '#{options[:slug]}' already exists", :yellow
    return
  end

  employer.base_path.mkpath
  say "Created application workspace: #{employer.base_path}", :green
end
```

- Removes `-j/--job` parameter entirely
- Just creates the directory
- Validates resume data still required (needed for later steps)

#### `jojo job_description` (New)

```ruby
desc "job_description", "Process job description for an application"
method_option :slug, aliases: "-s", type: :string,
              desc: "Application slug (uses current if omitted)"
method_option :job, aliases: "-j", type: :string, required: true,
              desc: "Job description URL or file path"

def job_description
  slug = options[:slug] || StatePersistence.current_slug
  abort "No application specified. Use -s or select one in interactive mode." unless slug

  employer = Employer.new(slug)
  abort "Application '#{slug}' does not exist. Run 'jojo new -s #{slug}' first." unless employer.base_path.exist?

  employer.create_artifacts(options[:job], ...)
end
```

- `-s` optional (uses current slug from `.jojo_state` if omitted)
- `-j` required
- Validates employer directory exists

### Interactive Mode Changes

#### `handle_new_application` (Simplified)

```ruby
def handle_new_application
  slug = prompt_for_slug
  return unless slug

  employer = Employer.new(slug)
  if employer.base_path.exist?
    show_error("Application '#{slug}' already exists")
    return
  end

  employer.base_path.mkpath
  switch_application(slug)
  # Dashboard now shows Job Description as "Ready"
end
```

- Removes job source prompting (URL/File/Paste menu)
- Removes `CLI.invoke(:new, ...)` call
- Just creates directory and switches to it

#### Job Description Step Handler

When user presses "1" and job description doesn't exist yet:

```ruby
def prompt_for_job_source
  print "\e[#{@height};1H\e[K"
  print "Job description (URL or file path): "
  source = @reader.read_line.strip
  return if source.empty?

  processor = JobDescriptionProcessor.new(@employer, ai_client, ...)
  processor.process(source)

  render_dashboard
end
```

- Single prompt with auto-detection (URL vs file path already handled by `JobDescriptionProcessor.fetch_content`)
- Uses existing processor logic
- Fits pattern of other step handlers

### Unchanged Components

- `lib/jojo/employer.rb` - already clean
- `lib/jojo/job_description_processor.rb` - already clean
- `lib/jojo/workflow.rb` - already has Job Description as step 1

## Files Changed

| File | Change |
|------|--------|
| `lib/jojo/cli.rb` | Remove `-j` from `new`, add `job_description` command |
| `lib/jojo/interactive.rb` | Simplify `handle_new_application`, add job source prompt to step 1 handler |

## Testing

### Unit Tests

**`test/unit/cli_job_description_test.rb`** (new)
- requires -j parameter
- uses -s slug when provided
- uses current slug from state when -s omitted
- fails when no slug available
- fails when employer directory doesn't exist

**`test/unit/cli_new_test.rb`** (modify)
- Update tests to reflect simplified behavior
- Remove tests that use -j parameter

**`test/unit/interactive_test.rb`** (modify)
- handle_new_application creates directory without job prompt
- step 1 handler prompts for job source

### Integration Tests

**`test/integration/job_description_command_test.rb`** (new)
- processes job description from file path
- processes job description from URL
- Uses fixtures, stubs AI client
