module Jojo
  class TemplateValidator
    MARKER = "JOJO_TEMPLATE_PLACEHOLDER"

    class MissingInputError < StandardError; end
    class UnchangedTemplateError < StandardError; end

    def self.appears_unchanged?(file_path)
      return false unless File.exist?(file_path)
      File.read(file_path).include?(MARKER)
    end

    def self.validate_required_file!(file_path, description)
      unless File.exist?(file_path)
        raise MissingInputError, <<~MSG
          ✗ Error: #{file_path} not found
            Run 'jojo setup' to create input files.
        MSG
      end
    end

    def self.warn_if_unchanged(file_path, description, cli_instance: nil)
      return :skip unless File.exist?(file_path)
      return :continue unless appears_unchanged?(file_path)

      # If no CLI instance provided (testing), return action
      return :needs_warning unless cli_instance

      # Display warning message
      cli_instance.say "⚠ Warning: #{file_path} appears to be an unmodified template", :yellow
      cli_instance.say "  Generated materials may be poor quality until you customize it.", :yellow
      cli_instance.say ""

      # Ask user if they want to continue
      if cli_instance.yes?("Continue anyway?")
        :continue
      else
        :abort
      end
    end
  end
end
