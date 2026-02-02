# lib/jojo/commands/pdf/pandoc_checker.rb
module Jojo
  module Commands
    module Pdf
      class PandocChecker
        class PandocNotFoundError < StandardError; end

        def self.available?
          system("which pandoc > /dev/null 2>&1")
        end

        def self.version
          return nil unless available?

          output = `pandoc --version 2>/dev/null`.lines.first
          return nil unless output

          output[/pandoc ([\d.]+)/, 1]
        end

        def self.check!
          return true if available?

          raise PandocNotFoundError, <<~MSG
            Pandoc is not installed or not in PATH.

            Install Pandoc:
              macOS:   brew install pandoc
              Linux:   apt-get install pandoc  (or yum install pandoc)
              Windows: https://pandoc.org/installing.html

            After installing, verify with: pandoc --version
          MSG
        end
      end
    end
  end
end
