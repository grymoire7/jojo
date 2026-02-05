# frozen_string_literal: true

# lib/jojo/commands/interactive/runner.rb

require "tty-reader"
require "tty-cursor"
require "tty-screen"
require "tty-box"
require_relative "workflow"
require_relative "dashboard"
require_relative "dialogs"
require_relative "../console_output"

module Jojo
  module Commands
    module Interactive
      class Runner
        attr_reader :slug

        def initialize(slug: nil)
          @slug = slug || StatePersistence.load_slug
          @reader = TTY::Reader.new
          @cursor = TTY::Cursor
          @running = false
        end

        def application
          return nil unless @slug
          @application ||= Application.new(@slug)
        end

        def list_applications
          applications_path = File.join(Dir.pwd, "applications")
          return [] unless Dir.exist?(applications_path)

          Dir.children(applications_path)
            .select { |f| File.directory?(File.join(applications_path, f)) }
            .sort
        end

        def switch_application(new_slug)
          @slug = new_slug
          @application = nil  # Clear cached application
          StatePersistence.save_slug(new_slug)
        end

        def handle_key(key)
          case key
          when "q", "Q"
            :quit
          when "s", "S"
            :switch
          when "o", "O"
            :open
          when "a", "A"
            :all
          when "n", "N"
            :new
          when "1".."9"
            key.to_i - 1  # Convert to 0-indexed
          end
        end

        def clear_screen
          print @cursor.clear_screen
          print @cursor.move_to(0, 0)
        end

        def render_dashboard
          clear_screen
          puts Dashboard.render(application)
        end

        def render_welcome
          clear_screen
          lines = []
          lines << ""
          lines << "  Welcome! No applications yet."
          lines << ""
          lines << "  To get started, create your first application:"
          lines << ""
          lines << "  [n] New application    [q] Quit"

          puts TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " Jojo "},
            padding: [0, 1],
            border: :thick
          )
        end

        def run
          @running = true

          # Initial render
          apps = list_applications
          if application && File.exist?(application.base_path)
            render_dashboard
          elsif apps.empty?
            render_welcome
          else
            handle_switch
          end

          while @running
            key = @reader.read_keypress

            action = handle_key(key)
            case action
            when :quit
              @running = false
              clear_screen
              puts "Goodbye!"
            when :switch
              handle_switch
            when :open
              handle_open
            when :all
              handle_generate_all
            when :new
              handle_new_application
            when Integer
              handle_step_selection(action) if application
            end
          end
        rescue TTY::Reader::InputInterrupt
          # Ctrl+C pressed
          @running = false
          clear_screen
          puts "Interrupted. Goodbye!"
        end

        def handle_step_selection(step_index)
          return unless step_index >= 0 && step_index < Workflow::STEPS.length

          step = Workflow::STEPS[step_index]
          status = Workflow.status(step[:key], application)

          case status
          when :blocked
            show_blocked_dialog(step)
          when :ready, :stale
            show_ready_dialog(step, status)
          when :generated
            show_generated_dialog(step)
          end
        end

        private

        def show_blocked_dialog(step)
          missing = Workflow.missing_dependencies(step[:key], application)

          clear_screen
          puts Dialogs.blocked_dialog(step[:label], missing)

          # Wait for Escape
          loop do
            key = @reader.read_keypress
            break if key == "\e"
          end

          render_dashboard
        end

        def show_ready_dialog(step, status)
          # Special handling for job_description step - needs to prompt for source
          if step[:key] == :job_description
            show_job_description_dialog
            return
          end

          inputs = step[:dependencies].map do |dep_key|
            dep_step = Workflow::STEPS.find { |s| s[:key] == dep_key }
            path = Workflow.file_path(dep_key, application)
            age = File.exist?(path) ? time_ago(File.mtime(path)) : nil
            {name: dep_step[:output_file], age: age}
          end

          clear_screen
          puts Dialogs.ready_dialog(step[:label], inputs, step[:output_file], paid: step[:paid])

          loop do
            key = @reader.read_keypress
            case key
            when "\r", "\n" # Enter
              execute_step(step)
              break
            when "\e" # Escape
              break
            end
          end

          render_dashboard
        end

        def show_generated_dialog(step)
          path = Workflow.file_path(step[:key], application)
          age = time_ago(File.mtime(path))

          clear_screen
          puts Dialogs.generated_dialog(step[:label], age, paid: step[:paid])

          loop do
            key = @reader.read_keypress
            case key
            when "r", "R"
              execute_step(step)
              break
            when "v", "V"
              view_file(path)
              break
            when "\e"
              break
            end
          end

          render_dashboard
        end

        def show_job_description_dialog
          clear_screen
          puts TTY::Box.frame(
            "\n  Enter job description source (URL or file path)\n  at the prompt below.\n\n  [Esc] Cancel\n",
            title: {top_left: " Job Description "},
            padding: [0, 1],
            border: :thick
          )

          source = read_line_with_escape("> ")
          if source.nil? || source.empty?
            render_dashboard
            return
          end

          clear_screen
          puts "Processing job description..."
          puts "Press Ctrl+C to cancel"
          puts

          begin
            output = ConsoleOutput.new
            JobDescription::Command.new(output, slug: @slug, job: source, overwrite: true).execute

            puts
            puts "Done! Press any key to continue..."
            @reader.read_keypress
          rescue => e
            puts "Error: #{e.message}"
            puts "Press any key to continue..."
            @reader.read_keypress
          end

          render_dashboard
        end

        def read_line_with_escape(prompt = "")
          # Use a fresh reader to avoid accumulating handlers
          reader = TTY::Reader.new

          reader.on(:keyescape) do
            return nil  # Returns from read_line_with_escape method
          end

          reader.read_line(prompt).strip
        end

        def time_ago(time)
          seconds = Time.now - time
          case seconds
          when 0..59
            "just now"
          when 60..3599
            "#{(seconds / 60).to_i} minutes ago"
          when 3600..86399
            "#{(seconds / 3600).to_i} hours ago"
          else
            "#{(seconds / 86400).to_i} days ago"
          end
        end

        def view_file(path)
          editor = ENV["EDITOR"] || "less"
          system(editor, path)
        end

        def execute_step(step)
          clear_screen

          # Show generating indicator
          puts "Generating #{step[:label].downcase}..."
          puts "Press Ctrl+C to cancel"
          puts

          begin
            output = ConsoleOutput.new
            command_class = step_command_class(step[:command])
            command_class.new(output, slug: @slug, overwrite: true, quiet: false).execute

            puts
            puts "Done! Press any key to continue..."
            @reader.read_keypress
          rescue => e
            show_error_dialog(step, e.message)
          end
        end

        def step_command_class(command_key)
          case command_key
          when :job_description then JobDescription::Command
          when :research then Research::Command
          when :resume then Resume::Command
          when :cover_letter then CoverLetter::Command
          when :annotate then Annotate::Command
          when :faq then Faq::Command
          when :branding then Branding::Command
          when :website then Website::Command
          when :pdf then Pdf::Command
          end
        end

        def show_error_dialog(step, error_message)
          clear_screen
          puts Dialogs.error_dialog(step[:label], error_message)

          loop do
            key = @reader.read_keypress
            case key
            when "r", "R"
              execute_step(step)
              return
            when "\e"
              return
            end
          end
        end

        def handle_switch
          apps = list_applications
          return render_welcome if apps.empty?

          clear_screen

          lines = []
          lines << ""
          lines << "  Recent applications:"
          lines << ""

          apps.each_with_index do |app_slug, idx|
            next if idx >= 9  # Only show first 9

            # Get progress for this app
            app_application = Application.new(app_slug)
            if File.exist?(app_application.base_path)
              progress = Workflow.progress(app_application)
              progress_bar = Dashboard.progress_bar(progress, width: 10)
              progress_str = (progress == 100) ? "Done" : "#{progress}%"
              company = app_application.company_name

              lines << "  #{idx + 1}. #{app_slug.ljust(25)} #{progress_bar}  #{progress_str}"
              lines << "     #{company}"
            else
              lines << "  #{idx + 1}. #{app_slug}"
            end
            lines << ""
          end

          lines << "  [1-#{[apps.length, 9].min}] Select    [n] New application    [Esc] Back    [q] Quit"

          puts TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " Switch Application "},
            padding: [0, 1],
            border: :thick
          )

          loop do
            key = @reader.read_keypress
            case key
            when "1".."9"
              idx = key.to_i - 1
              if idx < apps.length
                switch_application(apps[idx])
                render_dashboard
                return
              end
            when "n", "N"
              handle_new_application
              return
            when "\e"
              if application
                render_dashboard
              else
                # No application to go back to, treat as quit
                @running = false
                clear_screen
                puts "Goodbye!"
              end
              return
            when "q", "Q"
              @running = false
              clear_screen
              puts "Goodbye!"
              return
            end
          end
        end

        def handle_new_application
          clear_screen

          # Prompt for slug
          puts TTY::Box.frame(
            "\n  Enter slug (e.g., acme-corp-senior-dev)\n  at the prompt below.\n",
            title: {top_left: " New Application "},
            padding: [0, 1],
            border: :thick
          )

          slug = @reader.read_line("> ").strip
          if slug.empty?
            if application
              render_dashboard
            elsif list_applications.empty?
              render_welcome
            else
              handle_switch
            end
            return
          end

          # Check if already exists
          new_application = Application.new(slug)
          if File.exist?(new_application.base_path)
            clear_screen
            puts TTY::Box.frame(
              "\n  Application '#{slug}' already exists.\n\n  Press any key to continue...\n",
              title: {top_left: " Error "},
              padding: [0, 1],
              border: :thick
            )
            @reader.read_keypress
            if application
              render_dashboard
            elsif list_applications.empty?
              render_welcome
            else
              handle_switch
            end
            return
          end

          # Create the directory
          FileUtils.mkdir_p(new_application.base_path)
          switch_application(slug)

          clear_screen
          puts TTY::Box.frame(
            "\n  Created application: #{slug}\n\n  Select 'Job Description' to add the job posting.\n\n  Press any key to continue...\n",
            title: {top_left: " Success "},
            padding: [0, 1],
            border: :thick
          )
          @reader.read_keypress
          render_dashboard
        end

        def prompt_for_input(prompt)
          clear_screen
          puts TTY::Box.frame(
            "\n  #{prompt}\n  Enter at the prompt below.\n",
            title: {top_left: " New Application "},
            padding: [0, 1],
            border: :thick
          )

          input = @reader.read_line("> ").strip
          input.empty? ? nil : input
        end

        def prompt_for_paste
          clear_screen
          puts "Paste job description (end with Ctrl+D on empty line):"
          puts

          lines = []
          while (line = $stdin.gets)
            lines << line
          end

          text = lines.join
          text.empty? ? nil : text
        rescue Interrupt
          nil
        end

        def handle_open
          return unless application

          path = application.base_path
          if RUBY_PLATFORM.include?("darwin")
            system("open", path)
          elsif RUBY_PLATFORM.include?("linux")
            system("xdg-open", path)
          else
            puts "Cannot open folder on this platform"
            sleep 1
          end
        end

        def handle_generate_all
          return unless application

          statuses = Workflow.all_statuses(application)
          ready_steps = Workflow::STEPS.select { |s| [:ready, :stale].include?(statuses[s[:key]]) }

          return if ready_steps.empty?

          clear_screen
          puts "Generating all ready items..."
          puts

          ready_steps.each do |step|
            puts "-> #{step[:label]}..."
            execute_step_quietly(step)
          end

          puts
          puts "Done! Press any key to continue..."
          @reader.read_keypress
          render_dashboard
        end

        def execute_step_quietly(step)
          output = ConsoleOutput.new(quiet: true)
          command_class = step_command_class(step[:command])
          command_class.new(output, slug: @slug, overwrite: true, quiet: true).execute
        rescue => e
          puts "  Error: #{e.message}"
        end
      end
    end
  end
end
