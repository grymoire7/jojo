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
  end
end
