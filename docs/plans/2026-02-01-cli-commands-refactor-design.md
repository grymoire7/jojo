# CLI Commands Refactor Design

## Problem

The CLI architecture has maintainability issues:

- `cli.rb` is 877 lines mixing Thor routing, validation logic, and command orchestration
- Adding a new command requires modifying `cli.rb`, risking changes to unrelated code
- Command-specific helpers (generators, prompts, processors) are scattered across `lib/jojo/`
- The `interactive` command has a circular dependency, calling back into `CLI` via `cli.invoke()`
- Testing command logic in isolation is difficult due to Thor coupling

## Solution

Refactor commands into self-contained classes under `lib/jojo/commands/`. Each command gets its own directory containing the command class and any command-specific helpers. The `cli.rb` file becomes a thin router that delegates to command classes.

## Architecture

### Command Base Class

Extracts repeated patterns into a shared base:

```ruby
# lib/jojo/commands/base.rb
module Jojo
  module Commands
    class Base
      attr_reader :cli, :options

      def initialize(cli, options = {})
        @cli = cli
        @options = options
      end

      def execute
        raise NotImplementedError, "Subclasses must implement #execute"
      end

      protected

      # Common options
      def slug = options[:slug]
      def verbose? = options[:verbose] || false
      def overwrite? = options[:overwrite] || false
      def quiet? = options[:quiet] || false

      # Output helpers (delegate to injected CLI)
      def say(message, color = nil) = cli.say(message, color)
      def yes?(prompt) = cli.yes?(prompt)

      # Shared setup (lazy-loaded)
      def employer
        @employer ||= Jojo::Employer.new(slug)
      end

      def config
        @config ||= Jojo::Config.new
      end

      def ai_client
        @ai_client ||= Jojo::AIClient.new(config, verbose: verbose?)
      end

      def status_logger
        @status_logger ||= Jojo::StatusLogger.new(employer)
      end

      # Common validations
      def require_employer!
        return if employer.artifacts_exist?

        say "Employer '#{slug}' not found.", :red
        say "  Run 'jojo new -s #{slug}' to create it.", :yellow
        exit 1
      end

      def require_file!(path, description, suggestion: nil)
        return if File.exist?(path)

        say "#{description} not found at #{path}", :red
        say "  #{suggestion}", :yellow if suggestion
        exit 1
      end
    end
  end
end
```

### Example Command Implementation

```ruby
# lib/jojo/commands/annotate/command.rb
module Jojo
  module Commands
    module Annotate
      class Command < Base
        def execute
          require_employer!

          say "Generating annotations for #{employer.company_name}...", :green

          generator = Generator.new(
            employer,
            ai_client,
            verbose: verbose?,
            overwrite_flag: overwrite?,
            cli_instance: cli
          )
          annotations = generator.generate

          say "Generated #{annotations.length} annotations", :green
          say "  Saved to: #{employer.job_description_annotations_path}", :green
        rescue => e
          say "Error generating annotations: #{e.message}", :red
          exit 1
        end
      end
    end
  end
end
```

### Thin CLI Router

```ruby
# lib/jojo/cli.rb
module Jojo
  class CLI < Thor
    include OverwriteHelper

    class_option :verbose, type: :boolean, aliases: "-v", desc: "Run verbosely"
    class_option :slug, type: :string, aliases: "-s", desc: "Employer slug"
    class_option :overwrite, type: :boolean, desc: "Overwrite existing files"

    def self.exit_on_failure? = true
    default_task :interactive

    desc "annotate", "Generate job description annotations"
    def annotate
      Commands::Annotate::Command.new(self, command_options).execute
    end

    desc "research", "Generate company/role research"
    def research
      Commands::Research::Command.new(self, command_options).execute
    end

    # ... other commands follow same one-liner pattern ...

    private

    def command_options
      {
        slug: options[:slug] || ENV["JOJO_EMPLOYER_SLUG"],
        verbose: options[:verbose],
        overwrite: options[:overwrite],
        quiet: options[:quiet]
      }
    end
  end
end
```

### CLI Adapter for Interactive Mode

Interactive mode needs to call commands without Thor. Instead of conditional logic in the base class, inject a different CLI adapter:

```ruby
# lib/jojo/commands/interactive/console_output.rb
module Jojo
  module Commands
    module Interactive
      class ConsoleOutput
        def initialize(quiet: false)
          @quiet = quiet
        end

        def say(message, _color = nil)
          puts message unless @quiet
        end

        def yes?(prompt)
          print "#{prompt} "
          $stdin.gets.chomp.downcase.start_with?("y")
        end
      end
    end
  end
end
```

```ruby
# lib/jojo/commands/interactive/runner.rb (in execute_step)
def execute_step(step)
  output = ConsoleOutput.new(quiet: @quiet)
  command_class = step_command_class(step[:command])
  command_class.new(output, slug: @slug, overwrite: true).execute
end
```

