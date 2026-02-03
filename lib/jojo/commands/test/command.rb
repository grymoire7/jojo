# lib/jojo/commands/test/command.rb
module Jojo
  module Commands
    module Test
      class Command
        attr_reader :cli, :options

        def initialize(cli, options = {})
          @cli = cli
          @options = options.transform_keys(&:to_sym)
        end

        def execute
          validate_options!
          run_standard_checks if run_standard?
          exit_if_standard_only
          run_tests
        end

        private

        def validate_options!
          unsupported_flags = []
          unsupported_flags << "--no-unit or --skip-unit" if options[:unit] == false
          unsupported_flags << "--no-integration or --skip-integration" if options[:integration] == false
          unsupported_flags << "--no-all or --skip-all" if options[:all] == false
          unsupported_flags << "--no-standard or --skip-standard" if options[:standard] == false

          if unsupported_flags.any?
            say "Unsupported option(s): #{unsupported_flags.join(", ")}", :red
            say "Only --no-service (to exclude service tests from --all) is supported.", :yellow
            exit 1
          end
        end

        def run_standard?
          options[:standard] || options[:all]
        end

        def run_standard_checks
          say "Running Standard Ruby style checks...", :cyan
          system("bundle exec standardrb")
          standard_exit_code = $?.exitstatus

          if standard_exit_code != 0
            say "Standard Ruby style checks failed", :red
            exit standard_exit_code
          end
          say "Standard Ruby style checks passed", :green
        end

        def exit_if_standard_only
          if options[:standard] && !options[:all] && !options[:unit] && !options[:integration] && !options[:service]
            exit 0
          end
        end

        def run_tests
          categories = determine_categories
          categories = exclude_service_if_needed(categories)
          categories = confirm_service_tests(categories)

          if categories.empty?
            say "No tests to run.", :yellow
            exit 0
          end

          execute_tests(categories)
        end

        def determine_categories
          if options[:all]
            ["unit", "integration", "service"]
          else
            cats = []
            cats << "unit" if options[:unit]
            cats << "integration" if options[:integration]
            cats << "service" if options[:service]
            cats.empty? ? ["unit"] : cats
          end
        end

        def exclude_service_if_needed(categories)
          categories.delete("service") if options[:service] == false
          categories
        end

        def confirm_service_tests(categories)
          return categories unless categories.include?("service")
          return categories if ENV["SKIP_SERVICE_CONFIRMATION"]

          unless cli.yes?("Run service tests? These may cost money and require API keys. Continue? (y/n)")
            categories.delete("service")
          end
          categories
        end

        def execute_tests(categories)
          patterns = categories.map { |cat| "test/#{cat}/**/*_test.rb" }
          pattern_glob = patterns.join(",")
          test_cmd = "bundle exec ruby -Ilib:test -e 'Dir.glob(\"{#{pattern_glob}}\").each { |f| require f.sub(/^test\\//, \"\") }'"

          if options[:quiet]
            exec "#{test_cmd} > /dev/null 2>&1"
          else
            exec test_cmd
          end
        end

        def say(message, color = nil)
          cli.say(message, color)
        end
      end
    end
  end
end
