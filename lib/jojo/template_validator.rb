module Jojo
  class TemplateValidator
    MARKER = "JOJO_TEMPLATE_PLACEHOLDER"

    def self.appears_unchanged?(file_path)
      return false unless File.exist?(file_path)
      File.read(file_path).include?(MARKER)
    end
  end
end
