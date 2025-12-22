require 'erb'
require 'fileutils'

module Jojo
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Run verbosely'
    class_option :employer, type: :string, aliases: '-e', desc: 'Employer name'
    class_option :job, type: :string, aliases: '-j', desc: 'Job description (file path or URL)'

    desc "version", "Show version"
    def version
      say "Jojo #{Jojo::VERSION}", :green
    end
  end
end
