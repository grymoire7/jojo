module Jojo
  class RecommendationParser
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def parse
      return nil unless File.exist?(file_path)

      content = File.read(file_path)
      sections = content.split(/^---\s*$/).map(&:strip)

      # Skip first section (header/instructions)
      sections.shift

      sections.map { |section| parse_section(section) }.compact
    end

    private

    def parse_section(section)
      return nil if section.empty?

      # Extract recommender name
      name_match = section.match(/^##\s+Recommendation from\s+(.+)$/i)
      return nil unless name_match
      recommender_name = name_match[1].strip

      # Extract title
      title_match = section.match(/\*\*Their Title:\*\*\s+(.+)$/i)
      recommender_title = title_match ? title_match[1].strip : nil

      # Extract relationship
      relationship_match = section.match(/\*\*Relationship:\*\*\s+(.+)$/i)
      relationship = relationship_match ? relationship_match[1].strip : 'Colleague'

      # Extract quote (blockquote lines starting with >)
      quote_lines = section.lines.select { |line| line.strip.start_with?('>') }
      return nil if quote_lines.empty?

      quote = quote_lines.map { |line| line.sub(/^>\s*/, '').strip }.join(' ')

      {
        recommender_name: recommender_name,
        recommender_title: recommender_title,
        relationship: relationship,
        quote: quote
      }
    end
  end
end
