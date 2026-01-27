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
      apps = list_applications
      if employer && File.exist?(employer.base_path)
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
      # Special handling for job_description step - needs to prompt for source
      if step[:key] == :job_description
        show_job_description_dialog
        return
      end

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
        cli = CLI.new
        cli.invoke(:job_description, [], slug: @slug, job: source, overwrite: true)

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
        # Build the Thor CLI instance and invoke the command
        cli = CLI.new
        cli.options = {slug: @slug, overwrite: true, quiet: false}

        case step[:command]
        when :job_description
          # Should not reach here - handled by show_job_description_dialog
          puts "Use step 1 to add job description"
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
        app_employer = Employer.new(app_slug)
        if File.exist?(app_employer.base_path)
          progress = Workflow.progress(app_employer)
          progress_bar = UI::Dashboard.progress_bar(progress, width: 10)
          progress_str = (progress == 100) ? "Done" : "#{progress}%"
          company = app_employer.company_name

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
          if employer
            render_dashboard
          else
            # No employer to go back to, treat as quit
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
        if employer
          render_dashboard
        elsif list_applications.empty?
          render_welcome
        else
          handle_switch
        end
        return
      end

      # Check if already exists
      new_employer = Employer.new(slug)
      if File.exist?(new_employer.base_path)
        clear_screen
        puts TTY::Box.frame(
          "\n  Application '#{slug}' already exists.\n\n  Press any key to continue...\n",
          title: {top_left: " Error "},
          padding: [0, 1],
          border: :thick
        )
        @reader.read_keypress
        if employer
          render_dashboard
        elsif list_applications.empty?
          render_welcome
        else
          handle_switch
        end
        return
      end

      # Create the directory
      FileUtils.mkdir_p(new_employer.base_path)
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
      return unless employer

      path = employer.base_path
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
      return unless employer

      statuses = Workflow.all_statuses(employer)
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
      cli = CLI.new
      cli.options = {slug: @slug, overwrite: true, quiet: true}

      case step[:command]
      when :research
        cli.invoke(:research, [], slug: @slug, overwrite: true, quiet: true)
      when :resume
        cli.invoke(:resume, [], slug: @slug, overwrite: true, quiet: true)
      when :cover_letter
        cli.invoke(:cover_letter, [], slug: @slug, overwrite: true, quiet: true)
      when :annotate
        cli.invoke(:annotate, [], slug: @slug, overwrite: true, quiet: true)
      when :faq
        cli.invoke(:faq, [], slug: @slug, overwrite: true, quiet: true)
      when :branding
        cli.invoke(:branding, [], slug: @slug, overwrite: true, quiet: true)
      when :website
        cli.invoke(:website, [], slug: @slug, overwrite: true, quiet: true)
      when :pdf
        cli.invoke(:pdf, [], slug: @slug, overwrite: true, quiet: true)
      end
    rescue => e
      puts "  Error: #{e.message}"
    end
  end
end
