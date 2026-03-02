# frozen_string_literal: true

module Jojo
  module JsonExtractor
    def self.call(content, symbolize_names: false)
      return content if content.is_a?(Hash) || content.is_a?(Array)

      stripped = content.gsub(/\A```\w*\s*|\s*```\z/m, "").strip

      try_parse(content, symbolize_names: symbolize_names) ||
        try_parse(stripped, symbolize_names: symbolize_names) ||
        extract_first_structure(content, symbolize_names: symbolize_names) ||
        raise(JSON::ParserError, "No JSON object found in response")
    end

    def self.try_parse(text, symbolize_names: false)
      JSON.parse(text, symbolize_names: symbolize_names)
    rescue JSON::ParserError
      nil
    end
    private_class_method :try_parse

    def self.extract_first_structure(text, symbolize_names: false)
      obj_pos = text.index("{")
      arr_pos = text.index("[")

      candidates = [obj_pos, arr_pos].compact
      return nil if candidates.empty?

      opener, closer = (candidates.min == obj_pos) ? ["{", "}"] : ["[", "]"]
      start = text.index(opener)

      depth = 0
      in_string = false
      escape = false

      text[start..].chars.each_with_index do |char, i|
        if escape
          escape = false
        elsif char == "\\"
          escape = true if in_string
        elsif char == '"'
          in_string = !in_string
        elsif !in_string
          depth += 1 if char == opener
          if char == closer
            depth -= 1
            return try_parse(text[start, i + 1], symbolize_names: symbolize_names) if depth.zero?
          end
        end
      end
      nil
    end
    private_class_method :extract_first_structure
  end
end
