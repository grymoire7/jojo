# frozen_string_literal: true

require "tty-reader"
require "tty-cursor"
require "tty-screen"
require "tty-box"

module Jojo
  class Interactive
    attr_reader :slug

    def initialize(slug: nil)
      @slug = slug || StatePersistence.load_slug
      @reader = TTY::Reader.new
      @cursor = TTY::Cursor
      @running = false
    end

    def employer
      return nil unless @slug
      @employer ||= Employer.new(@slug)
    end

    def list_applications
      employers_path = File.join(Dir.pwd, "employers")
      return [] unless Dir.exist?(employers_path)

      Dir.children(employers_path)
        .select { |f| File.directory?(File.join(employers_path, f)) }
        .sort
    end

    def switch_application(new_slug)
      @slug = new_slug
      @employer = nil  # Clear cached employer
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
      puts UI::Dashboard.render(employer)
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
      if employer && File.exist?(employer.base_path)
        render_dashboard
      else
        render_welcome
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
          handle_step_selection(action) if employer
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
      status = Workflow.status(step[:key], employer)

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
      missing = Workflow.missing_dependencies(step[:key], employer)

      clear_screen
      puts UI::Dialogs.blocked_dialog(step[:label], missing)

      # Wait for Escape
      loop do
        key = @reader.read_keypress
        break if key == "\e"
      end

      render_dashboard
    end

    def show_ready_dialog(step, status)
      inputs = step[:dependencies].map do |dep_key|
        dep_step = Workflow::STEPS.find { |s| s[:key] == dep_key }
        path = Workflow.file_path(dep_key, employer)
        age = File.exist?(path) ? time_ago(File.mtime(path)) : nil
        {name: dep_step[:output_file], age: age}
      end

      clear_screen
      puts UI::Dialogs.ready_dialog(step[:label], inputs, step[:output_file], paid: step[:paid])

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
      path = Workflow.file_path(step[:key], employer)
      age = time_ago(File.mtime(path))

      clear_screen
      puts UI::Dialogs.generated_dialog(step[:label], age, paid: step[:paid])

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
        # Build the Thor CLI instance and invoke the command
        cli = CLI.new
        cli.options = {slug: @slug, overwrite: true, quiet: false}

        case step[:command]
        when :new
          puts "Use 'jojo new' command to create a new application"
        when :research
          cli.invoke(:research, [], slug: @slug, overwrite: true)
        when :resume
          cli.invoke(:resume, [], slug: @slug, overwrite: true)
        when :cover_letter
          cli.invoke(:cover_letter, [], slug: @slug, overwrite: true)
        when :annotate
          cli.invoke(:annotate, [], slug: @slug, overwrite: true)
        when :faq
          cli.invoke(:faq, [], slug: @slug, overwrite: true)
        when :branding
          cli.invoke(:branding, [], slug: @slug, overwrite: true)
        when :website
          cli.invoke(:website, [], slug: @slug, overwrite: true)
        when :pdf
          cli.invoke(:pdf, [], slug: @slug, overwrite: true)
        end

        puts
        puts "Done! Press any key to continue..."
        @reader.read_keypress
      rescue => e
        show_error_dialog(step, e.message)
      end
    end

    def show_error_dialog(step, error_message)
      clear_screen
      puts UI::Dialogs.error_dialog(step[:label], error_message)

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
  end
end
