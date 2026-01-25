# frozen_string_literal: true

module Jojo
  module StatePersistence
    STATE_FILE = ".jojo_state"

    def self.save_slug(slug)
      File.write(STATE_FILE, slug)
    end

    def self.load_slug
      return nil unless File.exist?(STATE_FILE)
      File.read(STATE_FILE).strip
    end

    def self.clear
      File.delete(STATE_FILE) if File.exist?(STATE_FILE)
    end
  end
end
