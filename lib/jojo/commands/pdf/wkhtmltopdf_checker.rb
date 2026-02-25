# lib/jojo/commands/pdf/wkhtmltopdf_checker.rb
module Jojo
  module Commands
    module Pdf
      class WkhtmltopdfChecker
        class WkhtmltopdfNotFoundError < StandardError; end

        def self.available?
          system("which wkhtmltopdf > /dev/null 2>&1")
        end

        def self.version
          return nil unless available?

          output = `wkhtmltopdf --version 2>/dev/null`.lines.first
          return nil unless output

          output[/wkhtmltopdf ([\d.]+)/, 1]
        end

        def self.check!
          return true if available?

          raise WkhtmltopdfNotFoundError, <<~MSG
            wkhtmltopdf is not installed or not in PATH.

            Install wkhtmltopdf:
              macOS:   brew install --cask wkhtmltopdf
              Linux:   apt-get install wkhtmltopdf  (or yum install wkhtmltopdf)
              Windows: https://wkhtmltopdf.org/downloads.html

            After installing, verify with: wkhtmltopdf --version
          MSG
        end
      end
    end
  end
end
