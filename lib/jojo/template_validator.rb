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
  end
end
