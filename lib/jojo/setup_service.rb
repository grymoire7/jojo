require 'fileutils'
require 'erb'

module Jojo
  class SetupService
    def initialize(cli_instance:, force: false)
      @cli = cli_instance
      @force = force
      @created_files = []
      @skipped_files = []
    end

    def run
      # To be implemented
    end
  end
end
