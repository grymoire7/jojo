require_relative "commands/version/command"
require_relative "commands/annotate/command"
require_relative "commands/research/command"
require_relative "commands/resume/command"
require_relative "commands/cover_letter/command"
require_relative "commands/faq/command"
require_relative "commands/branding/command"
require_relative "commands/website/command"
require_relative "commands/pdf/command"
require_relative "commands/setup/command"
require_relative "commands/new/command"
require_relative "commands/job_description/command"
require_relative "commands/test/command"
require_relative "commands/interactive/command"

module Jojo
  class CLI < Thor
    include OverwriteHelper

    class_option :verbose, type: :boolean, aliases: "-v", desc: "Run verbosely"
    class_option :quiet, type: :boolean, aliases: "-q", desc: "Suppress output, rely on exit code"
    class_option :slug, type: :string, aliases: "-s", desc: "Employer slug (unique identifier)"
    class_option :template, type: :string, aliases: "-t", desc: "Website template name (default: default)", default: "default"
    class_option :overwrite, type: :boolean, banner: "Overwrite existing files without prompting"

    def self.exit_on_failure?
      true
    end

    default_task :interactive

    desc "version", "Show version"
    def version
      Commands::Version::Command.new(self, command_options).execute
    end

    desc "setup", "Setup configuration"
    def setup
      Commands::Setup::Command.new(self, command_options).execute
    end

    desc "new", "Create a new job application workspace"
    long_desc <<~DESC, wrap: false
      Create a new employer workspace directory.
      After creating, use 'jojo job_description' to process the job description.

      Examples:
        jojo new -s acme-corp-senior-dev
        jojo new -s bigco-principal
    DESC
    method_option :slug, type: :string, aliases: "-s", required: true, desc: "Unique employer identifier"
    def new
      Commands::New::Command.new(self, command_options).execute
    end

    desc "job_description", "Process job description for an application"
    long_desc <<~DESC, wrap: false
      Process a job description for an existing employer workspace.
      This extracts and saves the job description and key details.

      Examples:
        jojo job_description -s acme-corp-senior-dev -j job.txt
        jojo job_description -s bigco-principal -j https://careers.bigco.com/jobs/123
        jojo job_description -j job.txt  # Uses current application from state
    DESC
    method_option :slug, type: :string, aliases: "-s", desc: "Application slug (uses current if omitted)"
    method_option :job, type: :string, aliases: "-j", required: true, desc: "Job description (file path or URL)"
    def job_description
      Commands::JobDescription::Command.new(self, command_options).execute
    end

    desc "annotate", "Generate job description annotations"
    long_desc <<~DESC, wrap: false
      Generate annotations for the job description showing how your experience matches.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo annotate -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo annotate
    DESC
    def annotate
      Commands::Annotate::Command.new(self, command_options).execute
    end

    desc "research", "Generate company/role research only"
    long_desc <<~DESC, wrap: false
      Generate company and role research.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo research -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo research
    DESC
    def research
      Commands::Research::Command.new(self, command_options).execute
    end

    desc "resume", "Generate tailored resume only"
    long_desc <<~DESC, wrap: false
      Generate a tailored resume for a specific employer.
      Requires that you've already run 'jojo new' to create the employer workspace.

      Examples:
        jojo resume -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo resume
    DESC
    def resume
      Commands::Resume::Command.new(self, command_options).execute
    end

    desc "cover_letter", "Generate cover letter only"
    long_desc <<~DESC, wrap: false
      Generate a cover letter for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo cover_letter -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo cover_letter
    DESC
    def cover_letter
      Commands::CoverLetter::Command.new(self, command_options).execute
    end

    desc "faq", "Generate FAQs only"
    long_desc <<~DESC, wrap: false
      Generate FAQs for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo faq -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo faq
    DESC
    def faq
      Commands::Faq::Command.new(self, command_options).execute
    end

    desc "branding", "Generate branding statement only"
    long_desc <<~DESC, wrap: false
      Generate a branding statement for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo branding -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo branding
    DESC
    def branding
      Commands::Branding::Command.new(self, command_options).execute
    end

    desc "website", "Generate website only"
    long_desc <<~DESC, wrap: false
      Generate a landing page website for a specific employer.
      Requires that you've already run 'jojo new' and 'jojo resume' first.

      Examples:
        jojo website -s acme-corp-senior-dev
        jojo website -s acme-corp-senior-dev -t modern
        JOJO_EMPLOYER_SLUG=acme-corp jojo website
    DESC
    def website
      Commands::Website::Command.new(self, command_options).execute
    end

    desc "pdf", "Generate PDF versions of resume and cover letter"
    long_desc <<~DESC, wrap: false
      Generate PDF files from markdown resume and cover letter.
      Requires Pandoc to be installed.

      Examples:
        jojo pdf -s acme-corp-senior-dev
        JOJO_EMPLOYER_SLUG=acme-corp jojo pdf
    DESC
    def pdf
      Commands::Pdf::Command.new(self, command_options).execute
    end

    desc "test", "Run tests (default: --unit for fast feedback)"
    long_desc <<~DESC, wrap: false
      Run test suite with optional category filtering.

      CATEGORIES:
      --unit: Unit tests (fast, no external dependencies) [default]
      --integration: Integration tests (mocked external services)
      --service: Service tests (real API calls, may cost money)
      --standard: Standard Ruby style checks
      --all: All tests and checks (includes --standard)
      --no-service: Exclude service tests

      EXAMPLES:
      jojo test                      # Run unit tests only (fast)
      jojo test --standard           # Run Standard Ruby style checks
      jojo test --all                # Run all tests and style checks
      jojo test --all --no-service   # Run all tests/checks except service tests
      jojo test --standard --unit    # Run style checks then unit tests
      jojo test --service            # Run service tests (with confirmation)
    DESC
    method_option :unit, type: :boolean, desc: "Run unit tests (default)"
    method_option :integration, type: :boolean, desc: "Run integration tests"
    method_option :service, type: :boolean, desc: "Run service tests (may use real APIs)"
    method_option :standard, type: :boolean, desc: "Run Standard Ruby style checks"
    method_option :all, type: :boolean, desc: "Run all tests and checks"
    def test
      test_options = options.slice(:unit, :integration, :service, :standard, :all, :quiet)
      Commands::Test::Command.new(self, test_options).execute
    end

    desc "interactive", "Launch interactive dashboard mode"
    method_option :slug, type: :string, aliases: "-s", desc: "Application slug to start with"
    map "i" => :interactive
    def interactive
      Commands::Interactive::Command.new(self, command_options).execute
    end

    private

    def command_options
      {
        slug: options[:slug] || ENV["JOJO_EMPLOYER_SLUG"],
        verbose: options[:verbose],
        overwrite: options[:overwrite],
        quiet: options[:quiet]
      }
    end

    def resolve_slug
      slug = options[:slug] || ENV["JOJO_EMPLOYER_SLUG"]

      unless slug
        say "Error: No employer specified.", :red
        say "Provide --slug or set JOJO_EMPLOYER_SLUG environment variable.", :yellow
        say "\nExample:", :cyan
        say "  jojo #{invoked_command} --slug acme-corp-senior", :white
        say "  export JOJO_EMPLOYER_SLUG=acme-corp-senior && jojo #{invoked_command}", :white
        exit 1
      end

      slug
    end

    def invoked_command
      # Get the current command name for error messages

      @_invocations.keys.last.to_s
    rescue
      "command"
    end
  end
end