This enables:
- Consistent interface across Thor CLI, Interactive, and tests
- No conditionals in Base class
- Easy mocking for unit tests

## Directory Structure

```
lib/jojo/
├── cli.rb                          # Thin Thor router (~150 lines)
├── commands/
│   ├── base.rb                     # Shared command behavior
│   ├── annotate/
│   │   ├── command.rb
│   │   ├── generator.rb            # from generators/annotation_generator.rb
│   │   └── prompt.rb               # from prompts/annotation_prompt.rb
│   ├── branding/
│   │   ├── command.rb
│   │   ├── generator.rb            # from generators/branding_generator.rb
│   │   └── prompt.rb
│   ├── cover_letter/
│   │   ├── command.rb
│   │   ├── generator.rb            # from generators/cover_letter_generator.rb
│   │   └── prompt.rb               # from prompts/cover_letter_prompt.rb
│   ├── faq/
│   │   ├── command.rb
│   │   ├── generator.rb            # from generators/faq_generator.rb
│   │   └── prompt.rb               # from prompts/faq_prompt.rb
│   ├── interactive/
│   │   ├── command.rb              # thin wrapper
│   │   ├── runner.rb               # from interactive.rb
│   │   ├── console_output.rb       # CLI adapter for commands
│   │   ├── workflow.rb             # from workflow.rb
│   │   ├── dashboard.rb            # from ui/dashboard.rb
│   │   └── dialogs.rb              # from ui/dialogs.rb
│   ├── job_description/
│   │   ├── command.rb
│   │   ├── processor.rb            # from job_description_processor.rb
│   │   └── prompt.rb               # from prompts/job_description_prompts.rb
│   ├── new/
│   │   └── command.rb
│   ├── pdf/
│   │   ├── command.rb
│   │   ├── converter.rb            # from pdf_converter.rb
│   │   └── pandoc_checker.rb       # from pandoc_checker.rb
│   ├── research/
│   │   ├── command.rb
│   │   ├── generator.rb            # from generators/research_generator.rb
│   │   └── prompt.rb               # from prompts/research_prompt.rb
│   ├── resume/
│   │   ├── command.rb
│   │   ├── generator.rb            # from generators/resume_generator.rb
│   │   ├── prompt.rb               # from prompts/resume_prompt.rb
│   │   ├── curation_service.rb     # from resume_curation_service.rb
│   │   └── transformer.rb          # from resume_transformer.rb
│   ├── setup/
│   │   ├── command.rb
│   │   └── service.rb              # from setup_service.rb
│   ├── test/
│   │   └── command.rb
│   ├── version/
│   │   └── command.rb
│   └── website/
│       ├── command.rb
│       ├── generator.rb            # from generators/website_generator.rb
│       └── prompt.rb               # from prompts/website_prompt.rb
│
├── # Shared utilities (remain in lib/jojo/)
├── ai_client.rb
├── config.rb
├── employer.rb
├── erb_renderer.rb
├── errors.rb
├── overwrite_helper.rb
├── resume_data_formatter.rb        # shared by cover_letter, research
├── resume_data_loader.rb           # shared by multiple commands
├── state_persistence.rb
├── status_logger.rb
└── template_validator.rb
```

## Removed

- `lib/jojo/generators/` - contents moved into command directories
- `lib/jojo/prompts/` - contents moved into command directories
- `lib/jojo/ui/` - contents moved into commands/interactive/
- `lib/jojo/interactive.rb` - moved to commands/interactive/runner.rb
- `lib/jojo/workflow.rb` - moved to commands/interactive/workflow.rb
- `generate` command - removed (use interactive mode or individual commands)

## Benefits

| Before | After |
|--------|-------|
| Adding a command modifies cli.rb | Adding a command = new directory |
| Command helpers scattered in lib/jojo/ | Command-specific code co-located |
| Interactive depends on CLI class | Interactive uses command classes directly |
| Hard to test commands in isolation | Inject mock CLI adapter for tests |
| 877-line cli.rb | ~150-line thin router |

## Testing

Commands become easier to test in isolation:

```ruby
class AnnotateCommandTest < Minitest::Test
  def test_requires_employer
    mock_cli = Minitest::Mock.new
    mock_cli.expect :say, nil, ["Employer 'fake' not found.", :red]
    mock_cli.expect :say, nil, [String, :yellow]

    command = Jojo::Commands::Annotate::Command.new(mock_cli, slug: "fake")
    assert_raises(SystemExit) { command.execute }
    mock_cli.verify
  end
end
```

## Migration Strategy

1. Create `commands/base.rb` with shared behavior
2. Create `commands/interactive/console_output.rb` adapter
3. Migrate one simple command (e.g., `version`) as proof of concept
4. Migrate remaining commands one at a time, moving related helpers
5. Remove `generate` command, update interactive to use command classes directly
6. Delete empty `generators/`, `prompts/`, `ui/` directories
7. Update require statements in `lib/jojo.rb`
