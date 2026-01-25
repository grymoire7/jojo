# frozen_string_literal: true

require "tty-reader"
require "tty-cursor"
require "tty-screen"

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
  end
end
