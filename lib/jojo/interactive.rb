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
  end
end
